import {
  createPublicClient,
  createWalletClient,
  http,
  type Address,
  type PublicClient,
  type WalletClient,
  type Hex,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { base, baseSepolia } from "viem/chains";
import type { QuantaContracts } from "./types.js";
import { QUANTA_CONTRACTS } from "./types.js";

const CHAINS = { base, "base-sepolia": baseSepolia };

export type ChainName = keyof typeof CHAINS;

export class QuantaClient {
  public readonly chainName: ChainName;
  public readonly contracts: QuantaContracts;
  public readonly publicClient: PublicClient;
  public readonly walletClient: WalletClient;
  public readonly address: Address;

  constructor(opts: {
    chain: ChainName;
    privateKey: Hex;
    rpcUrl?: string;
    contracts?: Partial<QuantaContracts>;
  }) {
    this.chainName = opts.chain;
    const chain = CHAINS[opts.chain];
    const account = privateKeyToAccount(opts.privateKey);
    this.address = account.address;

    this.publicClient = createPublicClient({
      chain,
      transport: http(opts.rpcUrl),
    });

    this.walletClient = createWalletClient({
      account,
      chain,
      transport: http(opts.rpcUrl),
    });

    this.contracts = {
      ...QUANTA_CONTRACTS[opts.chain],
      ...opts.contracts,
    };

    // Guard: warn if using mainnet with placeholder zero addresses
    const zeroAddr = "0x0000000000000000000000000000000000000000";
    if (
      this.contracts.token === zeroAddr ||
      this.contracts.registry === zeroAddr
    ) {
      console.warn(
        `[QUANTA] Chain "${opts.chain}" has placeholder addresses. Contracts not deployed to mainnet yet.`
      );
    }
  }

  async balanceOf(address: Address): Promise<bigint> {
    return (await this.publicClient.readContract({
      address: this.contracts.token,
      abi: ERC20_ABI,
      functionName: "balanceOf",
      args: [address],
    })) as bigint;
  }

  async totalSupply(): Promise<bigint> {
    return (await this.publicClient.readContract({
      address: this.contracts.token,
      abi: ERC20_ABI,
      functionName: "totalSupply",
    })) as bigint;
  }

  async totalBurned(): Promise<bigint> {
    return (await this.publicClient.readContract({
      address: this.contracts.token,
      abi: [{
        inputs: [],
        name: "totalBurned",
        outputs: [{ type: "uint256" }],
        stateMutability: "view",
        type: "function",
      }],
      functionName: "totalBurned",
    })) as bigint;
  }

  async transfer(to: Address, amount: bigint): Promise<Hex> {
    return await this.walletClient.writeContract({
      address: this.contracts.token,
      abi: ERC20_ABI,
      functionName: "transfer",
      args: [to, amount],
      chain: this.walletClient.chain,
      account: this.walletClient.account!,
    });
  }

  async approve(spender: Address, amount: bigint): Promise<Hex> {
    return await this.walletClient.writeContract({
      address: this.contracts.token,
      abi: ERC20_ABI,
      functionName: "approve",
      args: [spender, amount],
      chain: this.walletClient.chain,
      account: this.walletClient.account!,
    });
  }
}

const ERC20_ABI = [
  {
    inputs: [{ name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [{ type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "to", type: "address" }, { name: "amount", type: "uint256" }],
    name: "transfer",
    outputs: [{ type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }],
    name: "approve",
    outputs: [{ type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;
