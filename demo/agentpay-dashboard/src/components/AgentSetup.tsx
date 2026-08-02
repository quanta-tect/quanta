import { useState } from 'react';
import type { Agent } from '../app/types.js';

export function AgentSetup({ onCreate, mode }: { onCreate: (a: Agent) => void; mode: string }) {
  const [name, setName] = useState('');
  const [uri, setUri] = useState('ipfs://bafy/agent-card.json');

  const handle = () => {
    if (!name.trim()) return;
    onCreate({
      agentId: '',
      owner: mode === 'mock' ? '0xUser0000000000000000000000000000000001' : '0x0000000000000000000000000000000000000000',
      metadataURI: uri || 'ipfs://default',
      maxPerTx: 0n,
      maxPerDay: 0n,
      active: true,
      registeredAt: Date.now(),
    });
  };

  return (
    <div className="card">
      <h2>1. Agent Setup</h2>
      <div className="row">
        <label>Agent name</label>
        <input value={name} onChange={e => setName(e.target.value)} placeholder="ResearchBot" />
      </div>
      <div className="row">
        <label>Metadata URI</label>
        <input value={uri} onChange={e => setUri(e.target.value)} placeholder="ipfs://..." />
      </div>
      <button onClick={handle}>Register Agent</button>
    </div>
  );
}
