<p align="center">
  <img src="./assets/quanta-mark.svg" alt="Quanta mark" width="96" height="96">
</p>

<h1 align="center">Quanta</h1>

<p align="center">
  Open-source payment and trust layer for autonomous AI agents.
</p>

<p align="center">
  <strong>Wallets with rules for AI agents.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
  <img src="https://img.shields.io/badge/release-v0.1.0-blue.svg" alt="Release v0.1.0">
  <img src="https://img.shields.io/badge/tests-176%20passing-brightgreen.svg" alt="176 tests passing">
  <img src="https://img.shields.io/badge/network-Base%20Sepolia-blueviolet.svg" alt="Base Sepolia">
  <img src="https://img.shields.io/badge/audit-0%20high-green.svg" alt="SDK audit 0 high">
  <img src="https://img.shields.io/badge/status-experimental-yellow.svg" alt="Experimental">
</p>

---

## Overview

Quanta is an open-source payment and trust layer for autonomous AI agents.

AI agents will need to pay for APIs, tools, models, data, infrastructure, and other agents. Quanta gives them wallets with rules: identity, budgets, permissions, authorized spenders, payment channels, marketplace primitives, and on-chain receipts.

## Why Quanta

Giving an AI agent an unrestricted wallet is unsafe.

Quanta is designed around a simple idea:

```text
AI agents should be able to pay.
But they should not be able to spend without rules.
```

Quanta adds the missing control layer between autonomous agents and on-chain payments.

## Current Status

- EVM contracts v1.2
- Base Sepolia deployment
- AgentPay dashboard demo
- TypeScript SDK
- 176 contract tests passing
- SDK audit with 0 high vulnerabilities
- Real-wallet test completed on Base Sepolia
- Public testnet release v0.1.0

## Core Features

- Agent identity
- Spending policies
- Authorized spenders
- Payment channels
- Model marketplace primitives
- On-chain transaction receipts
- TypeScript SDK
- AgentPay dashboard demo

## Architecture

Quanta consists of six main components:

| Component | Description |
|---|---|
| QuantaToken | ERC-20 token used for payments and policy enforcement |
| AIAgentRegistry | On-chain agent identity, spending limits, and authorized spender controls |
| AIPaymentChannel | Payment channel primitive for agent transactions |
| AIModelMarketplace | Marketplace primitive for AI models, tools, and data |
| TypeScript SDK | Client library for apps and developers |
| AgentPay Dashboard | React demo for testing mock mode and Base Sepolia real mode |

## Base Sepolia Deployment

Quanta v1.2 contracts are deployed on Base Sepolia.

```text
Network: Base Sepolia
Chain ID: 84532
```

| Contract | Address |
|---|---|
| QuantaToken | 0xBfeC1E5574940E4132296819dd4953A3D990dA9a |
| AIAgentRegistry | 0x37789b163F27a88e6B358c546C34e6d3d6CC6D0c |
| AIPaymentChannel | 0x22B28618ef6424F253A4D76cEDF5ddD48C0c2EC8 |
| AIModelMarketplace | 0xBFE04AB65bEA2d0F0A2886C2eC06C5F7622884aA |

Owner and deployer wallet:

```text
0x2060378AF1916eCFB1A6734405d4f4a62f1560FC
```

## Quickstart

Clone the repository:

```bash
git clone https://github.com/quanta-tect/quanta.git
cd quanta
```

Run contract checks:

```bash
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
