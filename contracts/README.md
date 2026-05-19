# QUANTA Smart Contracts

Smart contracts deploying QUANTA on EVM chains (Ethereum, Base, Arbitrum, Polygon) — enabling real token launch with DEX liquidity, before the standalone L1 is ready.

## 📦 Contracts

| File | Mô tả |
|------|-------|
| `QuantaToken.sol` | ERC-20 with burn, permit, governance, tax-on-AI-use |
| `QuantumGuard.sol` | Quantum-safe signature verification (Lamport on-chain) |
| `AIAgentRegistry.sol` | Đăng ký AI agent with spending policy + reputation |
| `AIPaymentChannel.sol` | x402-style payment channel for micro-tx |
| `AIModelMarketplace.sol` | Marketplace mua bán inference, auto royalty |
| `QuantaStaking.sol` | Stake để earn reward + boost |

## 🛠️ Setup (Foundry)

```bash
# Cài Foundry
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Build
forge build

# Test
forge test -vv

# Deploy testnet (Base Sepolia)
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast --verify
```

## 🚀 Deployment strategy

**Phase A**: Deploy `QuantaToken` lên Base mainnet → create Uniswap V3 pool → có giá thật
**Phase B**: Deploy `AIAgentRegistry` + `AIPaymentChannel` → demo AI agent live
**Phase C**: Deploy `AIModelMarketplace` → first creator monetization story
**Phase D**: Bridge sang Ethereum + Arbitrum khi có TVL

## ⚠️ Audit before mainnet

- Slither (free, run every PR)
- Mythril (semi-automated)
- Trail of Bits or Halborn ($50-150K) before khi TVL > $1M
