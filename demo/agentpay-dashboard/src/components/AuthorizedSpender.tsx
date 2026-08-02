import { useState } from 'react';

export function AuthorizedSpender({ agentId: _agentId, onToggle }: { agentId: string; onToggle: (spender: string, authorized: boolean) => void }) {
  const [spender, setSpender] = useState('');
  const [authorized, setAuthorized] = useState(true);

  return (
    <div className="card">
      <h2>3. Authorized Spender</h2>
      <p style={{ fontSize: 12, color: '#6b7280' }}>Authorize marketplace/payment contracts to spend on behalf of this agent.</p>
      <div className="row">
        <label>Spender address</label>
        <input value={spender} onChange={e => setSpender(e.target.value)} placeholder="0x..." />
      </div>
      <div className="row">
        <label>Authorized</label>
        <input type="checkbox" checked={authorized} onChange={e => setAuthorized(e.target.checked)} />
      </div>
      <button onClick={() => { if (spender.trim()) onToggle(spender, authorized); }}>Apply</button>
    </div>
  );
}
