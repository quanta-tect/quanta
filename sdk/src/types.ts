import type { Address, Hex } from "viem";

export interface SpendingPolicy {
  maxPerTx: bigint;
  maxPerDay: bigint;
  deathSwitchSec: number;
  requireIntent: boolean;
}

export interface AgentConfig {
  name: string;
  metadataURI: string;
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

export const QUANTA_CONTRACTS: Record<string, QuantaContracts> = {
  "base-sepolia": {
    token: "0x312137fb6943F8f89F5eF0f221aA102035a16625",
    registry: "0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB",
    channel: "0xF146e95b97fce1d1800F5F922AE99155711A4314",
    marketplace: "0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49",
  },
  base: {
    token: "0x0000000000000000000000000000000000000000",
    registry: "0x0000000000000000000000000000000000000000",
    channel: "0x0000000000000000000000000000000000000000",
    marketplace: "0x0000000000000000000000000000000000000000",
  },
};
