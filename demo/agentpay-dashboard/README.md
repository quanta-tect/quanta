# QUANTA AgentPay Demo

A minimal web dashboard demo that shows the core value of Quanta:

> "Give an AI agent a wallet, a spending policy, and a payment receipt."

## What it does

- Create/register an AI agent
- Configure a spending policy (max per tx, max per day)
- Manage authorized spender addresses
- Simulate agent payments and see pass/fail reasons
- View receipt history

## Modes

### Mock / Local mode (default)

No private key or RPC node needed. Uses local React state with realistic policy enforcement.

```bash
cd demo/agentpay-dashboard
npm install
npm run dev
```

Open `http://localhost:5173`.

### Base Sepolia mode

1. Copy `.env.example` to `.env`
2. Fill:
   - `VITE_RPC_URL` — Base Sepolia RPC
   - `VITE_AGENT_REGISTRY_ADDRESS`, `VITE_PAYMENT_CHANNEL_ADDRESS`, `VITE_QTA_TOKEN_ADDRESS` — deployed contract addresses
   - Optional wallet client/account if your browser extension provides it
3. Run `npm run dev` and enable real mode from the UI/config once contract wiring exists.

> If real mode wiring is not implemented yet, mock mode still works.

## How to run locally

```bash
# from repo root
cd demo/agentpay-dashboard
npm install
npm run dev
```

## Limitations

- Mock mode only enforces business logic locally; no on-chain state or transactions.
- Base Sepolia real mode requires deployed contract addresses and a funded wallet.
- No retries, no multisig, no Audius/NFT integration in this MVP.
