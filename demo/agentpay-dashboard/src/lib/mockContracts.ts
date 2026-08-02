import type { Agent, Policy, Receipt, Contracts } from '../app/types.js';
import { keccak256, encodeAbiParameters, parseEther } from 'viem';

const DAY_MS = 24 * 60 * 60 * 1000;

export function createMockContracts(overrides?: Partial<Contracts>): Contracts {
  return {
    registry: '0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB',
    channel: '0xF146e95b97fce1d1800F5F922AE99155711A4314',
    marketplace: '0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49',
    token: '0x312137fb6943F8f89F5eF0f221aA102035a16625',
    ...overrides,
  };
}

export class MockRegistry {
  private agents: Map<string, Agent> = new Map();
  private authorized: Map<string, Set<string>> = new Map(); // agentId -> spenders
  private receipts: Receipt[] = [];

  getAgents() { return Array.from(this.agents.values()); }
  getReceipts() { return this.receipts; }

  authorizeSpender(agentId: string, spender: string) {
    const set = this.authorized.get(agentId) || new Set();
    set.add(spender);
    this.authorized.set(agentId, set);
  }

  registerAgent(owner: string, metadataURI: string, maxPerTx: string, maxPerDay: string): Agent {
    const agentId = keccak256(
      encodeAbiParameters([{ type: 'address' }, { type: 'string' }], [owner as `0x${string}`, metadataURI])
    );
    if (this.agents.has(agentId)) throw new Error('Agent already exists');
    const agent: Agent = {
      agentId,
      owner,
      metadataURI,
      maxPerTx: parseEther(maxPerTx),
      maxPerDay: parseEther(maxPerDay),
      active: true,
      registeredAt: Date.now(),
    };
    this.agents.set(agentId, agent);
    return agent;
  }

  updatePolicy(agentId: string, maxPerTx: string, maxPerDay: string) {
    const agent = this.agents.get(agentId);
    if (!agent) throw new Error('Agent not found');
    agent.maxPerTx = parseEther(maxPerTx);
    agent.maxPerDay = parseEther(maxPerDay);
  }

  checkAndRecordSpend(agentId: string, amount: string, spender: string, service: string): Receipt {
    const agent = this.agents.get(agentId);
    if (!agent) return { id: crypto.randomUUID(), timestamp: Date.now(), agentId, amount: BigInt(0), service, status: 'fail', reason: 'Agent not found' };
    if (!agent.active) return { id: crypto.randomUUID(), timestamp: Date.now(), agentId, amount: BigInt(0), service, status: 'fail', reason: 'Agent inactive' };

    const policy = { maxPerTx: agent.maxPerTx, maxPerDay: agent.maxPerDay, active: true } as Policy;
    const spenders = this.authorized.get(agentId) || new Set();
    if (spender !== agent.owner && !spenders.has(spender)) {
      return { id: crypto.randomUUID(), timestamp: Date.now(), agentId, amount: BigInt(0), service, status: 'fail', reason: 'Not authorized spender' };
    }
    if (!policy.active) return { id: crypto.randomUUID(), timestamp: Date.now(), agentId, amount: BigInt(0), service, status: 'fail', reason: 'Policy inactive' };

    const amt = parseEther(amount);
    if (amt > policy.maxPerTx) return { id: crypto.randomUUID(), timestamp: Date.now(), agentId, amount: amt, service, status: 'fail', reason: 'Exceeds max per tx' };

    const rolling = this.receipts
      .filter(r => r.agentId === agentId && r.status === 'success')
      .filter(r => Date.now() - r.timestamp < DAY_MS)
      .reduce((s, r) => s + r.amount, BigInt(0));

    if (rolling + amt > policy.maxPerDay) return { id: crypto.randomUUID(), timestamp: Date.now(), agentId, amount: amt, service, status: 'fail', reason: 'Exceeds max per day' };

    const receipt: Receipt = { id: crypto.randomUUID(), timestamp: Date.now(), agentId, amount: amt, service, status: 'success', txHash: '0x' + Array.from(crypto.getRandomValues(new Uint8Array(32))).map(b => b.toString(16).padStart(2, '0')).join('') };
    this.receipts.push(receipt);
    return receipt;
  }
}
