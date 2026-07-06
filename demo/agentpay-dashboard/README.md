# AgentPay Dashboard Demo

React and Vite dashboard for Quanta AgentPay.

Quanta AgentPay gives AI agents wallets with rules:
- budgets
- permissions
- authorized spenders
- on-chain receipts

## Run in mock mode

Mock mode does not require a wallet, private key, contract address, or test ETH.

```bash
cd demo/agentpay-dashboard
npm install
npm run dev

Open:

http://localhost:5173

Keep Mock mode enabled in the UI.

## Run in Base Sepolia real mode

Create .env.local from .env.example:

```bash
cp .env.example .env.local
```

Use these values:

```bash
VITE_CHAIN_ID=84532
VITE_CHAIN_NAME=Base Sepolia
VITE_RPC_URL=https://sepolia.base.org

VITE_AGENT_REGISTRY_ADDRESS=0x37789b163F27a88e6B358c546C34e6d3d6CC6D0c
VITE_PAYMENT_CHANNEL_ADDRESS=0x22B28618ef6424F253A4D76cEDF5ddD48C0c2EC8
VITE_MARKETPLACE_ADDRESS=0xBFE04AB65bEA2d0F0A2886C2eC06C5F7622884aA
VITE_QTA_TOKEN_ADDRESS=0xBfeC1E5574940E4132296819dd4953A3D990dA9a

VITE_DEMO_MODE=real
```

Then restart the dev server:

```bash
npm run dev
```

## Base Sepolia contracts

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

## Real mode walkthrough

1. Connect wallet.
2. Switch to Base Sepolia.
3. Make sure Mock mode is off.
4. Register an agent.
5. Save or update the spending policy.
6. Authorize a spender.
7. Record spend.
8. Open the transaction hash on BaseScan.

## Troubleshooting

Missing addresses:
Check .env.local, then restart npm run dev.

Wrong network:
Switch your wallet to Base Sepolia.

Wallet is not owner:
Only the registry owner can authorize global spenders.

Transaction rejected:
The wallet user rejected the transaction.

Not enough test ETH:
Get Base Sepolia ETH from a faucet.

## Security notes

Do not commit:

- .env.local
- private keys
- mnemonics
- RPC secrets
- wallet keystores

Only public testnet contract addresses should be committed.
