<div align="center">

<img src="./assets/quanta-mark.svg" alt="Quanta mark" width="80" height="80"/>

# Quanta

Quanta is an open-source payment and trust layer for autonomous AI agents.

Wallets with rules for AI agents.

</div>

![License](https://img.shields.io/badge/license-MIT-blue.svg) &nbsp; ![Release](https://img.shields.io/badge/release-v0.1.0-blue.svg) &nbsp; ![Tests](https://img.shields.io/badge/tests-176%20passing-brightgreen.svg) &nbsp; ![Network](https://img.shields.io/badge/network-Base%20Sepolia-blueviolet.svg) &nbsp; ![Audit](https://img.shields.io/badge/audit-0%20high-green.svg) &nbsp; ![Status](https://img.shields.io/badge/status-experimental-yellow.svg)

---

## Overview

Quanta provides on-chain agent identity, spending policies, authorized spenders, payment channels, marketplace primitives, and receipts for AI agents.

Current status:

- EVM contracts v1.2
- Base Sepolia deployment
- AgentPay dashboard demo
- TypeScript SDK
- 176 contract tests passing
- real-wallet test completed on Base Sepolia

## Problem

AI agents will need to pay for APIs, tools, models, data, and other agents.
But giving autonomous agents unrestricted wallets is unsafe.

## Solution

Quanta adds:
- agent identity
- spending policies
- authorized spenders
- payment channels
- model marketplace primitives
- on-chain receipts
- open-source SDK and demo dashboard

## Architecture

Quanta consists of the following components:

- QuantaToken: ERC-20 token used for payments and policy enforcement
- AIAgentRegistry: on-chain agent identity with spending policy controls
- AIPaymentChannel: payment channel primitive for agent transactions
- AIModelMarketplace: on-chain marketplace primitives for models and data
- TypeScript SDK: client library for interacting with Quanta contracts
- AgentPay Dashboard: React dashboard demo for the AgentPay flow

## Base Sepolia Deployment

Quanta v1.2 contracts are deployed on Base Sepolia, chain ID 84532.

QuantaToken:
0xBfeC1E5574940E4132296819dd4953A3D990dA9a

AIAgentRegistry:
0x37789b163F27a88e6B358c546C34e6d3d6CC6D0c

AIPaymentChannel:
0x22B28618ef6424F253A4D76cEDF5ddD48C0c2EC8

AIModelMarketplace:
0xBFE04AB65bEA2d0F0A2886C2eC06C5F7622884aA

Owner and deployer wallet:
0x2060378AF1916eCFB1A6734405d4f4a62f1560FC

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

## Demo

The AgentPay dashboard demo is in `demo/agentpay-dashboard`.

- Mock mode requires no wallet.
- Real mode uses Base Sepolia.
- See `demo/agentpay-dashboard/README.md` for detailed setup and real-wallet instructions.

## Security

- No private keys are committed in this repository.
- `.env.local` is ignored.
- Testnet deployment addresses are public.
- This is experimental open-source software.
- Do not use with mainnet funds yet.

## Repository Layout

`contracts/` - Solidity smart contracts and Foundry tests.

`sdk/` - TypeScript SDK and build configuration.

`demo/agentpay-dashboard/` - React dashboard demo for the AgentPay flow.

`deployments/` - Deployment records.

`docs/` - Additional documentation.

`.github/` - CI workflows and project settings.

`setup.sh` - One-shot setup script for contracts and SDK.

`Makefile` - Common build and test commands.

## Development Checks

```bash
cd contracts && forge build && forge test -vvv
cd sdk && npm audit --audit-level=high && npm run build && npm pack --dry-run
cd demo/agentpay-dashboard && npm run build && npm run typecheck
bash -n setup.sh
git diff --check
```

## Roadmap

- improve AgentPay UX
- add more SDK examples
- add agent-to-agent payment examples
- expand marketplace flows
- prepare audited mainnet-ready version
- improve docs and developer onboarding

## License

MIT
