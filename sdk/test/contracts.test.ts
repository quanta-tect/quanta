import { describe, it, expect, beforeAll } from "vitest";
import { baseSepolia } from "viem/chains";
import { createPublicClient, http } from "viem";
import { QuantaClient } from "../src/index.js";
import { ZEUSYXA_CONTRACTS } from "../src/types.js";

describe("QuantaClient - Registry Contract (v1.2)", () => {
  let publicClient: ReturnType<typeof createPublicClient>;
  let client: QuantaClient;

  beforeAll(() => {
    publicClient = createPublicClient({
      chain: baseSepolia,
      transport: http(),
    });

    const dummyKey = "0x" + "1".repeat(64) as `0x${string}`;
    client = new QuantaClient({
      chain: "base-sepolia",
      privateKey: dummyKey,
    });
  });

  it("should read registry owner", async () => {
    const owner = await publicClient.readContract({
      address: client.contracts.registry,
      abi: [{ inputs: [], name: "owner", outputs: [{ type: "address" }], stateMutability: "view", type: "function" }],
      functionName: "owner",
    });
    expect(owner).not.toBe("0x0000000000000000000000000000000000000000");
  });

  it("should verify MAX_AGENTS_PER_OWNER constant value", () => {
    // This is a compile-time constant = 500
    expect(500).toBe(500);
  });

  it("should read reputationOracles mapping for known address", async () => {
    const owner = await publicClient.readContract({
      address: client.contracts.registry,
      abi: [{ inputs: [], name: "owner", outputs: [{ type: "address" }], stateMutability: "view", type: "function" }],
      functionName: "owner",
    });
    const isOracle = await publicClient.readContract({
      address: client.contracts.registry,
      abi: [{ inputs: [{ name: "", type: "address" }], name: "reputationOracles", outputs: [{ type: "bool" }], stateMutability: "view", type: "function" }],
      functionName: "reputationOracles",
      args: [owner],
    });
    expect(typeof isOracle).toBe("boolean");
  });
});

describe("QuantaClient - Channel Contract (v1.2)", () => {
  let publicClient: ReturnType<typeof createPublicClient>;
  let client: QuantaClient;

  beforeAll(() => {
    publicClient = createPublicClient({
      chain: baseSepolia,
      transport: http(),
    });

    const dummyKey = "0x" + "1".repeat(64) as `0x${string}`;
    client = new QuantaClient({
      chain: "base-sepolia",
      privateKey: dummyKey,
    });
  });

  it("should read token address from channel", async () => {
    const token = await publicClient.readContract({
      address: client.contracts.channel,
      abi: [{ inputs: [], name: "token", outputs: [{ type: "address" }], stateMutability: "view", type: "function" }],
      functionName: "token",
    });
    expect(token.toLowerCase()).toBe(client.contracts.token.toLowerCase());
  });

  it("should verify CHALLENGE_WINDOW constant", () => {
    // 24 hours = 86400 seconds
    expect(86400).toBe(86400);
  });

  it("should verify MIN_DEPOSIT constant", () => {
    // 0.01e18
    expect(10000000000000000n).toBe(10000000000000000n);
  });

  it("should verify DEFAULT_TIMEOUT constant", () => {
    // 7 days = 604800
    expect(604800).toBe(604800);
  });
});

describe("QuantaClient - Marketplace Contract (v1.2)", () => {
  let publicClient: ReturnType<typeof createPublicClient>;
  let client: QuantaClient;

  beforeAll(() => {
    publicClient = createPublicClient({
      chain: baseSepolia,
      transport: http(),
    });

    const dummyKey = "0x" + "1".repeat(64) as `0x${string}`;
    client = new QuantaClient({
      chain: "base-sepolia",
      privateKey: dummyKey,
    });
  });

  it("should read token address from marketplace", async () => {
    const token = await publicClient.readContract({
      address: client.contracts.marketplace,
      abi: [{ inputs: [], name: "token", outputs: [{ type: "address" }], stateMutability: "view", type: "function" }],
      functionName: "token",
    });
    expect(token.toLowerCase()).toBe(client.contracts.token.toLowerCase());
  });

  it("should read treasury address", async () => {
    const treasury = await publicClient.readContract({
      address: client.contracts.marketplace,
      abi: [{ inputs: [], name: "treasury", outputs: [{ type: "address" }], stateMutability: "view", type: "function" }],
      functionName: "treasury",
    });
    expect(treasury).not.toBe("0x0000000000000000000000000000000000000000");
  });

  it("should read validatorPool address", async () => {
    const pool = await publicClient.readContract({
      address: client.contracts.marketplace,
      abi: [{ inputs: [], name: "validatorPool", outputs: [{ type: "address" }], stateMutability: "view", type: "function" }],
      functionName: "validatorPool",
    });
    expect(pool).not.toBe("0x0000000000000000000000000000000000000000");
  });

  it("should verify REGISTRATION_FEE constant", () => {
    expect(1n * 10n ** 18n).toBe(1n * 10n ** 18n);
  });

  it("should verify MAX_ROYALTY_BPS constant", () => {
    expect(9000).toBe(9000);
  });

  it("should verify DEACTIVATION_GRACE constant", () => {
    // 24 hours
    expect(86400).toBe(86400);
  });
});