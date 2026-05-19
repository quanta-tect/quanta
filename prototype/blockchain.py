"""
QUANTA Blockchain Core
======================

Minimal blockchain implementation integrating:
  - Block + Transaction structure
  - Quantum-safe signature verification
  - PoUW consensus integration
  - Mempool + state (account-based, like Ethereum)
  - Burn mechanism (deflationary)
  - AI marketplace primitives (on-chain model registry)
"""

from __future__ import annotations
import hashlib
import json
import time
from dataclasses import dataclass, field, asdict
from typing import Optional

from quantum_wallet import verify
from pouw_consensus import PoUWConsensus, UsefulTask, Validator, demo_executor


HASH = lambda b: hashlib.sha3_256(b).digest()


@dataclass
class Transaction:
    sender: str
    recipient: str
    amount: float
    nonce: int
    fee: float
    public_root: str
    signature: dict
    memo: str = ""
    tx_type: str = "transfer"  # transfer | model_register | ai_call | burn

    def to_dict(self) -> dict:
        return asdict(self)

    def signed_payload(self) -> dict:
        return {
            "from": self.sender,
            "to": self.recipient,
            "amount": self.amount,
            "memo": self.memo,
            "nonce": self.nonce,
            "ts": 0,
            "agent_name": "",
        }

    def hash(self) -> str:
        return HASH(json.dumps(self.to_dict(), sort_keys=True).encode()).hex()


@dataclass
class Block:
    height: int
    parent_hash: str
    timestamp: float
    proposer: str
    transactions: list[Transaction]
    pouw_proof: Optional[dict]
    state_root: str
    burned: float = 0.0

    def hash(self) -> str:
        body = {
            "height": self.height,
            "parent": self.parent_hash,
            "ts": self.timestamp,
            "proposer": self.proposer,
            "txs": [tx.hash() for tx in self.transactions],
            "pouw": self.pouw_proof,
            "state_root": self.state_root,
            "burned": self.burned,
        }
        return HASH(json.dumps(body, sort_keys=True).encode()).hex()


@dataclass
class Account:
    address: str
    balance: float = 0.0
    nonce: int = 0
    public_root: Optional[str] = None


@dataclass
class AIModel:
    model_id: str
    owner: str
    weights_hash: str
    price_per_call: float
    royalty_pct: float = 0.7
    total_calls: int = 0
    total_earned: float = 0.0


class Blockchain:
    BURN_RATE = 0.5
    AI_BURN_RATE = 0.3

    def __init__(self):
        self.chain: list[Block] = [self._genesis()]
        self.accounts: dict[str, Account] = {}
        self.mempool: list[Transaction] = []
        self.pouw = PoUWConsensus(seed=1)
        self.models: dict[str, AIModel] = {}
        self.total_burned: float = 0.0
        self.total_supply: float = 300_000_000

    def _genesis(self) -> Block:
        return Block(
            height=0,
            parent_hash="0" * 64,
            timestamp=time.time(),
            proposer="qta1genesis",
            transactions=[],
            pouw_proof=None,
            state_root=HASH(b"genesis").hex(),
            burned=0.0,
        )

    def credit(self, address: str, amount: float) -> None:
        acc = self.accounts.setdefault(address, Account(address))
        acc.balance += amount

    def debit(self, address: str, amount: float) -> None:
        acc = self.accounts.setdefault(address, Account(address))
        if acc.balance < amount:
            raise ValueError(f"Insufficient balance for {address}")
        acc.balance -= amount

    def register_account(self, address: str, public_root: str) -> None:
        acc = self.accounts.setdefault(address, Account(address))
        acc.public_root = public_root

    def validate_tx(self, tx: Transaction) -> tuple[bool, str]:
        sender_acc = self.accounts.get(tx.sender)
        if sender_acc is None:
            return False, "Unknown sender"
        if sender_acc.public_root and sender_acc.public_root != tx.public_root:
            return False, "Public root mismatch"
        if sender_acc.balance < tx.amount + tx.fee:
            return False, "Insufficient balance"
        if tx.nonce != sender_acc.nonce:
            return False, f"Bad nonce (expect {sender_acc.nonce}, got {tx.nonce})"
        if not verify(tx.public_root, tx.signed_payload(), tx.signature):
            return False, "Invalid quantum signature"
        return True, "ok"

    def submit_tx(self, tx: Transaction) -> tuple[bool, str]:
        ok, reason = self.validate_tx(tx)
        if not ok:
            return False, reason
        self.mempool.append(tx)
        return True, "queued"

    def produce_block(self, slot_seed: bytes) -> Block:
        proposer = self.pouw.select_proposer(slot_seed)
        if proposer is None:
            raise RuntimeError("No validators registered")

        pouw_proof = None
        if self.pouw.task_queue:
            task = self.pouw.task_queue.pop(0)
            proof = self.pouw.execute_task(proposer, task, demo_executor)
            ok = self.pouw.verify_proof(task, proof, demo_executor)
            self.pouw.reward_and_slash(proposer, ok, work_score=0.95)
            if ok:
                pouw_proof = {"task_id": task.task_id, "result_hash": proof.result_hash,
                              "validator": proposer.address}
                self.credit(proposer.address, self.pouw.BLOCK_REWARD)
                self.total_supply += self.pouw.BLOCK_REWARD

        included: list[Transaction] = []
        block_burned = 0.0
        for tx in list(self.mempool):
            ok, reason = self.validate_tx(tx)
            if not ok:
                continue
            self.debit(tx.sender, tx.amount + tx.fee)
            self.credit(tx.recipient, tx.amount)
            burn = tx.fee * (self.AI_BURN_RATE if tx.tx_type == "ai_call" else self.BURN_RATE)
            self.total_burned += burn
            self.total_supply -= burn
            block_burned += burn
            self.credit(proposer.address, tx.fee - burn)
            self.accounts[tx.sender].nonce += 1
            included.append(tx)
            self.mempool.remove(tx)

        state_root = HASH(json.dumps(
            {a: (acc.balance, acc.nonce) for a, acc in sorted(self.accounts.items())},
            sort_keys=True,
        ).encode()).hex()

        block = Block(
            height=len(self.chain),
            parent_hash=self.chain[-1].hash(),
            timestamp=time.time(),
            proposer=proposer.address,
            transactions=included,
            pouw_proof=pouw_proof,
            state_root=state_root,
            burned=block_burned,
        )
        self.chain.append(block)
        return block

    def register_model(self, owner: str, weights_hash: str, price_per_call: float) -> AIModel:
        model_id = f"mod-{len(self.models):06d}"
        m = AIModel(model_id=model_id, owner=owner, weights_hash=weights_hash,
                    price_per_call=price_per_call)
        self.models[model_id] = m
        return m

    def call_model(self, caller: str, model_id: str) -> dict:
        """User calls inference; royalties split automatically."""
        if model_id not in self.models:
            raise KeyError("model not found")
        model = self.models[model_id]
        price = model.price_per_call
        self.debit(caller, price)
        owner_share = price * model.royalty_pct
        treasury_share = price * 0.05
        burn_share = price * self.AI_BURN_RATE
        validator_share = price - owner_share - treasury_share - burn_share

        self.credit(model.owner, owner_share)
        self.credit("qta1treasury", treasury_share)
        self.credit("qta1validator_pool", validator_share)
        self.total_burned += burn_share
        self.total_supply -= burn_share

        model.total_calls += 1
        model.total_earned += owner_share
        return {
            "model_id": model_id,
            "paid": price,
            "owner_received": owner_share,
            "burned": burn_share,
            "calls_total": model.total_calls,
        }

    def stats(self) -> dict:
        return {
            "height": len(self.chain) - 1,
            "n_accounts": len(self.accounts),
            "n_validators": len(self.pouw.validators),
            "total_supply": round(self.total_supply, 4),
            "total_burned": round(self.total_burned, 4),
            "n_models": len(self.models),
            "mempool": len(self.mempool),
        }
