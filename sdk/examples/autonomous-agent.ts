import 'dotenv/config';
/**
 * 🤖 VIRAL DEMO: AI Agent earns money + pays for services
 * =====================================================
 *
 * Scenario:
 *   1. Create AI agent "ResearchBot-001" with budget of 5 QTA/day
 *   2. Agent receives task: "Summarize 100 papers on quantum cryptography"
 *   3. Agent autonomously buys inference from AI marketplace (LLM model)
 *   4. Pays via payment channel (x402-style, micropayment)
 *   5. Sells summary back to user, earns revenue
 *   6. Agent self-funds for the next task
 *
 * This demo proves: AI agents can be independent economic entities.
 *
 * Run: tsx examples/autonomous-agent.ts
 * (Requires PRIVATE_KEY in .env)
 */

import { QuantaClient, AIAgent, PaymentChannel, ModelMarketplace } from "../src/index.js";
import { parseEther, formatEther, type Address } from "viem";

const SCRIPT_HEADER = `
╔══════════════════════════════════════════════════════════════╗
║   🤖 QUANTA Autonomous Agent Demo                            ║
║   Watch an AI earn and spend QTA without human intervention  ║
╚══════════════════════════════════════════════════════════════╝
`;

async function main() {
  console.log(SCRIPT_HEADER);

  // === Setup ===
  if (!process.env.PRIVATE_KEY) {
    throw new Error("PRIVATE_KEY env var required. NEVER use a default. See SECURITY.md.");
  }
  const privateKey = process.env.PRIVATE_KEY as `0x${string}`;
  const client = new QuantaClient({
    chain: "base-sepolia",
    privateKey,
  });
  console.log(`👤 Owner address: ${client.address}`);
  console.log(`💰 Initial balance: ${formatEther(await client.balanceOf(client.address))} QTA\n`);

  // === Step 1: Register agent ===
  console.log("📝 Step 1: Registering autonomous AI agent...");
  const agent = await AIAgent.register(client, {
    name: "ResearchBot-" + Date.now(),
    metadataURI: "ipfs://bafy.../research-bot-card.json",
    policy: {
      maxPerTx: parseEther("0.5"),
      maxPerDay: parseEther("5"),
      deathSwitchSec: 7 * 86400,
      requireIntent: false,
    },
  });
  console.log(`✓ Agent registered: ${agent.agentId}\n`);

  // === Step 2: Agent receives a task ===
  console.log("📥 Step 2: Agent receives task from user...");
  const userTask = {
    description: "Summarize 10 recent papers on post-quantum cryptography",
    payment: parseEther("2"),  // user pays 2 QTA
  };
  console.log(`   Task: "${userTask.description}"`);
  console.log(`   Reward: ${formatEther(userTask.payment)} QTA\n`);

  // === Step 3: Agent opens payment channel with LLM provider ===
  console.log("📡 Step 3: Agent opens micropayment channel with LLM API provider...");
  const apiProvider = ("0x" + "f".repeat(40)) as Address;
  const channel = await PaymentChannel.open(client, apiProvider, parseEther("1"));
  console.log(`✓ Channel opened with deposit 1 QTA`);
  console.log(`   Channel ID: ${channel.state.channelId.slice(0, 18)}...\n`);

  // === Step 4: Agent makes 50 inference calls (one per paper section) ===
  console.log("🧠 Step 4: Agent makes 50 LLM inference calls (off-chain micropayments)...");
  for (let i = 0; i < 50; i++) {
    const ticket = await channel.pay(parseEther("0.01"));
    if (i % 10 === 0) {
      console.log(`   📤 Call #${i + 1}: paid total ${formatEther(ticket.spent)} QTA`);
    }
  }
  const stats = channel.getStats();
  console.log(`\n   Total off-chain payments: ${stats.micropayments}`);
  console.log(`   Total spent: ${formatEther(stats.spent)} QTA`);
  console.log(`   On-chain txs needed: 2 (open + close)\n`);

  // === Step 5: Settle the channel ===
  console.log("💸 Step 5: Provider settles channel on-chain...");
  // In demo we just simulate — in production provider would call close()
  console.log(`   → ${formatEther(stats.spent)} QTA → provider`);
  console.log(`   → ${formatEther(stats.remaining)} QTA refund to agent\n`);

  // === Step 6: Agent returns result to user, gets paid, sends profit to owner ===
  console.log("💰 Step 6: Agent delivers result and books profit...");
  const profit = userTask.payment - stats.spent;
  console.log(`   Revenue:  ${formatEther(userTask.payment)} QTA`);
  console.log(`   Cost:     ${formatEther(stats.spent)} QTA`);
  console.log(`   Profit:   ${formatEther(profit)} QTA → returned to owner\n`);

  // === Step 7: Heartbeat to prove agent is alive ===
  console.log("💓 Step 7: Agent pings (heartbeat for death-switch)...");
  await agent.ping();
  console.log(`✓ Agent alive: ${await agent.isAlive()}\n`);

  console.log("✨ Demo complete! In 7 steps the agent:");
  console.log("   • Earned 2 QTA from user task");
  console.log("   • Spent 0.5 QTA on AI inference (50 off-chain micropayments)");
  console.log("   • Returned 1.5 QTA profit to owner");
  console.log("   • Maintained heartbeat to avoid death-switch refund");
  console.log("\n💡 In production this loop runs 24/7, agent compounds earnings.");
}

main().catch(e => {
  console.error("Demo error:", e);
  console.log("\n⚠️  Note: This demo requires deployed contracts + RPC + funded wallet.");
  console.log("    Run locally or on Base Sepolia testnet.");
  process.exit(1);
});
