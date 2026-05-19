import type { Address, Hex } from "viem";

export interface SpendingPolicy {
  maxPerTx: bigint;          // wei
  maxPerDay: bigint;
  deathSwitchSec: number;
  requireIntent: boolean;
}

export interface AgentConfig {
  name: string;
  metadataURI: string;       // IPFS URI to model card
  policy: SpendingPolicy;
  initialFunding?: bigint;
}

export interface ChannelState {
  channelId: Hex;
  payer: Address;
  payee: Address;
  deposit: bigint;
  spent: bigint;
  nonce: number;
  signature?: Hex;
}

export interface ModelInfo {
  modelId: bigint;
  creator: Address;
  weightsURI: string;
  metadataURI: string;
  pricePerCall: bigint;
  royaltyBps: number;
  totalCalls: bigint;
  totalEarned: bigint;
}

export interface QuantaContracts {
  token: Address;
  registry: Address;
  channel: Address;
  marketplace: Address;
}

// Default deployments (placeholders — update after deploy)
export const QUANTA_CONTRACTS: Record<string, QuantaContracts> = {
  "base-sepolia": {
    token: "0x0000000000000000000000000000000000000000",
    registry: "0x0000000000000000000000000000000000000000",
    channel: "0x0000000000000000000000000000000000000000",
    marketplace: "0x0000000000000000000000000000000000000000",
  },
  base: {
    token: "0x0000000000000000000000000000000000000000",
    registry: "0x0000000000000000000000000000000000000000",
    channel: "0x0000000000000000000000000000000000000000",
    marketplace: "0x0000000000000000000000000000000000000000",
  },
};
