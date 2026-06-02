# QUANTA PROJECT — Full Context Summary

> **Last updated**: June 2, 2026
> **Purpose**: Give any AI assistant full context about QUANTA project state

---

## 📋 Project Overview

**QUANTA** = Quantum-resistant Universal Agent Network for Transactions & AI

- **Type**: Layer-1 blockchain (currently on Base Sepolia testnet)
- **Token**: QTA (ERC-20), 1B hard cap, 300M genesis
- **GitHub**: https://github.com/quanta-tect/quanta
- **License**: MIT

---

## ✅ What's Been Done (as of June 2, 2026)

### Smart Contracts (v1.1 — All Verified on BaseScan ✅)

| Contract | Address | Verified |
|---|---|---|
| **QuantaToken (QTA)** | `0x4e2B5dE8d3fE3a6C84D34FFf5E673f47010eEc9e` | ✅ |
| **AIAgentRegistry** | `0x9D6d634D4C4D7fF1b920e980793f07c87CD45908` | ✅ |
| **AIPaymentChannel** | `0xE68dad3095B93476AaeB718E0A4ed3CC5B342272` | ✅ |
| **AIModelMarketplace** | `0xd545F870Dc1d62E7bF6681CC0984e526a74b6785` | ✅ |

**Treasury**: `0x1d6a9512fF4A98C192A99Adea934ac3f83035953` (holds 300M QTA)
**Network**: Base Sepolia (chainId 84532)
**RPC**: `https://sepolia.base.org`

### SDK (TypeScript)
- Contract addresses updated ✅
- ABI fixed for v1.1 ✅

### Security
- Internal audit: 30 findings, all fixed ✅
- Fuzz + invariant tests passing ✅

### Community (Phase B — DONE)
- Twitter: @Quanta_Protocol ✅
- Discord server ✅
- Mirror.xyz blog ✅
- Launch thread posted ✅

---

## ⚠️ Known Issues

1. **BaseScan API V1 deprecated**: Use Etherscan V2 API (`api.etherscan.io/v2/api` with `chainid=84532`)
2. **Etherscan API key**: Register on etherscan.io (NOT basescan.org)
3. **Verification**: Use Standard JSON Input format + `evmversion: "cancun"`

---

## 📋 Remaining Tasks

- [ ] Test SDK end-to-end on testnet
- [ ] Cross-post (HN, Reddit, LinkedIn)
- [ ] Submit audit applications
- [ ] Apply Base Builder Grant
- [ ] Viral demo video
- [ ] Mainnet preparation

---

## 🚀 Quick Commands

```bash
# Build
cd ~/quanta/contracts && forge build

# Test
forge test --match-path "test-v1.1/**" -vvv

# Deploy
forge script script/DeployV11.s.sol:DeployV11Script --rpc-url https://sepolia.base.org --private-key $DEPLOYER_KEY --broadcast -vvv[200~This file provides full context for any AI assistant working on the QUANTA project.
