# ⚛️ QUANTA — Quantum-resistant Universal Agent Network for Transactions & AI

> "Money for the future isn't just quantum-resistant — it speaks AI's language."

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()
[![Quantum Safe](https://img.shields.io/badge/Quantum-Safe-purple.svg)]()
[![AI Native](https://img.shields.io/badge/AI-Native-blue.svg)]()
[![PoUW](https://img.shields.io/badge/Consensus-PoUW-green.svg)]()

---

## 🎯 Summary

**QUANTA** is a next-generation Layer-1 blockchain designed from the ground up for the post-quantum era and the AI agent economy:

- 🔐 **Quantum-Safe**: CRYSTALS-Dilithium signatures (NIST FIPS 204)
- 🧠 **Proof of Useful Work**: AI inference instead of meaningless hashing
- 🤖 **AI Agent Native**: dedicated agent wallets, x402 micropayments, on-chain spending policies
- 🛒 **On-chain AI Marketplace**: tokenized models, datasets, and compute
- ⚡ **50,000+ TPS** with sharding + zk-rollups
- 💎 **Deflationary** through AI inference fee burns

## 📦 Project structure

```
quanta/
├── README.md
├── INDEX.md                  # Master file map (read this!)
├── LAUNCH_GUIDE_7_DAYS.md    # Day-by-day launch plan
├── setup.sh                  # One-shot setup
│
├── docs/                     # 📚 Strategy & design docs
│   ├── WHITEPAPER.md
│   ├── TOKENOMICS.md
│   ├── ROADMAP.md
│   └── MARKETING.md
│
├── docs-security/            # 🛡️ Security playbook (most important!)
│   ├── BRIDGE_SECURITY_REVIEW.md
│   ├── INCIDENT_RESPONSE.md
│   └── AUDIT_OPTIONS_COMPARISON.md
│
├── prototype/                # 🐍 Python L1 prototype (educational)
│
├── contracts/                # 🔗 Solidity smart contracts
│   ├── src-v1.1/             # Production (all security fixes applied)
│   ├── test-v1.1/            # Security regression tests
│   ├── test-invariant/       # Foundry + Echidna invariants
│   └── test-formal/          # Halmos formal verification
│
├── bridge/                   # 🌉 Hyperlane bridge implementation
│
├── sdk/                      # 📦 TypeScript SDK
│
├── forta-bot/                # 🤖 Real-time security monitoring
│
├── multisig-setup/           # 🔐 Gnosis Safe ceremony + scripts
│
├── wargames/                 # 🎮 6 incident response drills
│
├── audit-applications/       # 📜 Ready-to-submit audit applications
│
├── security-training/        # 🎓 7-course curriculum
│
├── wallet-ui/                # 📱 Wallet with tx simulation
│
├── content/                  # 🎨 Marketing assets
│
├── explorer/                 # 🔍 Live block explorer mockup
│
├── landing/                  # 🌐 Marketing landing page
│
└── simulator/                # 📊 Tokenomics simulator
```

## 🏃 Quick start

```bash
# All-in-one
bash setup.sh

# Or individually:
cd prototype && python3 demo.py                 # Python L1 demo
cd simulator && python3 tokenomics_sim.py --all # 50-year tokenomics
cd contracts && forge test                      # Solidity tests
cd sdk && npm install && npm run demo:agent     # AI agent demo
open landing/index.html                         # Marketing site
open explorer/index.html                        # Live explorer (simulated)
open wallet-ui/index.html                       # Safe wallet with tx simulation
```

## 🗺️ Deployment roadmap

### ✅ Phase 0 — Now (Done in this repo)
- Whitepaper, tokenomics, full prototype, landing page, simulator
- Smart contracts (Solidity v1.1 with all security fixes)
- TypeScript SDK with examples
- Marketing content kit (launch thread + 30-day calendar)
- Block explorer mockup
- Complete security suite (audit, war games, training, etc.)

### 🔨 Phase 1 — Next 30 days
1. **Week 1**: Deploy v1.1 smart contracts to Base Sepolia (testnet)
2. **Week 2**: Set up Twitter, Discord, Mirror blog
3. **Week 3**: Publish launch thread + viral demo video
4. **Week 4**: Deploy to Base mainnet + Uniswap V3 pool

### 🚀 Phase 2 — Months 2-3
- Audit smart contracts (Code4rena / Sherlock / Cantina)
- Deploy across L2s (Arbitrum, Optimism, Polygon)
- Hackathon $50K prize pool
- First 1000 AI agents registered

### 🌌 Phase 3 — Months 4-12
- Rust L1 implementation
- Devnet → Testnet → Mainnet
- AI Council formation
- Full DAO governance

## 💡 Killer use cases

| For Humans | For AI Agents |
|------------|---------------|
| Quantum-safe savings | Self-sovereign wallet from birth |
| DeFi resistant to Q-Day | Earn from selling inference/data |
| Earn from AI inference royalties | Pay other AIs micro-cents for services |
| Stake to validate useful AI work | Operate 24/7 with policy guardrails |
| Cheap remittance via L2 | Cross-agent reputation |
| NFT model creator monetization | Death-switch + insurance |

## 📊 Key numbers

- **1B QTA** hard cap
- **70%** royalty to model creators (highest in industry)
- **50%** tx fee burned + **30%** AI fee burned
- **Net deflation** from year 7 (base case scenario)
- **$0.000001** target fee for AI micropayments
- **50,000+ TPS** target throughput
- **2 seconds** finality

## 🛡️ Security First

This project takes security seriously:

- ✅ Internal audit complete (30 findings, all fixed in v1.1)
- ✅ Echidna + Foundry invariant fuzz testing
- ✅ Halmos formal verification of critical properties
- ✅ CI: Slither + Mythril + secret scanning
- ✅ Real-time Forta monitoring bot
- ✅ Gnosis Safe multisig setup guide
- ✅ 6 war game scenarios for incident response
- ✅ 7-course security training curriculum
- ✅ Bug bounty + audit application templates

**Read `SECURITY_AUDIT.md` and `docs-security/` before any mainnet deployment.**

## 🤝 Contributing

We need:
- 🔐 Cryptographers (Dilithium / Kyber experience)
- 🦀 Rust developers (Substrate / Cosmos SDK)
- 🤖 AI engineers (PoUW verification, zkML)
- 🎨 Designers (UI/UX for wallet + explorer)
- 📣 Community builders + memers

## ⚠️ Disclaimer

This is a proof-of-concept project for educational and research purposes.
Not investment advice. Audit before deploying to mainnet with real value.

## 📜 License

MIT © QUANTA Foundation

All funds go toward:
- 🔐 Smart contract audits
- 🛠️ Developer grants
- 🎓 Educational content
- ☕ Coffee for late-night coding
