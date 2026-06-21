# 📋 HACKATHON APPLICATION — ETHGlobal

**Project:** QUANTA Protocol
**Track:** AI × Web3 / Payments / Infrastructure
**Team:** Solo founder

---

## Project Description

QUANTA is "Stripe for AI Agents" — a quantum-resistant payment protocol that enables AI agents to transact autonomously at micro-scale.

### The Problem
AI agents (ChatGPT, Claude, AutoGPT) need to pay each other for API calls, GPU time, and LLM tokens. But:
- Stripe doesn't support sub-$0.01 transactions
- Ethereum gas ($0.50/tx) is too expensive for micropayments
- AI agents have no legal identity — can't open bank accounts

### The Solution
QUANTA provides:
1. **Payment Channels**: 1M micropayments = 2 on-chain tx. Fees: ~$0.000001.
2. **Agent Registry**: On-chain identity + spending policies + reputation.
3. **Model Marketplace**: AI models sell inference with automatic royalty distribution.
4. **Quantum-Resistant**: Dilithium3 (NIST FIPS 204) lattice-based signatures.

### Demo (5 min)
1. Register an AI agent on QUANTA
2. Open payment channel with another agent
3. Stream 1000 micropayments off-chain
4. Close channel — single on-chain settlement
5. Show AI model marketplace: register model, buy inference, automatic royalty split

## Technical Stack

- **Layer 2**: Solidity 0.8.24 on Base Sepolia (Coinbase L2)
- **Layer 1**: Rust/Substrate with Dilithium3 post-quantum signatures
- **SDK**: TypeScript (viem)
- **CI/CD**: GitHub Actions (Slither, Mythril, gitleaks)

## What's Already Built

- ✅ 4 smart contracts deployed + verified on Base Sepolia
- ✅ TypeScript SDK working
- ✅ 100+ tests (Rust + Solidity)
- ✅ Rust L1 node (native + WASM)
- ✅ Security audit completed
- ✅ CI/CD pipeline

## What We'd Build at Hackathon

- **Dashboard MVP**: React app showing agent spending, channel status, tax reports
- **LangChain Integration**: QUANTA as a LangChain Tool for AI agent payments
- **Demo Video**: Full flow from agent registration to micropayment settlement

## Why QUANTA Wins

1. **Novel**: First quantum-safe AI agent payment protocol
2. **Working**: Already deployed and tested, not just a whitepaper
3. **Impactful**: Enables the entire AI agent economy to transact
4. **Technical depth**: Post-quantum crypto, state channels, Substrate node
5. **Open source**: MIT licensed, community-driven

## Links

- GitHub: https://github.com/quanta-tect/quanta
- Base Sepolia: https://base-sepolia.blockscout.com
- Demo: SDK examples in repo

## Bounties We're Applying For

- **Base**: Best project on Base
- **Optimism**: Best cross-chain project
- **Chainlink**: Best use of CCIP for cross-chain agent identity
- **The Graph**: Best indexing of agent transactions
