import type { Address, Hex } from "viem";
import { encodeAbiParameters, keccak256, hashMessage } from "viem";
import type { QuantaClient } from "./client.js";
import type { ChannelState } from "./types.js";

const CHANNEL_ABI = [
  {
    inputs: [
      { name: "payee", type: "address" },
      { name: "nonce", type: "uint64" },
      { name: "deposit", type: "uint256" },
    ],
    name: "openChannel",
    outputs: [{ type: "bytes32" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { name: "channelId", type: "bytes32" },
      { name: "amount", type: "uint256" },
      { name: "signature", type: "bytes" },
    ],
    name: "closeChannel",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

/**
 * PaymentChannel — x402-style micropayments off-chain.
 *
 * @example
 *   // Payer side
 *   const channel = await PaymentChannel.open(client, apiProvider, parseEther("1"));
 *   for (let i = 0; i < 1000; i++) {
 *     const ticket = await channel.pay(parseEther("0.0001"));
 *     await sendToProvider(ticket);  // off-chain HTTP
 *   }
 *
 *   // Payee side (when ready to cash out)
 *   await channel.close(bestTicket);  // 1 onchain tx settles all
 */
export class PaymentChannel {
  private spent = 0n;
  private nonce = 0;
  private lastTicket: ChannelState | null = null;

  constructor(
    public readonly client: QuantaClient,
    public readonly state: {
      channelId: Hex;
      payer: Address;
      payee: Address;
      deposit: bigint;
      openNonce: bigint;
    },
  ) {}

  static async open(
    client: QuantaClient,
    payee: Address,
    deposit: bigint,
    nonce?: bigint,
  ): Promise<PaymentChannel> {
    const openNonce = nonce ?? BigInt(Math.floor(Date.now() / 1000));

    // 1. Approve token spend
    await client.approve(client.contracts.channel, deposit);

    // 2. Open channel
    const txHash = await client.walletClient.writeContract({
      address: client.contracts.channel,
      abi: CHANNEL_ABI,
      functionName: "openChannel",
      args: [payee, openNonce, deposit],
      chain: client.walletClient.chain,
      account: client.walletClient.account!,
    });
    await client.publicClient.waitForTransactionReceipt({ hash: txHash });

    const channelId = keccak256(
      encodeAbiParameters(
        [{ type: "address" }, { type: "address" }, { type: "uint64" }],
        [client.address, payee, openNonce],
      ),
    );

    return new PaymentChannel(client, {
      channelId,
      payer: client.address,
      payee,
      deposit,
      openNonce,
    });
  }

  /**
   * Tạo 1 ticket micropayment (off-chain, gần như free).
   * Trả về signed state để gửi for payee.
   */
  async pay(amount: bigint): Promise<ChannelState> {
    if (this.spent + amount > this.state.deposit) {
      throw new Error("Channel exhausted");
    }
    this.spent += amount;
    this.nonce++;

    // Sign {channelId, total spent}
    const msgHash = keccak256(
      encodeAbiParameters(
        [{ type: "bytes32" }, { type: "uint256" }],
        [this.state.channelId, this.spent],
      ),
    );
    const signature = await this.client.walletClient.signMessage({
      message: { raw: msgHash },
      account: this.client.walletClient.account!,
    });

    this.lastTicket = {
      channelId: this.state.channelId,
      payer: this.state.payer,
      payee: this.state.payee,
      deposit: this.state.deposit,
      spent: this.spent,
      nonce: this.nonce,
      signature,
    };
    return this.lastTicket;
  }

  /**
   * Close channel with best ticket (highest amount).
   * Chỉ payee mới gọi was on-chain.
   */
  async close(ticket: ChannelState): Promise<Hex> {
    if (!ticket.signature) throw new Error("No signature");
    return await this.client.walletClient.writeContract({
      address: this.client.contracts.channel,
      abi: CHANNEL_ABI,
      functionName: "closeChannel",
      args: [ticket.channelId, ticket.spent, ticket.signature],
      chain: this.client.walletClient.chain,
      account: this.client.walletClient.account!,
    });
  }

  getLastTicket(): ChannelState | null {
    return this.lastTicket;
  }

  getStats() {
    return {
      deposit: this.state.deposit,
      spent: this.spent,
      remaining: this.state.deposit - this.spent,
      micropayments: this.nonce,
    };
  }
}
