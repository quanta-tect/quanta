# How to Build a TypeScript SDK for Smart Contracts with Viem

**Meta:** Step-by-step guide to building a professional TypeScript SDK for Ethereum smart contracts using viem (not ethers.js). Includes type safety, error handling, and CI/CD.

**Tags:** typescript, ethereum, viem, web3, sdk

---

## Why Viem Over Ethers.js

Ethers.js v6 broke backwards compatibility and has verbose types. Viem is:
- Smaller bundle size (tree-shakeable)
- Better TypeScript support
- Faster (no JSON-RPC overhead)
- Built by the wagmi team

## Project Setup

```bash
mkdir quanta-sdk && cd quanta-sdk
npm init -y
npm install viem
npm install -D typescript @types/node vitest
```

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "declaration": true,
    "outDir": "dist",
    "lib": ["ES2022"]
  },
  "include": ["src"]
}
```

## The SDK Structure

```
src/
├── index.ts          # Main exports
├── client.ts         # Chain configuration
├── contracts.ts      # Contract ABIs + addresses
├── types.ts          # TypeScript interfaces
├── tokens.ts         # ERC-20 interactions
├── channels.ts       # Payment channel logic
├── registry.ts       # Agent registry
├── marketplace.ts    # Model marketplace
└── errors.ts         # Custom error types
```

## Core: Chain Client

```typescript
// src/client.ts
import { createPublicClient, http, type PublicClient } from 'viem';
import { baseSepolia } from 'viem/chains';

export function createQuantaClient(
  rpcUrl?: string
): PublicClient {
  return createPublicClient({
    chain: baseSepolia,
    transport: http(rpcUrl || 'https://sepolia.base.org'),
  });
}
```

## Types

```typescript
// src/types.ts
export interface Agent {
  owner: `0x${string}`;
  name: string;
  maxTxAmount: bigint;
  maxDailySpend: bigint;
  reputation: bigint;
  active: boolean;
}

export interface Channel {
  sender: `0x${string}`;
  receiver: `0x${string}`;
  amount: bigint;
  nonce: bigint;
  open: boolean;
}

export interface Model {
  creator: `0x${string}`;
  name: string;
  pricePerCall: bigint;
  totalCalls: bigint;
  active: boolean;
}

export interface QuantaConfig {
  chain: 'base-sepolia' | 'base';
  privateKey?: string;
  rpcUrl?: string;
}
```

## Contract Interactions

```typescript
// src/tokens.ts
import { 
  type PublicClient, 
  type WalletClient,
  parseAbi, 
  parseUnits 
} from 'viem';

const ERC20_ABI = parseAbi([
  'function balanceOf(address) view returns (uint256)',
  'function transfer(address,uint256) returns (bool)',
  'function approve(address,uint256) returns (bool)',
  'function allowance(address,address) view returns (uint256)',
]);

export class TokenClient {
  private public: PublicClient;
  private wallet?: WalletClient;
  private address: `0x${string}`;
  
  constructor(
    publicClient: PublicClient,
    walletClient?: WalletClient,
    tokenAddress?: `0x${string}`
  ) {
    this.public = publicClient;
    this.wallet = walletClient;
    this.address = tokenAddress || 
      '0x312137fb6943F8f89F5eF0f221aA102035a16625';
  }
  
  async balanceOf(
    account: `0x${string}`
  ): Promise<bigint> {
    return this.public.readContract({
      address: this.address,
      abi: ERC20_ABI,
      functionName: 'balanceOf',
      args: [account],
    });
  }
  
  async transfer(
    to: `0x${string}`,
    amount: string // Human-readable: "100.5"
  ): Promise<`0x${string}`> {
    if (!this.wallet) throw new Error('No wallet client');
    
    const [account] = await this.wallet.getAddresses();
    const value = parseUnits(amount, 18);
    
    const { request } = await this.public.simulateContract({
      address: this.address,
      abi: ERC20_ABI,
      functionName: 'transfer',
      args: [to, value],
      account,
    });
    
    return this.wallet.writeContract(request);
  }
}
```

## Payment Channel Client

```typescript
// src/channels.ts
import { parseAbi, encodeAbiParameters, keccak256 } from 'viem';

const CHANNEL_ABI = parseAbi([
  'function openChannel(address,uint256) returns (bytes32)',
  'function closeChannel(bytes32,uint256,bytes)',
  'function channels(bytes32) view returns (tuple(address,address,uint256,uint256,bool))',
]);

export class ChannelClient {
  private public: PublicClient;
  private wallet?: WalletClient;
  private address: `0x${string}`;
  
  async openChannel(
    receiver: `0x${string}`,
    amount: bigint
  ): Promise<`0x${string}`> {
    if (!this.wallet) throw new Error('No wallet');
    
    const [account] = await this.wallet.getAddresses();
    
    // First approve
    // ... approve token spending
    
    const { request } = await this.public.simulateContract({
      address: this.address,
      abi: CHANNEL_ABI,
      functionName: 'openChannel',
      args: [receiver, amount],
      account,
    });
    
    const txHash = await this.wallet.writeContract(request);
    
    // Wait for receipt to get channel ID
    const receipt = await this.public.waitForTransactionReceipt({
      hash: txHash,
    });
    
    // Parse channel ID from logs
    return this.parseChannelId(receipt);
  }
  
  async getChannel(
    channelId: `0x${string}`
  ) {
    return this.public.readContract({
      address: this.address,
      abi: CHANNEL_ABI,
      functionName: 'channels',
      args: [channelId],
    });
  }
}
```

## Main SDK Entry Point

```typescript
// src/index.ts
import { type QuantaConfig, type Agent, type Channel } from './types';
import { createQuantaClient } from './client';
import { TokenClient } from './tokens';
import { ChannelClient } from './channels';
import { RegistryClient } from './registry';

export class QuantaSDK {
  public token: TokenClient;
  public channel: ChannelClient;
  public registry: RegistryClient;
  
  constructor(config: QuantaConfig) {
    const publicClient = createQuantaClient(config.rpcUrl);
    
    this.token = new TokenClient(publicClient);
    this.channel = new ChannelClient(publicClient);
    this.registry = new RegistryClient(publicClient);
  }
  
  async getBalance(
    address: `0x${string}`
  ): Promise<string> {
    const balance = await this.token.balanceOf(address);
    return formatEther(balance);
  }
}

// Re-exports
export { QuantaSDK } from './index';
export type { Agent, Channel, Model } from './types';
```

## Testing

```typescript
// tests/sdk.test.ts
import { describe, it, expect } from 'vitest';
import { QuantaSDK } from '../src';

describe('QuantaSDK', () => {
  const sdk = new QuantaSDK({
    chain: 'base-sepolia',
    rpcUrl: 'https://sepolia.base.org',
  });
  
  it('reads token balance', async () => {
    const balance = await sdk.getBalance(
      '0x312137fb6943F8f89F5eF0f221aA102035a16625'
    );
    expect(typeof balance).toBe('string');
  });
  
  it('reads agent info', async () => {
    const agent = await sdk.registry.getAgent(
      '0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB'
    );
    expect(agent).toBeDefined();
  });
});
```

## Publishing to npm

```json
// package.json
{
  "name": "@quanta/sdk",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "types": "./dist/index.d.ts"
    }
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsc",
    "test": "vitest",
    "prepublishOnly": "npm run build"
  }
}
```

```bash
npm publish --access public
```

## Conclusion

Building a TypeScript SDK with viem gives you:
- Full type safety
- Tree-shakeable bundles
- Better DX than ethers.js
- Native BigInt support

QUANTA SDK is open-source. Try it today:

```bash
npm install @quanta/sdk
```

---

*GitHub: [quanta-tect/quanta](https://github.com/quanta-tect/quanta)*
