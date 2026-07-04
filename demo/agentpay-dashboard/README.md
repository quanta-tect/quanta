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

Copy `.env.example` to `.env`, set `VITE_DEMO_MODE=real`, and fill in the contract addresses already published in `.env.example`:

- QuantaToken: `0x6d089d25035868358952b4d3644f8dAdcCc3295a`
- AIAgentRegistry: `0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB`
- AIPaymentChannel: `0xF146e95b97fce1d1800F5F922AE99155711A4314`
- AIModelMarketplace: `0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49`

Connect a wallet, ensure the network is Base Sepolia (chainId `84532`), and use the UI toggle or `.env` setting to switch from mock to real mode.

## What is implemented vs mock

- Agent registration is local state only.
- Spending policy enforcement is simulated in the browser.
- Payment receipt generation is mock-based.
- No real transactions are sent unless you wire the env and toggle off mock mode.

## Notes

- Do not commit `.env`.
- This demo intentionally does not touch `sdk/`, `contracts/`, or `.github/`.
