# AGENTS.md — QUANTA Project Conventions

Read this file at the start of every AI session.

## Project
QUANTA Protocol — AI agent payment infrastructure on Base (Coinbase L2).
- 4 smart contracts: QuantaToken, AIAgentRegistry, AIPaymentChannel, AIModelMarketplace
- Version: v1.2 (security hardened + KYC + tax reporting)
- Status: Testnet deployed, verified, SDK demo working

## Tech Stack
- Solidity 0.8.24, OpenZeppelin, Foundry
- TypeScript SDK, viem, Node.js (ESM)
- Base Sepolia (chainId 84532) testnet

## Rules
- NEVER hardcode private keys — use read -s or env vars
- NEVER modify addresses without updating: sdk/src/types.ts, DEPLOYMENTS.md, PROJECT_CONTEXT.md
- ALWAYS run forge test after contract changes
- ALWAYS update PROJECT_CONTEXT.md + MEMORY.md at session end
- ALWAYS unset ETHERSCAN_API_KEY + BASESCAN_API_KEY before verify with sourcify
- DO NOT add [etherscan] section back to foundry.toml
- SDK uses viem (not ethers.js). Payment channel needs prior approve()
- User speaks Vietnamese, works on local machine, prefers sed over new files

## Contracts (v1.2 Final — Base Sepolia)
- QuantaToken:       0x312137fb6943F8f89F5eF0f221aA102035a16625
- AIAgentRegistry:   0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB
- AIPaymentChannel:  0xF146e95b97fce1d1800F5F922AE99155711A4314
- AIModelMarketplace: 0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49
- Treasury/Deployer: 0x288bc8d816f9C2E00af706fEBFeac9a7B149c110
