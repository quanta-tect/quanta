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

## Demo walkthrough

### Mock mode

1. Open http://localhost:5173 after `npm run dev`.
2. Keep Mock mode on.
3. Register an agent, save a policy, authorize a spender, and simulate a payment.
4. Receipts are labeled `Mock`.

No wallet is required in mock mode.

### Real mode

1. Copy `.env.example` to `.env.local`.
2. Set `VITE_DEMO_MODE=real` and fill contract addresses.
3. Connect a wallet with Base Sepolia selected.
4. Verify the owner status: only the registry owner can authorize spenders.
5. Register an agent, save/update a policy, authorize a spender, then record spend.
6. Each successful receipt includes a BaseScan link.

### Required `.env.local` values

- VITE_DEMO_MODE=real
- VITE_AGENT_REGISTRY_ADDRESS
- VITE_PAYMENT_CHANNEL_ADDRESS
- VITE_MARKETPLACE_ADDRESS
- VITE_QTA_TOKEN_ADDRESS
- VITE_OWNER_ADDRESS

## Test flow

1. Connect wallet
2. Switch to Base Sepolia
3. Register agent
4. Save/update policy
5. Authorize spender
6. Record spend
7. Open tx hash on BaseScan

## Troubleshooting

- Missing addresses: fill contract addresses in `.env.local`.
- Wrong network: switch wallet to Base Sepolia (chainId 84532).
- Wallet not owner: only the registry owner can authorize global spenders.
- User rejected transaction: confirm the transaction in the wallet popup.
- Not enough test ETH: get Base Sepolia ETH from a faucet.

## Notes

- Do not commit `.env.local`.
- This demo intentionally does not touch `sdk/`, `contracts/`, or `.github/`.
