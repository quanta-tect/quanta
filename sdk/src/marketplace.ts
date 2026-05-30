import type { Address, Hex } from "viem";
import type { QuantaClient } from "./client.js";
import type { ModelInfo } from "./types.js";

const MARKET_ABI = [
  {
    inputs: [
      { name: "weightsURI", type: "string" },
      { name: "metadataURI", type: "string" },
      { name: "pricePerCall", type: "uint256" },
      { name: "royaltyBps", type: "uint16" },
    ],
    name: "registerModel",
    outputs: [{ type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "modelId", type: "uint256" }, { name: "maxPrice", type: "uint256" }],
    name: "payForInference",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "", type: "uint256" }],
    name: "models",
    outputs: [
      { name: "creator", type: "address" },
      { name: "weightsURI", type: "string" },
      { name: "metadataURI", type: "string" },
      { name: "pricePerCall", type: "uint256" },
      { name: "royaltyBps", type: "uint16" },
      { name: "totalCalls", type: "uint64" },
      { name: "totalEarned", type: "uint256" },
      { name: "deactivatedAt", type: "uint64" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "modelCount",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class ModelMarketplace {
  constructor(public readonly client: QuantaClient) {}

  async registerModel(opts: {
    weightsURI: string;
    metadataURI: string;
    pricePerCall: bigint;
    royaltyBps: number;
  }): Promise<bigint> {
    const txHash = await this.client.walletClient.writeContract({
      address: this.client.contracts.marketplace,
      abi: MARKET_ABI,
      functionName: "registerModel",
      args: [opts.weightsURI, opts.metadataURI, opts.pricePerCall, opts.royaltyBps],
      chain: this.client.walletClient.chain,
      account: this.client.walletClient.account!,
    });
    const receipt = await this.client.publicClient.waitForTransactionReceipt({ hash: txHash });
    return BigInt(receipt.logs.length);
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
    })) as readonly [Address, string, string, bigint, number, bigint, bigint, bigint];

    return {
      modelId,
      creator: result[0],
      weightsURI: result[1],
      metadataURI: result[2],
      pricePerCall: result[3],
      royaltyBps: result[4],
      totalCalls: result[5],
      totalEarned: result[6],
    };
  }

  async modelCount(): Promise<bigint> {
    return (await this.client.publicClient.readContract({
      address: this.client.contracts.marketplace,
      abi: MARKET_ABI,
      functionName: "modelCount",
    })) as bigint;
  }
}
