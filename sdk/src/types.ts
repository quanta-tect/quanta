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
    token: "0x4e2B5dE8d3fE3a6C84D34FFf5E673f47010eEc9e",
    registry: "0x9D6d634D4C4D7fF1b920e980793f07c87CD45908",
    channel: "0xE68dad3095B93476AaeB718E0A4ed3CC5B342272",
    marketplace: "0xd545F870Dc1d62E7bF6681CC0984e526a74b6785",
  },
  base: {
    token: "0x0000000000000000000000000000000000000000",
    registry: "0x0000000000000000000000000000000000000000",
    channel: "0x0000000000000000000000000000000000000000",
    marketplace: "0x0000000000000000000000000000000000000000",
  },
};
