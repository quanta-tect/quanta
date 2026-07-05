# Quanta AgentPay Dashboard Demo

A minimal React + Vite dashboard that demonstrates the core Quanta AgentPay flow:

- Create/register an AI agent
- Set a daily spend policy
- Authorize a spender contract/address
- Simulate an agent payment
- View receipts/history

## Run in mock mode

```bash
cd demo/agentpay-dashboard
npm install
npm run dev
```

Open http://localhost:5173. No private key required.

## Run in Base Sepolia real mode

Copy `.env.example` to `.env.local` (do not commit `.env.local`), ensure `VITE_DEMO_MODE=real`, and use the deployed Base Sepolia addresses:

- QuantaToken: `0xBfeC1E5574940E4132296819dd4953A3D990dA9a`
- AIAgentRegistry: `0x37789b163F27a88e6B358c546C34e6d3d6CC6D0c`
- AIPaymentChannel: `0x22B28618ef6424F253A4D76cEDF5ddD48C0c2EC8`
- AIModelMarketplace: `0xBFE04AB65bEA2d0F0A2886C2eC06C5F7622884aA`

Connect the deployer/owner wallet `0x2060378AF1916eCFB1A6734405d4f4a62f1560FC`, ensure the network is Base Sepolia (chainId `84532`), then use the UI toggle or `.env.local` setting to switch to real mode.

## What is implemented vs mock

- Agent registration is local state in demo.
- Spending policy enforcement is simulated in the browser.
- Payment receipt generation uses live contract calls only in real mode.
- Real mode shows only-owner guidance when the connected wallet is not the registry owner.

## Notes

- Do not commit `.env.local`.
- This demo intentionally does not touch `sdk/`, `contracts/`, or `.github/`.
