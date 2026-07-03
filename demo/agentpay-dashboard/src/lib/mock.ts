import { keccak256, encodeAbiParameters, parseEther } from "viem";

export type SpendingPolicy = {
  maxPerTx: bigint;
  maxPerDay: bigint;
  deathSwitchSec: number;
  requireIntent: boolean;
  active: boolean;
};

export type Agent = {
  agentId: string;
  owner: string;
  wallet: string;
  name: string;
  metadataURI: string;
  policy: SpendingPolicy;
  spentToday: bigint;
  lastPing: number;
  todayStarted: number;
  active: boolean;
};

export type PaymentReceipt = {
  id: string;
  timestamp: number;
  agentId: string;
  agentName: string;
  amount: bigint;
  service: string;
  status: "success" | "fail";
  reason?: string;
  txHash?: string;
};

const DAY_MS = 24 * 60 * 60 * 1000;

export function makeAgentId(owner: string, name: string): string {
  return keccak256(
    encodeAbiParameters(
      [{ type: "address" as const }, { type: "string" as const }],
      [owner as `0x${string}`, name],
    ),
  );
}

export function createAgent(opts: {
  owner: string;
  wallet: string;
  name: string;
  metadataURI: string;
}): Agent {
  return {
    agentId: makeAgentId(opts.owner, opts.name),
    owner: opts.owner,
    wallet: opts.wallet,
    name: opts.name,
    metadataURI: opts.metadataURI,
    policy: {
      maxPerTx: parseEther("0.1"),
      maxPerDay: parseEther("1"),
      deathSwitchSec: 7 * 24 * 60 * 60,
      requireIntent: false,
      active: true,
    },
    spentToday: 0n,
    lastPing: Date.now(),
    todayStarted: Date.now(),
    active: true,
  };
}

export function simulatePayment(
  agent: Agent,
  amount: bigint,
  service: string,
  caller: string,
): PaymentReceipt {
  const now = Date.now();
  // Reset daily window
  if (now - agent.todayStarted >= DAY_MS) {
    agent.spentToday = 0n;
    agent.todayStarted = now;
  }

  if (!agent.active || !agent.policy.active) {
    return {
      id: crypto.randomUUID(),
      timestamp: now,
      agentId: agent.agentId,
      agentName: agent.name,
      amount,
      service,
      status: "fail",
      reason: "policy_inactive",
    };
  }

  if (caller !== agent.wallet) {
    return {
      id: crypto.randomUUID(),
      timestamp: now,
      agentId: agent.agentId,
      agentName: agent.name,
      amount,
      service,
      status: "fail",
      reason: "unauthorized_spender",
    };
  }

  if (amount > agent.policy.maxPerTx) {
    return {
      id: crypto.randomUUID(),
      timestamp: now,
      agentId: agent.agentId,
      agentName: agent.name,
      amount,
      service,
      status: "fail",
      reason: "over_max_tx",
    };
  }

  if (agent.spentToday + amount > agent.policy.maxPerDay) {
    return {
      id: crypto.randomUUID(),
      timestamp: now,
      agentId: agent.agentId,
      agentName: agent.name,
      amount,
      service,
      status: "fail",
      reason: "over_daily_budget",
    };
  }

  // Success
  agent.spentToday += amount;
  agent.lastPing = now;

  return {
    id: crypto.randomUUID(),
    timestamp: now,
    agentId: agent.agentId,
    agentName: agent.name,
    amount,
    service,
    status: "success",
    txHash: "0x" + Array.from({ length: 64 }, () =>
      Math.floor(Math.random() * 16).toString(16),
    ).join(""),
  };
}
