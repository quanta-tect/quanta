# @zeusyxa/sdk

TypeScript SDK for ZEUSYXA blockchain — built for both human developers and AI agents.

## 📦 Install

```bash
npm install @zeusyxa/sdk viem
```

## 🚀 Quick start

```ts
import { ZeusyxaClient, AIAgent, PaymentChannel } from "@zeusyxa/sdk";
import { parseEther } from "viem";

const client = new ZeusyxaClient({
  chain: "base-sepolia",
  privateKey: process.env.PRIVATE_KEY!,
});

// 1. Register an autonomous AI agent
const agent = await AIAgent.register(client, {
  name: "ResearchBot",
  metadataURI: "ipfs://bafy.../card.json",
  policy: AIAgent.defaultResearchPolicy(),
});

// 2. Open payment channel for micropayments
const channel = await PaymentChannel.open(
  client,
  apiProvider,
  parseEther("1"),
);

// 3. 1000 micropayments off-chain (essentially free)
for (let i = 0; i < 1000; i++) {
  await channel.pay(parseEther("0.0001"));
}

// 4. Settle on-chain (1 tx for all 1000 payments)
await channel.close(channel.getLastTicket()!);
```

## 📚 Examples

| File | What it shows |
|------|---------------|
| `examples/autonomous-agent.ts` | AI agent earns + spends ZYX autonomously |
| `examples/micropayment.ts` | x402-style payment channel |
| `examples/buy-inference.ts` | Buy AI inference from marketplace |
| `examples/langchain-integration.ts` | Plug into LangChain as Tool |

## 🤖 Framework compatibility

ZEUSYXA SDK is designed to be a drop-in for any AI agent framework:

| Framework | Status |
|-----------|--------|
| LangChain | ✅ Tool integration |
| LlamaIndex | ✅ via Tool interface |
| AutoGPT | ✅ Plugin |
| CrewAI | ✅ Custom tool |
| Vercel AI SDK | ✅ Function call |
| Claude Computer Use | ✅ Action handler |
| Anthropic MCP | 🚧 In progress |
| OpenAI Assistants | ✅ Function call |

## 🛡️ Safety features

- **Spending policy** enforced on-chain — even if AI goes rogue, can't exceed budget
- **Death switch** — auto refund if agent stops pinging
- **Intent-based mode** — require human signoff on every payment
- **Reputation tracking** — services see agent's track record

## 📜 License

MIT
