# Quanta v0.1.0 - AgentPay Testnet Release

Quanta is an open-source payment and trust layer for autonomous AI agents.

This release includes EVM smart contracts, a TypeScript SDK, and the AgentPay dashboard demo deployed and tested on Base Sepolia.

## What is included in v0.1.0

- QuantaToken ERC-20
- AIAgentRegistry for agent identity, spending policies, and authorized spenders
- AIPaymentChannel payment channel primitive
- AIModelMarketplace model and data marketplace primitives
- TypeScript SDK
- AgentPay dashboard demo with mock mode and real-wallet mode
- Base Sepolia real-wallet test completed

## Base Sepolia contract addresses

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

## How to run the demo

Run contract checks:

cd contracts
forge build
forge test -vvv
cd ..

Build the SDK:

cd sdk
npm install
npm run build
cd ..

Run the dashboard:

cd demo/agentpay-dashboard
npm install
npm run dev

Mock mode requires no wallet.
For real mode, see demo/agentpay-dashboard/README.md.

## Security note

This is testnet and experimental software.
Do not use with mainnet funds.
No private keys are committed.
.env.local is ignored.

## Links

- README: README.md
- Demo guide: demo/agentpay-dashboard/README.md
