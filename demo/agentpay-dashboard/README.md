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

## Base Sepolia mode

Update `.env` with real contract addresses and RPC URL. The UI exposes a mock/real toggle.

## What is implemented vs mock

- Agent registration is local state only.
- Spending policy enforcement is simulated in the browser.
- Payment receipt generation is mock-based.
- No real transactions are sent unless you wire the env and toggle off mock mode.

## Notes

- Do not commit `.env`.
- This demo intentionally does not touch `sdk/`, `contracts/`, or `.github/`.
