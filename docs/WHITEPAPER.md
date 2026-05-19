# QUANTA Whitepaper v1.0
### Quantum-resistant Universal Agent Network for Transactions & AI

**Date**: 2026
**Authors**: QUANTA Foundation
**Version**: 1.0 (Draft)

---

## Executive Summary

Bitcoin and Ethereum solved the problem of money and smart contracts for humans in the pre-quantum era. But two massive shifts are coming:

1. **Quantum computing** — Within 5-15 years, Shor's algorithm could break ECDSA/EdDSA, making every Bitcoin/Ethereum wallet with an exposed public key drainable within hours.
2. **AI Agent Economy** — By 2030, billions of AI agents will transact autonomously with each other at scales of millions of transactions per second with micro-cent values. Current financial infrastructure was not built for them.

**QUANTA** is a Layer-1 blockchain designed from scratch to address both:

- Lattice-based quantum-resistant signatures (CRYSTALS-Dilithium)
- **Proof of Useful Work (PoUW)** consensus that turns mining compute into useful AI inference
- Native primitives for AI: agent wallets, intent-based transactions, micropayment streaming, on-chain model registry

---

## 1. The Problem

### 1.1. Quantum Threat ("Q-Day")

- IBM, Google, Quantinuum are racing toward fault-tolerant quantum machines. NIST standardized post-quantum algorithms (FIPS 203/204/205) in August 2024.
- ~25% of Bitcoin (~6M BTC) sits in P2PK or address-reused wallets — public keys are exposed. A sufficiently powerful quantum computer would compute the private keys.
- **"Harvest now, decrypt later"**: Adversaries are already storing today's transactions to decrypt tomorrow.

### 1.2. AI Agents Have No Bank

- AI agents need to pay per-API-call, per-LLM-token, per-second of GPU compute.
- Current payment systems (Stripe, banks) don't support sub-$0.01 transactions.
- Agents have no legal identity → can't open accounts. Crypto is the only escape route, but Ethereum gas at $0.50/tx is too expensive for micropayments.

### 1.3. Mining is Wasteful

- Bitcoin consumes ~150 TWh/year — equal to Argentina — just computing meaningless SHA-256. This is massive social loss when the world needs GPUs for AI.

---

## 2. The QUANTA Solution

### 2.1. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│            APPLICATIONS LAYER                            │
│  Human Wallets │ AI Agent Wallets │ DeFi │ AI Market    │
├─────────────────────────────────────────────────────────┤
│            EXECUTION LAYER                               │
│   QVM (Quanta VM) — EVM-compatible + AI opcodes         │
├─────────────────────────────────────────────────────────┤
│            CONSENSUS LAYER                               │
│   Proof of Useful Work (AI inference + Stake)           │
├─────────────────────────────────────────────────────────┤
│            CRYPTOGRAPHY LAYER                            │
│   CRYSTALS-Dilithium (sigs) + Kyber (KEM) + SHA3-256    │
├─────────────────────────────────────────────────────────┤
│            DATA / NETWORK LAYER                          │
│   Sharded DAG + libp2p + zk-rollups for scaling         │
└─────────────────────────────────────────────────────────┘
```

### 2.2. Post-Quantum Cryptography Layer

| Purpose            | Algorithm               | Standard       | Notes                                |
|--------------------|-------------------------|----------------|--------------------------------------|
| Digital signatures | CRYSTALS-Dilithium-3    | NIST FIPS 204  | Public key 1952B, sig 3293B          |
| Key exchange       | CRYSTALS-Kyber-768      | NIST FIPS 203  | For P2P encryption and private memos |
| Hash               | SHA3-256 + BLAKE3       | FIPS 202       | Quantum-safe (Grover gives only √n)  |
| Address hash       | Keccak256(Dilithium-PK) | -              | Creates 32-byte address              |
| Backward compat    | Hybrid Ed25519+Dilithium| -              | Optional for compact wallets         |

**Address format**: `qta1...` (Bech32m, 42 chars) — easy to distinguish from Ethereum/BTC.

### 2.3. Proof of Useful Work (PoUW) Consensus

Instead of meaningless SHA-256, validators must:

1. **Stake** at least 10,000 QTA to register
2. **Receive tasks** from AI task pool (LLM inference, image gen, protein folding, scientific compute)
3. **Execute** on GPU/TPU and return result + proof
4. **Get verified** via:
   - **zkML proof** (ezkl, RiscZero) for small tasks
   - **Optimistic verification** with fraud proofs for large tasks
   - **Redundant execution** (3-of-5 random validators) for mission-critical

Reward = `block_reward × (stake_weight × 0.4 + work_quality_score × 0.6)`

> 💡 **Core viral message**: "Every QUANTA block teaches ChatGPT a new answer. Every watt of electricity mining QUANTA serves humanity."

### 2.4. AI-Native Infrastructure

#### 2.4.1. AI Agent Wallet (AAW)

A special account type featuring:

- **Spending policies**: max $X/hour, address whitelist, per-tx cap
- **Intent-based**: agent signs "intent" ("I want to buy 100 GPU compute tokens at ≤ 0.5 QTA"), solver executes
- **Auto-rotation keys**: rotates key every N transactions (forward secrecy)
- **Death switch**: if agent doesn't ping in T days, auto-refunds owner
- **Reputation score**: linked to DID (Decentralized Identifier)

#### 2.4.2. x402-style Micropayments

Revival of the HTTP 402 standard on QUANTA:

```http
GET /api/llm/inference
→ 402 Payment Required
  X-QUANTA-Price: 0.0001 QTA
  X-QUANTA-Receiver: qta1abc...
  X-QUANTA-Nonce: 0x...

# Client pays in header of next request
Authorization: QUANTA <signed_payment_proof>
→ 200 OK { "completion": "..." }
```

Fees settled batch-wise per block (off-chain channels) → 1 million micro-tx = 1 on-chain tx.

#### 2.4.3. On-chain AI Marketplace

3 objects are tokenized:

| Resource     | Token type       | Value                                      |
|--------------|------------------|--------------------------------------------|
| **Models**   | NFT-MOD          | Inference rights, royalty per use         |
| **Datasets** | NFT-DAT          | Access rights, can be time-limited        |
| **Compute**  | Fungible (cQTA)  | 1 cQTA = 1 GPU-hour of RTX 4090 equivalent |

Royalties auto-split: model creator 70%, validator serving inference 25%, treasury 5%.

### 2.5. Performance

| Metric                  | Target          | How achieved                          |
|-------------------------|-----------------|----------------------------------------|
| TPS                     | 50,000+         | 64-shard + zk-rollup                  |
| Block time              | 1 second        | Tendermint-style BFT                  |
| Finality                | 2 seconds       | Single-slot finality                  |
| Tx fee (human)          | $0.001          | Compute-based pricing                 |
| Tx fee (AI micro)       | $0.000001       | Off-chain payment channels            |
| Quantum sig overhead    | ~3.3 KB/tx      | Compensated via aggregation (BLS-style for Dilithium) |

---

## 3. Notable Features (vs "best of breed")

| Feature                      | Bitcoin | Ethereum | Solana | **QUANTA** |
|------------------------------|---------|----------|--------|------------|
| Quantum-safe signatures      | ❌      | ❌       | ❌     | ✅         |
| Smart contracts              | ❌      | ✅       | ✅     | ✅ (EVM+)  |
| Real-world TPS               | 7       | 30       | 3,000  | 50,000     |
| Sub-$0.001 fees              | ❌      | ❌       | ✅     | ✅         |
| Useful mining                | ❌      | -        | -      | ✅         |
| AI agent native              | ❌      | ❌       | ❌     | ✅         |
| zkML on-chain                | ❌      | Partial  | ❌     | ✅         |
| Privacy (optional)           | ❌      | ❌       | ❌     | ✅ (Kyber memos) |
| MEV resistance               | ❌      | Partial  | Partial| ✅ (encrypted mempool) |
| Account abstraction          | ❌      | EIP-4337 | ✅     | ✅ (native) |
| Cross-chain bridges          | Wrapped | ✅       | ✅     | ✅ (PQ-secured IBC) |

---

## 4. Governance Model

- **QTA holders** vote via quadratic voting (anti-whale)
- **AI Council**: 7 AI models (open-source) trained on tokenomics/security, provide non-binding advisory on every proposal
- **Human Council**: 7 experts (cryptographer, economist, lawyer) with 72h emergency veto
- **Two-house system**: requires majority of holders + one of two councils to pass

---

## 5. Security Model

- **Crypto-agility**: protocol can swap signature algorithms via soft hard fork (each account has version byte)
- **Slashing**: cheating validators lose 100% of stake
- **Bug bounty**: 10M QTA permanent fund, up to 5M for critical
- **Audit**: 3 rounds of independent audit before mainnet

---

## 6. Conclusion

QUANTA is not a Bitcoin fork with "AI" and "quantum" buzzwords. It's a primitive design for a world where:

- Messages can't be decrypted even when commercial quantum computers appear
- AI agents transact with each other more than humans transact with humans
- Every second of compute must deliver social value

Our goal isn't to "beat" Bitcoin or Ethereum. Our goal is to survive when they may not.

> **"The best time to migrate to post-quantum was yesterday. The second best time is QUANTA."**

---

## References

- NIST FIPS 203, 204, 205 (2024)
- Buterin, V. "How will Ethereum transition to quantum-resistant signatures?" (2024)
- Bernstein, D. "Post-quantum cryptography" (2017)
- Ben-Sasson, E. et al. "Scalable, transparent, and post-quantum secure computational integrity" (2018)
- "Proof of Useful Work" — Ball et al. (2017)
- Anthropic, "Model Context Protocol" (2024)
- Coinbase x402 specification (2025)
