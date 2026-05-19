"""
QUANTA — End-to-End Demo
========================

Run: `python demo.py` in the prototype/ directory.

Demonstrates the following features:
  1. Create quantum-safe wallets
  2. Register validators + PoUW
  3. Transfer between users
  4. AI agent autonomous transactions + payment channel
  5. AI marketplace: register model + call inference
  6. Burn mechanism reducing total supply
"""

from __future__ import annotations
import time

from quantum_wallet import Wallet
from pouw_consensus import Validator, UsefulTask
from ai_agent import AIAgentWallet, SpendingPolicy, PaymentChannel
from blockchain import Blockchain, Transaction


def section(title: str) -> None:
    print("\n" + "═" * 70)
    print(f"  {title}")
    print("═" * 70)


def main():
    print("⚛️  QUANTA Blockchain — End-to-End Demo")
    print("    Quantum-safe • AI-native • Proof of Useful Work")

    chain = Blockchain()

    # -----------------------------------------------------------------------
    section("1. Create quantum-safe wallets (CRYSTALS-Dilithium-style)")
    # -----------------------------------------------------------------------
    alice = Wallet.create(height=4)
    bob = Wallet.create(height=4)
    print(f"Alice : {alice.address}")
    print(f"Bob   : {bob.address}")

    # Initial funding (simulated genesis distribution)
    chain.register_account(alice.address, alice.public_root)
    chain.register_account(bob.address, bob.public_root)
    chain.credit(alice.address, 1000.0)
    chain.credit(bob.address, 100.0)
    chain.credit("qta1treasury", 0)
    chain.credit("qta1validator_pool", 0)
    print(f"Alice balance: {chain.accounts[alice.address].balance} QTA")
    print(f"Bob balance  : {chain.accounts[bob.address].balance} QTA")

    # -----------------------------------------------------------------------
    section("2. Register validators + enqueue PoUW tasks")
    # -----------------------------------------------------------------------
    for i in range(3):
        v_wallet = Wallet.create(height=3)
        v_addr = v_wallet.address
        chain.register_account(v_addr, v_wallet.public_root)
        chain.credit(v_addr, 20_000.0)
        validator = Validator(address=v_addr, stake=15_000 + i * 2_000, gpu_score=1.0 + i * 0.3)
        chain.pouw.register(validator)
        print(f"Validator {i}: {v_addr}  stake={validator.stake:,.0f}  gpu={validator.gpu_score}")

    for i in range(5):
        chain.pouw.enqueue_task(UsefulTask(
            task_id=f"llm-task-{i}",
            kind="llm_inference",
            payload={"prompt": f"Translate 'hello world' to language #{i}"},
            reward=10.0,
            verifier_hint={},
        ))
    print(f"Queued {len(chain.pouw.task_queue)} useful AI tasks")

    # -----------------------------------------------------------------------
    section("3. Alice transfers 50 QTA to Bob (quantum-signed)")
    # -----------------------------------------------------------------------
    payload = {
        "from": alice.address, "to": bob.address, "amount": 50.0,
        "memo": "for coffee", "nonce": 0, "ts": 0, "agent_name": "",
    }
    sig = alice.sign(payload)
    tx = Transaction(
        sender=alice.address, recipient=bob.address, amount=50.0,
        nonce=0, fee=0.01, public_root=alice.public_root,
        signature=sig, memo="for coffee",
    )
    ok, reason = chain.submit_tx(tx)
    print(f"Submit tx → {ok} ({reason})")

    # -----------------------------------------------------------------------
    section("4. Produce blocks with PoUW")
    # -----------------------------------------------------------------------
    for slot in range(3):
        block = chain.produce_block(slot_seed=f"slot-{slot}".encode())
        print(f"Block #{block.height} | proposer={block.proposer[:20]}... | "
              f"txs={len(block.transactions)} | "
              f"PoUW={'✓' if block.pouw_proof else '-'} | "
              f"burned={block.burned:.4f} QTA")

    print(f"\nAlice balance after: {chain.accounts[alice.address].balance:.4f} QTA")
    print(f"Bob balance after  : {chain.accounts[bob.address].balance:.4f} QTA")

    # -----------------------------------------------------------------------
    section("5. AI Agent Wallet + Payment Channel (x402-style)")
    # -----------------------------------------------------------------------
    agent_policy = SpendingPolicy(max_per_tx=0.5, max_per_hour=5.0,
                                  max_per_day=20.0)
    research_bot = AIAgentWallet.create(
        owner_address=alice.address,
        name="ResearchBot-001",
        policy=agent_policy,
        initial_funding=2.0,
    )
    api_provider_addr = "qta1openrouter_api"
    chain.register_account(research_bot.address, research_bot.base.public_root)
    chain.register_account(api_provider_addr, "")
    print(f"Created AI agent: {research_bot.name}")
    print(f"  Address: {research_bot.address}")
    print(f"  Balance: {research_bot.balance} QTA")
    print(f"  Death-switch: {agent_policy.death_switch_seconds}s")

    print("\n📡 Agent calls LLM API via payment channel...")
    channel = PaymentChannel(research_bot, api_provider_addr, deposit=1.0)
    for i in range(10):
        s = channel.micro_pay(0.0001)
    settle = channel.close()
    print(f"  10 micro-payments executed off-chain")
    print(f"  Fee per inference: 0.0001 QTA = $0.0001 (assuming $1/QTA)")
    print(f"  Settle on-chain: {settle['settle_to_payee']:.4f} QTA → API provider")
    print(f"  Refund:           {settle['refund_to_payer']:.4f} QTA → agent")

    # -----------------------------------------------------------------------
    section("6. AI Model Marketplace — register + monetize")
    # -----------------------------------------------------------------------
    chain.credit(alice.address, 1.0)
    model = chain.register_model(
        owner=alice.address,
        weights_hash="sha3:" + "ab" * 16,
        price_per_call=0.05,
    )
    print(f"Alice registers model: {model.model_id}")
    print(f"  Price per call: {model.price_per_call} QTA")
    print(f"  Royalty to owner: {model.royalty_pct * 100:.0f}%")

    # Bob calls inference 5 times
    for _ in range(5):
        receipt = chain.call_model(bob.address, model.model_id)
    print(f"\nBob called {model.total_calls} inferences. Alice earned {model.total_earned:.4f} QTA")

    # -----------------------------------------------------------------------
    section("7. Network Stats")
    # -----------------------------------------------------------------------
    stats = chain.stats()
    for k, v in stats.items():
        print(f"  {k:20s} : {v}")

    print("\n💎 Burn so far:", chain.total_burned, "QTA")
    print("   → every tx and inference reduces total supply (deflationary)")

    print("\n✨ Demo complete. Every transaction signed with quantum-resistant signature.")
    print("   Prototype code: ~800 lines pure Python, no external dependencies.")


if __name__ == "__main__":
    main()
