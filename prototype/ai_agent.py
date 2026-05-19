"""
QUANTA — AI Agent Wallet & x402-style Micropayment
==================================================

Unique features enabling AI agents to transact autonomously:
  - Spending policies (rate limit, max-per-tx, whitelist)
  - Intent-based transactions
  - Streaming micropayments (like x402)
  - Death switch (auto-refund if agent goes offline)
  - Reputation tracking
"""

from __future__ import annotations
import time
import json
import hashlib
from dataclasses import dataclass, field
from typing import Optional

from quantum_wallet import Wallet, verify


HASH = lambda b: hashlib.sha3_256(b).digest()


@dataclass
class SpendingPolicy:
    max_per_tx: float = 1.0
    max_per_hour: float = 10.0
    max_per_day: float = 50.0
    whitelist: list[str] = field(default_factory=list)
    blacklist: list[str] = field(default_factory=list)
    require_intent: bool = False
    death_switch_seconds: int = 86400 * 7

    def check(self, amount: float, recipient: str, history: list[dict]) -> tuple[bool, str]:
        if amount > self.max_per_tx:
            return False, f"Exceeds max_per_tx ({self.max_per_tx})"
        if recipient in self.blacklist:
            return False, "Recipient blacklisted"
        if self.whitelist and recipient not in self.whitelist:
            return False, "Recipient not in whitelist"

        now = time.time()
        spent_hour = sum(h["amount"] for h in history if now - h["ts"] < 3600)
        spent_day = sum(h["amount"] for h in history if now - h["ts"] < 86400)
        if spent_hour + amount > self.max_per_hour:
            return False, f"Exceeds hourly cap ({self.max_per_hour})"
        if spent_day + amount > self.max_per_day:
            return False, f"Exceeds daily cap ({self.max_per_day})"
        return True, "ok"


@dataclass
class AIAgentWallet:
    """Wallet dedicated to AI agents."""
    base: Wallet
    owner_address: str
    policy: SpendingPolicy
    name: str = "agent"
    balance: float = 0.0
    reputation: float = 1.0
    last_ping: float = field(default_factory=time.time)
    history: list[dict] = field(default_factory=list)

    @classmethod
    def create(cls, owner_address: str, name: str, policy: SpendingPolicy,
               initial_funding: float = 0.0) -> "AIAgentWallet":
        return cls(
            base=Wallet.create(height=6),
            owner_address=owner_address,
            policy=policy,
            name=name,
            balance=initial_funding,
        )

    @property
    def address(self) -> str:
        return self.base.address

    def ping(self) -> None:
        """Heartbeat — agent reports alive."""
        self.last_ping = time.time()

    def is_alive(self) -> bool:
        return (time.time() - self.last_ping) < self.policy.death_switch_seconds

    def send(self, recipient: str, amount: float, memo: str = "") -> dict:
        if not self.is_alive():
            raise RuntimeError("Agent dead — funds must be recovered by owner")
        if amount > self.balance:
            raise ValueError("Insufficient balance")

        ok, reason = self.policy.check(amount, recipient, self.history)
        if not ok:
            raise PermissionError(f"Policy violation: {reason}")

        tx = {
            "from": self.address,
            "to": recipient,
            "amount": amount,
            "memo": memo,
            "nonce": len(self.history),
            "ts": time.time(),
            "agent_name": self.name,
        }
        sig = self.base.sign(tx)
        self.balance -= amount
        self.history.append({"amount": amount, "ts": tx["ts"], "to": recipient})
        self.ping()
        return {"tx": tx, "sig": sig, "public_root": self.base.public_root}

    def receive(self, amount: float) -> None:
        self.balance += amount
        self.reputation = min(2.0, self.reputation + 0.001)


@dataclass
class Intent:
    """
    Agent signs an "intent" instead of a specific transaction.
    Solver/Aggregator finds best execution.
    Like CowSwap/UniswapX but for any action type.
    """
    agent_address: str
    action: str
    params: dict
    deadline: float
    nonce: int

    def hash(self) -> bytes:
        return HASH(json.dumps({
            "agent": self.agent_address,
            "action": self.action,
            "params": self.params,
            "deadline": self.deadline,
            "nonce": self.nonce,
        }, sort_keys=True).encode())


class PaymentChannel:
    """
    State channel between agent (payer) and service (payee).
    Each micro-payment is a signed message — settled on-chain
    only when channel closes (like Lightning Network but simpler).
    """

    def __init__(self, payer: AIAgentWallet, payee_address: str, deposit: float):
        self.payer = payer
        self.payee = payee_address
        self.deposit = deposit
        self.spent = 0.0
        self.nonce = 0
        self.last_signed_state: Optional[dict] = None
        if payer.balance < deposit:
            raise ValueError("Insufficient deposit")
        payer.balance -= deposit

    def micro_pay(self, amount: float) -> dict:
        """Pay 1 micropayment off-chain. Just increment counter + sign new state."""
        if self.spent + amount > self.deposit:
            raise ValueError("Channel exhausted — open new channel")
        self.spent += amount
        self.nonce += 1
        state = {
            "channel_id": f"chan-{self.payer.address}-{self.payee}",
            "spent": self.spent,
            "nonce": self.nonce,
        }
        sig = self.payer.base.sign(state)
        self.last_signed_state = {"state": state, "sig": sig,
                                   "public_root": self.payer.base.public_root}
        return self.last_signed_state

    def close(self) -> dict:
        """Close channel — settle on-chain."""
        refund = self.deposit - self.spent
        self.payer.balance += refund
        return {
            "settle_to_payee": self.spent,
            "refund_to_payer": refund,
            "final_state": self.last_signed_state,
        }


def http_402_response(price_qta: float, receiver: str, nonce: str) -> dict:
    """Simulates 402 Payment Required response."""
    return {
        "status": 402,
        "headers": {
            "X-QUANTA-Price": f"{price_qta:.6f} QTA",
            "X-QUANTA-Receiver": receiver,
            "X-QUANTA-Nonce": nonce,
            "X-QUANTA-Channel-Hint": "Open channel for batch discount 90%",
        },
        "body": {"error": "Payment required for this AI inference"},
    }


if __name__ == "__main__":
    print("🤖 AI Agent Wallet Demo\n")

    # Owner creates agent with strict policy
    policy = SpendingPolicy(
        max_per_tx=0.5,
        max_per_hour=2.0,
        max_per_day=10.0,
        whitelist=[],
    )
    agent = AIAgentWallet.create(
        owner_address="qta1humanowner",
        name="ResearchBot-001",
        policy=policy,
        initial_funding=5.0,
    )
    print(f"Created agent: {agent.name} @ {agent.address}")
    print(f"Initial balance: {agent.balance} QTA")

    # Agent pays for another AI service
    api_provider = "qta1openrouter"
    print(f"\n📡 HTTP 402 from {api_provider}:")
    print(json.dumps(http_402_response(0.001, api_provider, "n1"), indent=2))

    # Open payment channel to reduce fees
    print("\n💸 Opening payment channel (deposit 1 QTA)...")
    channel = PaymentChannel(agent, api_provider, deposit=1.0)
    for i in range(5):
        state = channel.micro_pay(0.001)
        print(f"  Micro-payment #{state['state']['nonce']}: "
              f"spent={state['state']['spent']:.4f} QTA")

    settle = channel.close()
    print(f"\n🔚 Channel closed:")
    print(f"  → Payee receives {settle['settle_to_payee']:.4f} QTA")
    print(f"  → Refund to agent: {settle['refund_to_payer']:.4f} QTA")
    print(f"  Agent balance now: {agent.balance:.4f} QTA")

    # Test policy enforcement
    print("\n🚫 Testing policy enforcement:")
    try:
        agent.send("qta1somebody", 0.6, "should fail")
    except PermissionError as e:
        print(f"  Blocked correctly: {e}")
