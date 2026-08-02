import { createPublicClient, http, type Address, type Hex } from 'viem';
import { baseSepolia } from 'viem/chains';
import type { Contracts, Agent } from '../app/types.js';

const REGISTRY_ABI = [
  {
    inputs: [{ name: 'agentId', type: 'bytes32' }],
    name: 'agents',
    outputs: [
      { name: 'owner', type: 'address' },
      { name: 'reputation', type: 'uint256' },
      { name: 'metadataURI', type: 'string' },
      { name: 'registeredAt', type: 'uint64' },
      { name: 'active', type: 'bool' },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { name: 'agentId', type: 'bytes32' },
      { name: 'metadataURI', type: 'string' },
      { name: 'maxPerTx', type: 'uint256' },
      { name: 'maxPerDay', type: 'uint256' },
    ],
    name: 'registerAgent',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'agentId', type: 'bytes32' }],
    name: 'deactivateAgent',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'agentId', type: 'bytes32' },
      { name: 'maxPerTx', type: 'uint256' },
      { name: 'maxPerDay', type: 'uint256' },
    ],
    name: 'updatePolicy',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'agentId', type: 'bytes32' }],
    name: 'getRolling24hSpend',
    outputs: [{ type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'spender', type: 'address' }, { name: 'authorized', type: 'bool' }],
    name: 'setAuthorizedSpender',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'agentId', type: 'bytes32' }, { name: 'amount', type: 'uint256' }],
    name: 'checkAndRecordSpend',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
] as const;

export class RealRegistry {
  private publicClient;
  private contracts: Contracts;

  constructor(rpcUrl: string, contracts: Contracts) {
    this.publicClient = createPublicClient({ chain: baseSepolia, transport: http(rpcUrl) });
    this.contracts = contracts;
  }

  async getAgent(_agentId: Hex): Promise<Agent | null> {
    const data = (await this.publicClient.readContract({
      address: this.contracts.registry as Address,
      abi: REGISTRY_ABI,
      functionName: 'agents',
      args: [_agentId],
    })) as [Address, bigint, string, bigint, boolean];
    const [owner, , metadataURI, registeredAt, active] = data;
    if (registeredAt === 0n) return null;
    return { agentId: _agentId, owner, metadataURI, maxPerTx: 0n, maxPerDay: 0n, active, registeredAt: Number(registeredAt) };
  }

  async registerAgent(_agentId: Hex, _metadataURI: string, _maxPerTx: bigint, _maxPerDay: bigint): Promise<Hex> {
    throw new Error('Write operations require walletClient configured in demo');
  }

  async authorizeSpender(_spender: Address, _authorized: boolean): Promise<Hex> {
    throw new Error('Write operations require walletClient configured in demo');
  }

  async simulatePayment(_agentId: Hex, _amount: bigint): Promise<{ ok: boolean; reason?: string; txHash?: Hex }> {
    return { ok: false, reason: 'Write operations require walletClient configured in demo' };
  }
}
