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
    token: "0x627088b570F6873c0D8f05607b12682b4D2f5fC8",
    registry: "0x4d25dD8bB2ccb67bdBd3Af4e7ff0016b919cFd2A",
    channel: "0xdA1C842Beb6872Cf3322447b70787773c1a64D32",
    marketplace: "0x5c4d27207D6b22AE7Ea91C1097f50c168d2a59b5",
  },
  base: {
    token: "0x0000000000000000000000000000000000000000",
    registry: "0x0000000000000000000000000000000000000000",
    channel: "0x0000000000000000000000000000000000000000",
    marketplace: "0x0000000000000000000000000000000000000000",
  },
};
