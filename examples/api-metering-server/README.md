# Quanta AgentPay API Metering Server Example

This example shows how an API or model provider can use Quanta to meter AI agent usage.

It demonstrates the core AgentPay idea:

- identify an agent
- check a spending policy
- simulate API usage
- return a receipt
- document where real Base Sepolia settlement should happen

## What it demonstrates

- A simple Express server for AI-agent API access.
- Mock-mode metering with fake agent IDs and spending limits.
- HTTP error handling for invalid requests, unauthorized agents, and spend limits.
- A safe path to real-mode integration on Base Sepolia.

## Requirements

- Node.js 18 or newer
- npm

## Install

```bash
cd examples/api-metering-server
npm install
```

## Run mock mode

Mock mode is the default when QUANTA_RPC_URL is empty.

```bash
npm run build
npm start
```

Development mode:

```bash
npm run dev
```

## Endpoints

Health check:

```bash
curl http://localhost:3000/health
```

Generate request:

```bash
curl -X POST http://localhost:3000/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"agentId":"agent-Agent-001","prompt":"Hello","maxTokens":64}'
```

Expected mock response:

```json
{
  "agentId": "agent-Agent-001",
  "prompt": "Hello",
  "maxTokens": 64,
  "usageSimulated": 64,
  "costSimulated": "0.00001",
  "policyMaxAllowance": "100000",
  "allowed": true,
  "note": "Mock receipt only. No on-chain settlement."
}
```

## Mock policy

The mock policy allows this agent ID:

```text
agent-Agent-001
```

Requests with unknown agent IDs return 403.
Requests above the mock spend limit return 402.
Malformed requests return 400.

## Real mode

Real mode is optional and is not fully implemented in this example.

To preview real-mode configuration, copy the env template:

```bash
cp .env.example .env
```

Then set:

```text
QUANTA_RPC_URL=
QUANTA_PRIVATE_KEY=
QUANTA_CONTRACT_TOKEN=
QUANTA_CONTRACT_REGISTRY=
QUANTA_CONTRACT_CHANNEL=
QUANTA_CONTRACT_MARKETPLACE=
```

A production real-mode API server should:

1. Verify the agent exists in AIAgentRegistry.
2. Check the spending policy before serving the request.
3. Execute the upstream API or model call.
4. Record spend through Quanta contracts.
5. Return a transaction receipt or settlement reference.

## Security notes

- Do not use real mode with mainnet funds.
- Do not commit .env files.
- Do not commit private keys or RPC secrets.
- Restrict CORS before public deployment.
- Add authentication and rate limiting before production use.

## License

MIT
