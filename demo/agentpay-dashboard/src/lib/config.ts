export interface DemoConfig {
  chainId: number;
  chainName: string;
  rpcUrl: string;
  agentRegistryAddress: string;
  paymentChannelAddress: string;
  marketplaceAddress: string;
  qtaTokenAddress: string;
  demoMode: boolean;
}

function cleanAddress(value: string | undefined, fallback: string): string {
  const trimmed = (value || '').trim();
  if (!trimmed) return fallback;
  return trimmed;
}

export function loadConfig(): DemoConfig {
  const chainId = Number(import.meta.env.VITE_CHAIN_ID || '84532');
  const chainName = String(import.meta.env.VITE_CHAIN_NAME || 'Base Sepolia');
  const rpcUrl = String(import.meta.env.VITE_RPC_URL || 'https://sepolia.base.org');
  const agentRegistryAddress = cleanAddress(import.meta.env.VITE_AGENT_REGISTRY_ADDRESS, '0x');
  const paymentChannelAddress = cleanAddress(import.meta.env.VITE_PAYMENT_CHANNEL_ADDRESS, '0x');
  const marketplaceAddress = cleanAddress(import.meta.env.VITE_MARKETPLACE_ADDRESS, '0x');
  const qtaTokenAddress = cleanAddress(import.meta.env.VITE_QTA_TOKEN_ADDRESS, '0x');
  const demoMode = String(import.meta.env.VITE_DEMO_MODE || 'mock').toLowerCase() !== 'real';

  return {
    chainId,
    chainName,
    rpcUrl,
    agentRegistryAddress,
    paymentChannelAddress,
    marketplaceAddress,
    qtaTokenAddress,
    demoMode,
  };
}
