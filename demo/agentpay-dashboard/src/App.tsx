import { useState, useCallback } from 'react';
import { Header } from './components/Header';
import { AgentSetup } from './components/AgentSetup';
import { SpendingPolicy } from './components/SpendingPolicy';
import { AuthorizedSpender } from './components/AuthorizedSpender';
import { SimulatePayment } from './components/SimulatePayment';
import { ReceiptsHistory } from './components/ReceiptsHistory';
import { MockRegistry, createMockContracts } from './lib/mockContracts';
import type { Agent, Receipt, Mode } from './app/types';

export default function App() {
  const [mode, setMode] = useState<Mode>('mock');
  const [mockRegistry] = useState(() => new MockRegistry());
  const [agent, setAgent] = useState<Agent | null>(null);
  const [receipts, setReceipts] = useState<Receipt[]>([]);

  const handleCreateAgent = useCallback((a: Agent) => {
    setAgent(a);
    // In real mode, agentId would be generated client-side via keccak256(owner, name)
  }, []);

  const handleSavePolicy = useCallback((maxPerTx: string, maxPerDay: string) => {
    if (!agent) return;
    if (mode === 'mock') {
      mockRegistry.updatePolicy(agent.agentId, maxPerTx, maxPerDay);
      setAgent({ ...agent, maxPerTx: BigInt(0), maxPerDay: BigInt(0) });
    }
  }, [agent, mode, mockRegistry]);

  const handleToggleSpender = useCallback((spender: string, _authorized: boolean) => {
    if (!agent) return;
    if (mode === 'mock') {
      mockRegistry.authorizeSpender(agent.agentId, spender);
    }
  }, [agent, mode, mockRegistry]);

  const handleSimulate = useCallback((r: Receipt) => {
    if (!agent) return;
    if (mode === 'mock') {
      const result = mockRegistry.checkAndRecordSpend(agent.agentId, '0.01', agent.owner, r.service);
      setReceipts((prev: Receipt[]) => [...prev, result]);
    }
  }, [agent, mode, mockRegistry]);

  return (
    <>
      <Header mode={mode} onModeChange={setMode} contracts={createMockContracts()} />
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <div>
          <AgentSetup onCreate={handleCreateAgent} mode={mode} />
          {agent && <SpendingPolicy agent={agent} onSave={handleSavePolicy} mode={mode} />}
          {agent && <AuthorizedSpender agentId={agent.agentId} onToggle={handleToggleSpender} />}
        </div>
        <div>
          {agent && <SimulatePayment agent={agent} onResult={handleSimulate} mode={mode} />}
          <ReceiptsHistory receipts={mode === 'mock' ? mockRegistry.getReceipts() : receipts} />
        </div>
      </div>
    </>
  );
}
