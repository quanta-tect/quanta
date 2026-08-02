/**
 * @quanta/sdk — TypeScript client for QUANTA blockchain
 *
 * Enables both developers (humans) and AI agents to interact with QUANTA:
 *   - Create wallets (EVM or quantum-safe L1)
 *   - Register AI agents with spending policies
 *   - Open payment channels for micropayments
 *   - Buy/sell AI inference via marketplace
 *   - Stake and governance
 *
 * Compatible: LangChain, AutoGPT, CrewAI, Claude Computer Use, Vercel AI SDK
 */

export { QuantaClient } from "./client.js";
export { AIAgent } from "./agent.js";
export { PaymentChannel } from "./channel.js";
export { ModelMarketplace } from "./marketplace.js";
export type {
  SpendingPolicy,
  AgentConfig,
  ChannelState,
  ModelInfo,
} from "./types.js";
