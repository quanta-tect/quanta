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
  vesting?: Address;
  treasury?: Address;
  rewards?: Address;
}

export const QUANTA_CONTRACTS: Record<string, QuantaContracts> = {
  "base-sepolia": {
    token: "0x312137fb6943F8f89F5eF0f221aA102035a16625",
    registry: "0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB",
    channel: "0xF146e95b97fce1d1800F5F922AE99155711A4314",
    marketplace: "0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49",
  },
  "base-sepolia-v2": {
    token: "0x6d089d25035868358952b4d3644f8dAdcCc3295a",
    registry: "0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB",
    channel: "0xF146e95b97fce1d1800F5F922AE99155711A4314",
    marketplace: "0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49",
    vesting: "0xDc1B7aB0e7aE57bbB66ead2d9998bDA9127A291D",
    treasury: "0xb8D10Ba1839597c0c76a60455E231Ac2bA837901",
    rewards: "0x3bED931A6A4F0246d152c2532BB9015850657446",
  },
  base: {
    token: "0x0000000000000000000000000000000000000000",
    registry: "0x0000000000000000000000000000000000000000",
    channel: "0x0000000000000000000000000000000000000000",
    marketplace: "0x0000000000000000000000000000000000000000",
  },
};
