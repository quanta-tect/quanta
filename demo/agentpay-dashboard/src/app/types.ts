export type Mode = 'mock' | 'sepolia';

export interface Agent {
  agentId: string;
  owner: string;
  metadataURI: string;
  maxPerTx: bigint;
  maxPerDay: bigint;
  active: boolean;
  registeredAt: number;
}

export interface Policy {
  maxPerTx: bigint;
  maxPerDay: bigint;
  active: boolean;
}

export interface Receipt {
  id: string;
  timestamp: number;
  agentId: string;
  amount: bigint;
  service: string;
  status: 'success' | 'fail';
  reason?: string;
  txHash?: string;
}

export interface Contracts {
  registry: string;
  channel: string;
  marketplace: string;
  token: string;
}
