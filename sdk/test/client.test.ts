import { describe, it, expect, beforeAll } from "vitest";
import { baseSepolia } from "viem/chains";
import { createPublicClient, http } from "viem";
import { QuantaClient } from "../src/index.js";
import { ZEUSYXA_CONTRACTS } from "../src/types.js";

describe("QuantaClient - Base Sepolia Integration (v1.2 QUANTA deployed)", () => {
  let publicClient: ReturnType<typeof createPublicClient>;
  let client: QuantaClient;

  beforeAll(() => {
    publicClient = createPublicClient({
      chain: baseSepolia,
      transport: http(),
    });

    // Use a dummy private key for read-only tests
    const dummyKey = "0x" + "1".repeat(64) as `0x${string}`;
    client = new QuantaClient({
      chain: "base-sepolia",
      privateKey: dummyKey,
    });
  });

  it("should have correct contract addresses for base-sepolia", () => {
    expect(client.contracts.token).toBe(ZEUSYXA_CONTRACTS["base-sepolia"].token);
    expect(client.contracts.registry).toBe(ZEUSYXA_CONTRACTS["base-sepolia"].registry);
    expect(client.contracts.channel).toBe(ZEUSYXA_CONTRACTS["base-sepolia"].channel);
    expect(client.contracts.marketplace).toBe(ZEUSYXA_CONTRACTS["base-sepolia"].marketplace);
  });

  it("should have valid non-zero contract addresses", () => {
    expect(client.contracts.token).not.toBe("0x0000000000000000000000000000000000000000");
    expect(client.contracts.registry).not.toBe("0x0000000000000000000000000000000000000000");
    expect(client.contracts.channel).not.toBe("0x0000000000000000000000000000000000000000");
    expect(client.contracts.marketplace).not.toBe("0x0000000000000000000000000000000000000000");
  });

  it("should read token totalSupply from chain", async () => {
    const supply = await client.totalSupply();
    expect(supply).toBeGreaterThan(0n);
    // Genesis supply is 300M QTA (v1.2)
    expect(supply).toBe(300_000_000n * 10n ** 18n);
  });

  it("should read token name and symbol (v1.2 QUANTA)", async () => {
    const name = await publicClient.readContract({
      address: client.contracts.token,
      abi: [{ inputs: [], name: "name", outputs: [{ type: "string" }], stateMutability: "view", type: "function" }],
      functionName: "name",
    });
    const symbol = await publicClient.readContract({
      address: client.contracts.token,
      abi: [{ inputs: [], name: "symbol", outputs: [{ type: "string" }], stateMutability: "view", type: "function" }],
      functionName: "symbol",
    });
    expect(name).toBe("QUANTA");
    expect(symbol).toBe("QTA");
  });

  it("should read AI tax bps from storage (v1.2 uses aiUsageTaxBps)", async () => {
    const taxBps = await publicClient.readContract({
      address: client.contracts.token,
      abi: [{ inputs: [], name: "aiUsageTaxBps", outputs: [{ type: "uint16" }], stateMutability: "view", type: "function" }],
      functionName: "aiUsageTaxBps",
    });
    // 30 bps = 0.3% (viem returns number for uint16)
    expect(taxBps).toBe(30);
  });

  it("should read MAX_SUPPLY constant", async () => {
    const maxSupply = await publicClient.readContract({
      address: client.contracts.token,
      abi: [{ inputs: [], name: "MAX_SUPPLY", outputs: [{ type: "uint256" }], stateMutability: "view", type: "function" }],
      functionName: "MAX_SUPPLY",
    });
    expect(maxSupply).toBe(1_000_000_000n * 10n ** 18n);
  });
});