# Quanta AgentPay Dashboard Demo

A minimal frontend demo showing the core value of Quanta:
> Give an AI agent a wallet, a spending policy, and a payment receipt.

## What it shows

- Register/create an AI agent
- Configure spending policy (max per tx, max per day)
- Manage authorized spender address
- Simulate agent payment checks
- Display receipts/history
- Supports mock/local mode and Base Sepolia configuration

## Prerequisites

- Node.js >= 18
- npm >= 9

## Run (mock mode)

```bash
cd demo/agentpay-dashboard
npm install
npm run dev
```

Open `http://localhost:5173`.

## Run (Base Sepolia mode)

```bash
cp .env.example .env
# Edit .env with your RPC URL and contract addresses
npm run dev
```

Connect your wallet when prompted. In Base Sepolia mode, transactions will be sent to the real deployed contracts.

## Scripts

- `npm run dev` — start dev server
- `npm run build` — production build to `dist/`
- `npm run typecheck` — TypeScript type check

## Notes

- Mock mode does not require private keys and does not submit real transactions.
- Base Sepolia mode requires an EOA private key in `.env` (recommend using `cast wallet import` + `--account` pattern; do not commit secrets).
- Contract ABIs are minimal fragments for demo purposes only. For production, use the full ABIs from `contracts/out/`.

## Limitations

- No persistence; data resets on refresh.
- Mock mode uses local in-memory state.
- Real mode is read/write and requires Base Sepolia ETH for gas.
