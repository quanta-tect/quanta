# ⚛️ Quanta — Payment & Trust Layer for Autonomous AI Agents

**Wallets with rules cho AI agents.** Built on Base.

Open-source payment và trust layer giúp AI agents thanh toán an toàn cho APIs, models, tools, data và các agent khác.

---

## Overview

Quanta cung cấp cho AI agents những chiếc **wallet có quy tắc** (spending policies, budgets, authorized spenders, payment channels, on-chain receipts).

**Ý tưởng cốt lõi:**
> AI agents nên có khả năng thanh toán.  
> Nhưng chúng không được phép chi tiêu mà không có quy tắc.

Quanta giải quyết vấn đề an ninh khi cho agent sử dụng wallet on-chain.

## Why Quanta?

- Tránh rủi ro agent bị drain toàn bộ wallet
- Hỗ trợ micropayments (x402 style)
- Agent identity + spending policies on-chain
- Model marketplace primitives
- Dễ tích hợp với LangChain, AutoGPT, CrewAI...

## Current Status (v0.1.0)

- **EVM Contracts v1.2** (security hardened)
- Deployed on **Base Sepolia**
- TypeScript SDK
- AgentPay Dashboard (Mock + Real mode)
- 176+ contract tests passing
- SDK security audit: 0 high vulnerabilities
- Real wallet test completed

**Quantum-safe features** đang được nghiên cứu (Dilithium signatures) và sẽ được tích hợp dần.

---

## Core Features

- Agent Identity & Registration
- Spending Policies & Budgets
- Authorized Spenders
- Payment Channels (x402 micropayments)
- AI Model Marketplace primitives
- On-chain Transaction Receipts
- TypeScript SDK
- AgentPay Dashboard Demo

---

## Architecture

| Component            | Description |
|----------------------|-----------|
| QuantaToken          | ERC-20 token với AI tax & burn mechanics |
| AIAgentRegistry      | Agent identity, policies, authorized spenders |
| AIPaymentChannel     | Payment channel cho micropayments |
| AIModelMarketplace   | Marketplace cho models, tools, data |
| TypeScript SDK       | Client library cho developers |
| AgentPay Dashboard   | React demo (mock + real) |

---

## Base Sepolia Deployment

**Network**: Base Sepolia (Chain ID: 84532)

**Contract Addresses** (v1.2):

| Contract              | Address                                      |
|-----------------------|----------------------------------------------|
| QuantaToken           | `0xBfeC1E5574940E4132296819dd4953A3D990dA9a` |
| AIAgentRegistry       | `0x37789b163F27a88e6B358c546C34e6d3d6CC6D0c` |
| AIPaymentChannel      | `0x22B28618ef6424F253A4D76cEDF5ddD48C0c2EC8` |
| AIModelMarketplace    | `0xBFE04AB65bEA2d0F0A2886C2eC06C5F7622884aA` |

**Owner/Deployer**: `0x2060378AF1916eCFB1A6734405d4f4a62f1560FC`

> ⚠️ **Lưu ý**: Đây là testnet. Chưa dùng cho mainnet funds.

---

## Quickstart

```bash
git clone https://github.com/quanta-tect/quanta.git
cd quanta

Run contract checks:

Bash

cd contracts
forge build
forge test -vvv
cd ..
```

Build the SDK:

```bash
cd sdk
npm install
npm run build
cd ..
```

Run the AgentPay dashboard:

```bash
cd demo/agentpay-dashboard
npm install
npm run dev
```

Open:

```text
http://localhost:5173
```

## AgentPay Demo

The AgentPay dashboard is located at:

```text
demo/agentpay-dashboard
```

The demo supports two modes.

### Mock Mode

Mock mode is for quick demos and onboarding.

It does not require:

- wallet connection
- private key
- test ETH
- contract addresses
- Base Sepolia setup

### Real Mode

Real mode uses Base Sepolia contracts and a connected wallet.

The real flow supports:

1. Connect wallet
2. Switch to Base Sepolia
3. Register an agent
4. Save or update spending policy
5. Authorize a spender
6. Record spend on-chain
7. Open the transaction receipt

See the detailed dashboard guide:

```text
demo/agentpay-dashboard/README.md
```

## Repository Layout

```text
contracts/                 Solidity smart contracts and Foundry tests
sdk/                       TypeScript SDK
demo/agentpay-dashboard/   React AgentPay dashboard demo
examples/api-metering-server/ API metering server example for AI agents
deployments/               Deployment records
docs/                      Additional documentation
.github/                   CI workflows and project settings
assets/                    Branding assets
setup.sh                   One-shot setup script
Makefile                   Common build and test commands
```

## Development Checks

Run these before opening a PR:

```bash
cd contracts
forge build
forge test -vvv
cd ..
```

```bash
cd sdk
npm audit --audit-level=high
npm run build
npm pack --dry-run
cd ..
```

```bash
cd demo/agentpay-dashboard
npm run build
npm run typecheck
cd ../..
```

```bash
bash -n setup.sh
git diff --check
```

## Security

This is experimental testnet software.

Do not use with mainnet funds yet.

Do not commit:

- private keys
- mnemonics
- wallet keystores
- RPC secrets
- `.env.local` files

Only public testnet contract addresses should be committed.

## Roadmap

- Improve AgentPay UX
- Add more SDK examples
- Add agent-to-agent payment examples
- Expand marketplace flows
- Add more developer documentation
- Prepare audited mainnet-ready version
- Improve onboarding for builders

## Release

Current release:

```text
v0.1.0 - AgentPay Testnet Release
```

Release notes:

```text
RELEASE_NOTES_v0.1.0.md
```

Changelog:

```text
CHANGELOG.md
```

## License

MIT
