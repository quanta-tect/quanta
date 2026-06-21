import type { Address, Hex } from "viem";
import type { QuantaClient } from "./client.js";
import type { ModelInfo } from "./types.js";

// v1.2 ABI
const MARKET_ABI = [
  {
    inputs: [
      { name: "pricePerCall", type: "uint256" },
      { name: "royaltyBps", type: "uint256" },
      { name: "metadataURI", type: "string" },
    ],
    name: "registerModel",
    outputs: [{ type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { name: "modelId", type: "uint256" },
      { name: "maxPrice", type: "uint256" },
    ],
    name: "payForInference",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "modelId", type: "uint256" }],
    name: "updatePrice",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "modelId", type: "uint256" }],
    name: "deactivateModel",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "", type: "uint256" }],
    name: "models",
    outputs: [
      { name: "creator", type: "address" },
      { name: "pricePerCall", type: "uint256" },
      { name: "royaltyBps", type: "uint256" },
      { name: "totalCalls", type: "uint256" },
      { name: "totalEarned", type: "uint256" },
      { name: "registeredAt", type: "uint64" },
      { name: "deactivatedAt", type: "uint64" },
      { name: "active", type: "bool" },
      { name: "metadataURI", type: "string" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "nextModelId",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "modelId", type: "uint256" }],
    name: "isModelAvailable",
    outputs: [{ type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class ModelMarketplace {
  constructor(public readonly client: QuantaClient) {}

  async registerModel(opts: {
    pricePerCall: bigint;
    royaltyBps: number;
    metadataURI: string;
  }): Promise<bigint> {
    const txHash = await this.client.walletClient.writeContract({
      address: this.client.contracts.marketplace,
      abi: MARKET_ABI,
      functionName: "registerModel",
      args: [opts.pricePerCall, BigInt(opts.royaltyBps), opts.metadataURI],
      chain: this.client.walletClient.chain,
      account: this.client.walletClient.account!,
    });
    const receipt = await this.client.publicClient.waitForTransactionReceipt({ hash: txHash });

    // Return modelId from event or counter
    const modelId = await this.modelCount() - 1n;
    return modelId;
  }

  async payForInference(modelId: bigint, maxPrice?: bigint): Promise<Hex> {
    const info = await this.getModel(modelId);
    const effectiveMaxPrice = maxPrice ?? info.pricePerCall;
    await this.client.approve(this.client.contracts.marketplace, info.pricePerCall);
    return await this.client.walletClient.writeContract({
      address: this.client.contracts.marketplace,
      abi: MARKET_ABI,
      functionName: "payForInference",
      args: [modelId, effectiveMaxPrice],
      chain: this.client.walletClient.chain,
      account: this.client.walletClient.account!,
    });
  }

  async getModel(modelId: bigint): Promise<ModelInfo> {
    const result = (await this.client.publicClient.readContract({
      address: this.client.contracts.marketplace,
      abi: MARKET_ABI,
      functionName: "models",
      args: [modelId],
    })) as readonly [Address, bigint, bigint, bigint, bigint, bigint, bigint, boolean, string];

    return {
      modelId,
      creator: result[0],
      weightsURI: result[8], // metadataURI in v1.2
      metadataURI: result[8],
      pricePerCall: result[1],
      royaltyBps: Number(result[2]),
      totalCalls: result[3],
      totalEarned: result[4],
    };
  }

  async modelCount(): Promise<bigint> {
    return (await this.client.publicClient.readContract({
      address: this.client.contracts.marketplace,
      abi: MARKET_ABI,
      functionName: "nextModelId",
    })) as bigint;
  }

  async isModelAvailable(modelId: bigint): Promise<boolean> {
    return (await this.client.publicClient.readContract({
      address: this.client.contracts.marketplace,
      abi: MARKET_ABI,
      functionName: "isModelAvailable",
      args: [modelId],
    })) as boolean;
  }
}
