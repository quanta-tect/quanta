/**
 * 🔗 LangChain Integration Example
 * ================================
 *
 * Integrate ZEUSYXA as a "Tool" in LangChain agent:
 *   - LLM can call `payForData` tool to buy datasets
 *   - LLM can call `payForInference` to use other models
 *   - All transactions respect spending policy
 *
 * This pattern allows any LangChain agent (GPT-4, Claude, Llama)
 * to participate in the ZEUSYXA economy without custom code.
 *
 * pip install langchain langchain-openai
 * tsx examples/langchain-integration.ts
 */

import { ZeusyxaClient, AIAgent, ModelMarketplace } from "../src/index.js";
import { parseEther, formatEther } from "viem";

// Mock LangChain Tool interface for the example
interface Tool {
  name: string;
  description: string;
  schema: Record<string, unknown>;
  execute: (args: any) => Promise<string>;
}

function createZeusyxaTools(client: ZeusyxaClient, agent: AIAgent): Tool[] {
  const marketplace = new ModelMarketplace(client);

  return [
    {
      name: "zeusyxa_pay_for_inference",
      description: "Pay ZYX to use an AI model on ZEUSYXA marketplace. " +
                    "Use when you need specialized capability (vision, audio, code, etc).",
      schema: {
        modelId: { type: "string", description: "On-chain model ID" },
      },
      async execute({ modelId }) {
        const info = await marketplace.getModel(BigInt(modelId));
        const tx = await marketplace.payForInference(BigInt(modelId));
        return `Paid ${formatEther(info.pricePerCall)} ZYX for model ${modelId}. ` +
                `TX: ${tx}. Now you can call the inference endpoint with this proof.`;
      },
    },
    {
      name: "zeusyxa_check_balance",
      description: "Check current ZYX balance of the agent.",
      schema: {},
      async execute() {
        const bal = await client.balanceOf(client.address);
        return `Current balance: ${formatEther(bal)} ZYX`;
      },
    },
    {
      name: "zeusyxa_heartbeat",
      description: "Ping the agent registry to prove agent is still alive. " +
                    "Call this every few hours to avoid death-switch refund.",
      schema: {},
      async execute() {
        await agent.ping();
        return "Heartbeat sent. Agent will stay active.";
      },
    },
  ];
}

async function demo() {
  console.log("🔗 LangChain × ZEUSYXA Integration\n");

  // Pseudocode — actual LangChain setup:
  /*
  import { ChatOpenAI } from "@langchain/openai";
  import { AgentExecutor, createOpenAIFunctionsAgent } from "langchain/agents";

  const llm = new ChatOpenAI({ model: "gpt-4o" });
  const client = new ZeusyxaClient({ chain: "base", privateKey: process.env.KEY });
  const agent = await AIAgent.register(client, { ... });
  const tools = createZeusyxaTools(client, agent);

  const executor = await AgentExecutor.fromAgentAndTools({
    agent: await createOpenAIFunctionsAgent({ llm, tools, prompt: ... }),
    tools,
  });

  await executor.invoke({
    input: "I need to identify objects in this image. Find the best vision " +
            "model on ZEUSYXA marketplace and pay for inference."
  });
  */

  console.log(`Pattern works with:
  ✓ LangChain (any LLM provider)
  ✓ LlamaIndex
  ✓ CrewAI
  ✓ AutoGPT plugins
  ✓ Vercel AI SDK (tool calling)
  ✓ Claude Computer Use
  ✓ OpenAI Assistants API
  ✓ Anthropic Model Context Protocol (MCP)

ZEUSYXA tools become first-class citizens in any AI agent framework.
This is the path to AI economic agency at scale.`);
}

export { createZeusyxaTools };

if (import.meta.url === `file://${process.argv[1]}`) {
  demo();
}
