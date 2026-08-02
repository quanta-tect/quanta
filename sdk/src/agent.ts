import type { Address, Hex } from "viem";
import { keccak256, encodeAbiParameters, parseEther } from "viem";
import type { QuantaClient } from "./client.js";
import type { AgentConfig, SpendingPolicy } from "./types.js";

// v1.2 ABI: registerAgent(bytes32 agentId, string metadataURI, uint256 maxPerTx, uint256 maxPerDay)
const REGISTRY_ABI = [
  {
    inputs: [
      { name: "agentId", type: "bytes32" },
      { name: "metadataURI", type: "string" },
      { name: "maxPerTx", type: "uint256" },
      { name: "maxPerDay", type: "uint256" },
    ],
    name: "registerAgent",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "agentId", type: "bytes32" }],
    name: "deactivateAgent",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { name: "agentId", type: "bytes32" },
      { name: "maxPerTx", type: "uint256" },
      { name: "maxPerDay", type: "uint256" },
    ],
    name: "updatePolicy",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "agentId", type: "bytes32" }],
    name: "getRolling24hSpend",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "", type: "bytes32" }],
    name: "agents",
    outputs: [
      { name: "owner", type: "address" },
      { name: "reputation", type: "uint256" },
      { name: "metadataURI", type: "string" },
      { name: "registeredAt", type: "uint64" },
      { name: "active", type: "bool" },
    ],
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
 */
export class AIAgent {
  constructor(
    public readonly client: QuantaClient,
    public readonly agentId: Hex,
    public readonly config: AgentConfig,
  ) {}

  static async register(client: QuantaClient, config: AgentConfig): Promise<AIAgent> {
    // v1.2: agentId = keccak256(abi.encode(owner, name))
    const agentId = keccak256(
      encodeAbiParameters(
        [{ type: "address" }, { type: "string" }],
        [client.address, config.name],
      ),
    );

    const txHash = await client.walletClient.writeContract({
      address: client.contracts.registry,
      abi: REGISTRY_ABI,
      functionName: "registerAgent",
      args: [
        agentId,
        config.metadataURI,
        config.policy.maxPerTx,
        config.policy.maxPerDay,
      ],
      chain: client.walletClient.chain,
      account: client.walletClient.account!,
    });
    await client.publicClient.waitForTransactionReceipt({ hash: txHash });

    return new AIAgent(client, agentId, config);
  }

  async deactivate(): Promise<Hex> {
    return await this.client.walletClient.writeContract({
      address: this.client.contracts.registry,
      abi: REGISTRY_ABI,
      functionName: "deactivateAgent",
      args: [this.agentId],
      chain: this.client.walletClient.chain,
      account: this.client.walletClient.account!,
    });
  }

  async updatePolicy(maxPerTx: bigint, maxPerDay: bigint): Promise<Hex> {
    return await this.client.walletClient.writeContract({
      address: this.client.contracts.registry,
      abi: REGISTRY_ABI,
      functionName: "updatePolicy",
      args: [this.agentId, maxPerTx, maxPerDay],
      chain: this.client.walletClient.chain,
      account: this.client.walletClient.account!,
    });
  }

  async getRolling24hSpend(): Promise<bigint> {
    return (await this.client.publicClient.readContract({
      address: this.client.contracts.registry,
      abi: REGISTRY_ABI,
      functionName: "getRolling24hSpend",
      args: [this.agentId],
    })) as bigint;
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
