# Quanta AgentPay API Metering Server Example

This example shows how an API or model provider can use Quanta to control AI agent access and record spend.

## What it demonstrates

- A simple Express server that proxies API calls for AI agents.
- Mock-mode metering with fake agent IDs and spending limits.
- A clear path to real-mode metering on Base Sepolia.

## How API sellers can meter usage for AI agents

1. A buyer agent is identified by its agent ID.
2. The seller checks the agent's registry policy (or a local mock policy in this example).
3. On each API request, usage is measured and matched against the allowable spend.
4. The seller records the charge through Quanta (documented for real mode).

## Mock Mode (default)

Mock mode is enabled when `QUANTA_RPC_URL` is empty.

Behavior:
- `/health` returns `{"status":"ok"}`
- `POST /api/generate` accepts `{agentId, prompt, maxTokens}`
- A fake policy allows up to `100000` units per `agentId-Agent-001`
- The server simulates usage and returns a mock receipt

## Real Mode (optional)

To enable real mode, set these env vars:

- `QUANTA_RPC_URL`
- `QUANTA_PRIVATE_KEY`
- `QUANTA_CONTRACT_TOKEN`
- `QUANTA_CONTRACT_REGISTRY`
- `QUANTA_CONTRACT_CHANNEL`
- `QUANTA_CONTRACT_MARKETPLACE`

This example documents where registry checks and spend recording would happen. Full real integration may require additional SDK work.

## Requirements

- Node.js >= 18

## How to run mock mode

```bash
cd examples/api-metering-server
npm install
npm run build
npm start
```

Dev mode:

```bash
npm run dev
```

## Request Examples

Health:

```bash
curl http://localhost:3000/health
```

Mock generate:

```bash
curl -X POST http://localhost:3000/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"agentId":"agent-Agent-001","prompt":"Hello","maxTokens":64}'
```

Real-mode preview endpoint structure:

```bash
curl -X POST http://localhost:3000/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"agentId":"0x...","prompt":"Hello","maxTokens":64}'
```

## Security notes

- Do not run real mode with mainnet funds yet.
- Use testnet only until contracts are audited for production.
- Never commit `.env` files.
- Restrict CORS and add authentication before public deployment.

## License

MIT
