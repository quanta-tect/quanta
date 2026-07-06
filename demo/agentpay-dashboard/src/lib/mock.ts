import { useState } from 'react';

export interface AgentPolicy {
  maxPerTx: string;
  maxPerDay: string;
  active: boolean;
}

export interface AgentRecord {
  id: string;
  name: string;
  owner: string;
  metadataUri: string;
  policy: AgentPolicy;
  authorizedSpender: string;
}

export interface Receipt {
  id: string;
  timestamp: string;
  agentId: string;
  amount: string;
  service: string;
  status: string;
  txHash?: string;
  reason?: string;
  isMock?: boolean;
  action?: string;
  error?: string;
  detail?: string;
}

const INITIAL_AGENT: AgentRecord = {
  id: 'agent-001',
  name: 'DemoAgent',
  owner: '0x1111111111111111111111111111111111111111',
  metadataUri: 'ipfs://demo-agent',
  policy: {
    maxPerTx: '0.01',
    maxPerDay: '0.05',
    active: true,
  },
  authorizedSpender: '0x2222222222222222222222222222222222222222',
};

const INITIAL_RECEIPTS: Receipt[] = [
  {
    id: 'rcpt-1',
    timestamp: new Date(Date.now() - 1000 * 60 * 60).toISOString(),
    agentId: 'agent-001',
    amount: '0.002',
    service: 'openai-api',
    status: 'SUCCESS',
    txHash: 'mock-abc123',
    reason: 'authorized_spender',
    isMock: true,
  },
];

export function useMockMode() {
  const [mockMode, setMockMode] = useState(true);
  return { mockMode, setMockMode };
}

export function useAgentState() {
  const [agent, setAgent] = useState<AgentRecord>(INITIAL_AGENT);

  const registerAgent = (name: string, owner: string, metadataUri: string) => {
    setAgent({
      ...agent,
      id: `agent-${Date.now()}`,
      name,
      owner,
      metadataUri,
    });
  };

  const updatePolicy = (policy: AgentPolicy) => {
    setAgent({ ...agent, policy });
  };

  const setAuthorizedSpender = (address: string) => {
    setAgent({ ...agent, authorizedSpender: address });
  };

  return { agent, registerAgent, updatePolicy, setAuthorizedSpender };
}

export function useReceipts() {
  const [receipts, setReceipts] = useState<Receipt[]>(INITIAL_RECEIPTS);

  const addReceipt = (receipt: Receipt) => {
    setReceipts([receipt, ...receipts]);
  };

  return { receipts, addReceipt };
}

export function simulatePayment(
  agent: AgentRecord,
  amount: string,
  service: string,
  spender: string
): Receipt {
  const numAmount = parseFloat(amount);
  const maxTx = parseFloat(agent.policy.maxPerTx);
  const maxDay = parseFloat(agent.policy.maxPerDay);

  if (!agent.policy.active) {
    return {
      id: `rcpt-${Date.now()}`,
      timestamp: new Date().toISOString(),
      agentId: agent.id,
      amount,
      service,
      status: 'FAILED',
      reason: 'policy_inactive',
      isMock: true,
    };
  }

  if (spender.toLowerCase() !== agent.authorizedSpender.toLowerCase()) {
    return {
      id: `rcpt-${Date.now()}`,
      timestamp: new Date().toISOString(),
      agentId: agent.id,
      amount,
      service,
      status: 'FAILED',
      reason: 'unauthorized_spender',
      isMock: true,
    };
  }

  if (numAmount > maxTx) {
    return {
      id: `rcpt-${Date.now()}`,
      timestamp: new Date().toISOString(),
      agentId: agent.id,
      amount,
      service,
      status: 'FAILED',
      reason: 'over_max_per_transaction',
      isMock: true,
    };
  }

  if (numAmount > maxDay) {
    return {
      id: `rcpt-${Date.now()}`,
      timestamp: new Date().toISOString(),
      agentId: agent.id,
      amount,
      service,
      status: 'FAILED',
      reason: 'over_daily_budget',
      isMock: true,
    };
  }

  return {
    id: `rcpt-${Date.now()}`,
    timestamp: new Date().toISOString(),
    agentId: agent.id,
    amount,
    service,
    status: 'SUCCESS',
    txHash: `mock-${Math.random().toString(16).slice(2, 14)}`,
    reason: 'authorized_spender',
    isMock: true,
  };
}
