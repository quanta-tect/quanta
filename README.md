# ⚛️ Quanta — Payment & Trust Layer for Autonomous AI Agents

**Wallets with rules for AI agents.** Built on Base.

Open-source payment and trust layer for autonomous AI agents.

---

## Overview

Quanta is an open-source payment and trust layer designed for autonomous AI agents.

AI agents need to pay for APIs, models, tools, data, infrastructure, and other agents. Quanta provides them with **controlled wallets** featuring identity, budgets, spending policies, authorized spenders, payment channels, marketplace primitives, and on-chain receipts.

## Why Quanta?

Giving an AI agent an unrestricted wallet is dangerous.

Quanta is built around one core principle:

> **AI agents should be able to pay — but they should not be able to spend without rules.**

---

## Current Status (v0.1.0)

- EVM Smart Contracts v1.2 (security hardened)
- Deployed on **Base Sepolia**
- TypeScript SDK
- AgentPay Dashboard (Mock + Real mode)
- 176+ passing contract tests
- SDK security audit: 0 high vulnerabilities
- Real wallet integration tested on Base Sepolia
- Public testnet release

---

## Core Features

- Agent Identity & Registry
- Spending Policies & Budget Controls
- Authorized Spenders
- Payment Channels (x402-style micropayments)
- AI Model / Tool / Data Marketplace primitives
- On-chain Transaction Receipts
- TypeScript SDK
- AgentPay Dashboard Demo

---

## Architecture

| Component              | Description |
|------------------------|-----------|
| **QuantaToken**        | ERC-20 token with payment and policy enforcement |
| **AIAgentRegistry**    | On-chain agent identity, spending limits, and authorized spender controls |
| **AIPaymentChannel**   | Payment channel primitive for efficient agent transactions |
| **AIModelMarketplace** | Marketplace primitives for AI models, tools, and data |
| **TypeScript SDK**     | Developer-friendly client library |
| **AgentPay Dashboard** | React demo for testing (mock + live on Base Sepolia) |

---

## Base Sepolia Deployment

**Network**: Base Sepolia  
**Chain ID**: 84532

| Contract               | Address                                      |
|------------------------|----------------------------------------------|
| QuantaToken            | `0xBfeC1E5574940E4132296819dd4953A3D990dA9a` |
| AIAgentRegistry        | `0x37789b163F27a88e6B358c546C34e6d3d6CC6D0c` |
| AIPaymentChannel       | `0x22B28618ef6424F253A4D76cEDF5ddD48C0c2EC8` |
| AIModelMarketplace     | `0xBFE04AB65bEA2d0F0A2886C2eC06C5F7622884aA` |

**Deployer / Owner**: `0x2060378AF1916eCFB1A6734405d4f4a62f1560FC`

> ⚠️ **Security Notice**: This is experimental testnet software. Do not use with real funds.

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
