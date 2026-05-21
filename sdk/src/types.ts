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
    token: "0x949E6cd790cAef46Ce905DcA133DDeC8A7875DF5",
    registry: "0x28Fc0f450705a23BA1F27473C94ECF4FAa237514",
    channel: "0x436c1D23118f288f0F4d5533A64521a68bf1435d",
    marketplace: "0x5C97e1feDe8b4E66787E8f3f58F264C2eA12b14f",
  },
  base: {
    token: "0x0000000000000000000000000000000000000000",
    registry: "0x0000000000000000000000000000000000000000",
    channel: "0x0000000000000000000000000000000000000000",
    marketplace: "0x0000000000000000000000000000000000000000",
  },
};
