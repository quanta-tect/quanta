import 'dotenv/config';
/**
 * 🧠 QUANTA AI Model Marketplace Demo
 * ===================================
 * Registers an AI model for sale, then buys an inference call (x402-style
 * ERC-20 payment to the model creator via the on-chain marketplace).
 *
 * Run: tsx examples/buy-inference.ts
 * (Requires PRIVATE_KEY in .env — NEVER use a default, see SECURITY.md)
 */

import { QuantaClient, ModelMarketplace, AIAgent } from "../src/index.js";
import { parseEther, formatEther } from "viem";

async function main() {
  console.log("╔══════════════════════════════════════════════════════════╗");
  console.log("║  🧠 QUANTA AI Model Marketplace Demo                    ║");
  console.log("╚══════════════════════════════════════════════════════════╝");

  if (!process.env.PRIVATE_KEY) {
    throw new Error("PRIVATE_KEY env var required. See SECURITY.md.");
  }
  const privateKey = process.env.PRIVATE_KEY as `0x${string}`;

  const client = new QuantaClient({ chain: "base-sepolia", privateKey });
  console.log(`👤 Creator/Owner: ${client.address}`);

  const marketplace = new ModelMarketplace(client);

  console.log("\n📦 Registering model 'quanta-llm-mini'...");
  const modelId = await marketplace.registerModel({
    pricePerCall: parseEther("0.001"),
    royaltyBps: 250, // 2.5%
    metadataURI: "ipfs://bafy.../quanta-llm-mini.json",
  });
  console.log(`✓ Model registered with id ${modelId}`);

  const info = await marketplace.getModel(modelId);
  console.log(`  Price/call: ${formatEther(info.pricePerCall)} QTA`);
  console.log(`  Royalty: ${info.royaltyBps / 100}%`);
  console.log(`  Available: ${await marketplace.isModelAvailable(modelId)}`);

  console.log("\n🤖 Buying 3 inference calls...");
  for (let i = 0; i < 3; i++) {
    await marketplace.payForInference(modelId);
    console.log(`  • Inference #${i + 1} paid`);
  }

  const after = await marketplace.getModel(modelId);
  console.log(`\n📈 Model stats:`);
  console.log(`  Total calls:   ${after.totalCalls}`);
  console.log(`  Total earned:  ${formatEther(after.totalEarned)} QTA`);

  console.log("\n💡 Real revenue flows to the creator address on every call.");
}

main().catch((e) => {
  console.error("Demo error:", e);
  console.log("\n⚠️  Requires deployed contracts + RPC + funded wallet (Base Sepolia).");
  process.exit(1);
});
