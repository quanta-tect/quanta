export { AIAgentRegistryABI, ZeusyxaTokenABI } from './abi';

const BASE_SEPOLIA_EXPLORER = 'https://sepolia.basescan.org/tx';

export function baseExplorerUrl(hash: string) {
  return `${BASE_SEPOLIA_EXPLORER}/${hash}`;
}

export interface BaseReceipt {
  id: string;
  timestamp: string;
  action: string;
  status: 'PENDING' | 'SUCCESS' | 'FAILED';
  txHash?: string;
  explorerUrl?: string;
  reason?: string;
  error?: string;
  detail?: string;
}

export function createBaseReceipt(action: string): BaseReceipt {
  return {
    id: `real-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    timestamp: new Date().toISOString(),
    action,
    status: 'PENDING',
  };
}

export function weiFromZyx(zyx: string): bigint {
  const n = parseFloat(zyx);
  if (!Number.isFinite(n) || n <= 0) return 0n;
  return BigInt(Math.floor(n * 1e18));
}

export function bytes32AgentId(owner: string, nonce: string): `0x${string}` {
  const payload = `${owner}-${nonce}`;
  const hex = Array.from(new TextEncoder().encode(payload))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  return `0x${hex.padEnd(64, '0')}` as `0x${string}`;
}
