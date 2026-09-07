import 'dotenv/config';
/**
 * 💸 ZEUSYXA Micropayment Channel Demo
 * ==================================
 * Opens an x402-style state channel, makes a series of off-chain signed
 * micropayments (no per-call on-chain tx), then settles on-chain once.
 *
 * Run: tsx examples/micropayment.ts
 * (Requires PRIVATE_KEY in .env — NEVER use a default, see SECURITY.md)
 */

import { QuantaClient, PaymentChannel } from "../src/index.js";
import { parseEther, formatEther, type Address } from "viem";

async function main() {
  console.log("╔══════════════════════════════════════════════════════════╗");
  console.log("║  💸 ZEUSYXA Micropayment Channel Demo                     ║");
  console.log("╚══════════════════════════════════════════════════════════╝");

  if (!process.env.PRIVATE_KEY) {
    throw new Error("PRIVATE_KEY env var required. See SECURITY.md.");
  }
  const privateKey = process.env.PRIVATE_KEY as `0x${string}`;

  const client = new QuantaClient({ chain: "base-sepolia", privateKey });
  console.log(`👤 Payer: ${client.address}`);

  const provider = ("0x" + "f".repeat(40)) as Address;
  const deposit = parseEther("1");

  console.log("\n📡 Opening channel...");
  const channel = await PaymentChannel.open(client, provider, deposit);
  console.log(`✓ Channel: ${channel.state.channelId.slice(0, 18)}…`);
  console.log(`  Deposit: ${formatEther(deposit)} ZYX`);

  console.log("\n⚡ Streaming 20 off-chain micropayments...");
  for (let i = 0; i < 20; i++) {
    const ticket = await channel.pay(parseEther("0.01"));
    if (i % 5 === 0) {
      console.log(`  • #${i + 1} signed ticket, total ${formatEther(ticket.spent)} ZYX`);
    }
  }

  const stats = channel.getStats();
  console.log("\n📊 Channel stats:");
  console.log(`  Micropayments:  ${stats.micropayments}`);
  console.log(`  Spent:          ${formatEther(stats.spent)} ZYX`);
  console.log(`  Remaining:      ${formatEther(stats.remaining)} ZYX`);
  console.log(`  On-chain txs:   2 (open + close) instead of ${stats.micropayments}`);

  console.log("\n💸 Settling on-chain (provider closes with last signed ticket)...");
  const lastTicket = channel.getLastTicket();
  if (!lastTicket) throw new Error("No signed ticket to settle");
  await channel.close(lastTicket);
  console.log("✓ Settled. Provider received the signed amount, rest refunded.");
}

main().catch((e) => {
  console.error("Demo error:", e);
  console.log("\n⚠️  Requires deployed contracts + RPC + funded wallet (Base Sepolia).");
  process.exit(1);
});
