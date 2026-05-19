import type { Address, Hex } from "viem";
import { keccak256, encodeAbiParameters, parseEther } from "viem";
import type { QuantaClient } from "./client.js";
import type { AgentConfig, SpendingPolicy } from "./types.js";

const REGISTRY_ABI = [
  {
    inputs: [
      { name: "name", type: "string" },
      { name: "wallet", type: "address" },
      { name: "metadataURI", type: "string" },
      {
        name: "policy",
        type: "tuple",
        components: [
          { name: "maxPerTx", type: "uint128" },
          { name: "maxPerDay", type: "uint128" },
          { name: "deathSwitchSec", type: "uint64" },
          { name: "requireIntent", type: "bool" },
        ],
      },
    ],
    name: "registerAgent",
    outputs: [{ type: "bytes32" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "agentId", type: "bytes32" }],
    name: "ping",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "agentId", type: "bytes32" }],
    name: "isAlive",
    outputs: [{ type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
] as const;

/**
 * AIAgent — wraps an on-chain AI agent with spending policy + reputation.
 *
 * Compatible frameworks:
 *  - LangChain: use as Tool
 *  - AutoGPT: use as Plugin
 *  - Vercel AI SDK: use as Function call
 *
 * @example
 *   const agent = await AIAgent.register(client, {
 *     name: "ResearchBot",
 *     metadataURI: "ipfs://bafy.../card.json",
 *     policy: {
 *       maxPerTx: parseEther("0.5"),
 *       maxPerDay: parseEther("10"),
 *       deathSwitchSec: 7 * 86400,
 *       requireIntent: false,
 *     },
 *   });
 *
 *   await agent.ping();  // heartbeat
 *   const alive = await agent.isAlive();
 */
export class AIAgent {
  constructor(
    public readonly client: QuantaClient,
    public readonly agentId: Hex,
    public readonly config: AgentConfig,
  ) {}

  static async register(client: QuantaClient, config: AgentConfig): Promise<AIAgent> {
    const txHash = await client.walletClient.writeContract({
      address: client.contracts.registry,
      abi: REGISTRY_ABI,
      functionName: "registerAgent",
      args: [
        config.name,
        client.address,
        config.metadataURI,
        {
          maxPerTx: config.policy.maxPerTx,
          maxPerDay: config.policy.maxPerDay,
          deathSwitchSec: BigInt(config.policy.deathSwitchSec),
          requireIntent: config.policy.requireIntent,
        } as never,
      ],
      chain: client.walletClient.chain,
      account: client.walletClient.account!,
    });
    await client.publicClient.waitForTransactionReceipt({ hash: txHash });

    // Compute agentId off-chain
    const agentId = keccak256(
      encodeAbiParameters(
        [{ type: "address" }, { type: "string" }],
        [client.address, config.name],
      ),
    );

    return new AIAgent(client, agentId, config);
  }

  async ping(): Promise<Hex> {
    return await this.client.walletClient.writeContract({
      address: this.client.contracts.registry,
      abi: REGISTRY_ABI,
      functionName: "ping",
      args: [this.agentId],
      chain: this.client.walletClient.chain,
      account: this.client.walletClient.account!,
    });
  }

  async isAlive(): Promise<boolean> {
    return (await this.client.publicClient.readContract({
      address: this.client.contracts.registry,
      abi: REGISTRY_ABI,
      functionName: "isAlive",
      args: [this.agentId],
    })) as boolean;
  }

  /** Helper: create default policy for an agent "research assistant" */
  static defaultResearchPolicy(): SpendingPolicy {
    return {
      maxPerTx: parseEther("0.1"),
      maxPerDay: parseEther("2"),
      deathSwitchSec: 7 * 86400,
      requireIntent: false,
    };
  }

  /** Helper: strict policy for "agent with credit card" controlled by someone else */
  static strictPolicy(maxDaily: string): SpendingPolicy {
    return {
      maxPerTx: parseEther("0.01"),
      maxPerDay: parseEther(maxDaily),
      deathSwitchSec: 86400,
      requireIntent: true,
    };
  }
}
