# AgentPay Dashboard Demo

React + Vite dashboard for Quanta AgentPay.

## Setup

1. Copy `.env.example` to `.env.local`.
2. Fill in your wallet / RPC if needed.
3. Install deps: `npm install`
4. Run: `npm run dev`

## Base Sepolia Configuration

ChainId: `84532`
RPC: `https://sepolia.base.org`

Contract addresses:
- QuantaToken: `0xBfeC1E5574940E4132296819dd4953A3D990dA9a`
- AIAgentRegistry: `0x37789b163F27a88e6B358c546C34e6d3d6CC6D0c`
- AIPaymentChannel: `0x22B28618ef6424F253A4D76cEDF5ddD48C0c2EC8`
- AIModelMarketplace: `0xBFE04AB65bEA2d0F0A2886C2eC06C5F7622884aA`

Connect the deployer/owner wallet `0x2060378AF1916eCFB1A6734405d4f4a62f1560FC`, ensure the network is Base Sepolia (chainId `84532`), then use the UI toggle or `.env.local` setting to switch to real mode.
