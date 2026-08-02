import { useState } from 'react';

export function SpendingPolicy({ agent: _agent, onSave, mode: _mode }: { agent: any; onSave: (maxPerTx: string, maxPerDay: string) => void; mode: string }) {
  const [maxPerTx, setMaxPerTx] = useState('0.1');
  const [maxPerDay, setMaxPerDay] = useState('2');
  const [active, setActive] = useState(true);

  return (
    <div className="card">
      <h2>2. Spending Policy</h2>
      <div className="row">
        <label>Max per tx (ETH)</label>
        <input type="number" step="0.01" value={maxPerTx} onChange={e => setMaxPerTx(e.target.value)} />
      </div>
      <div className="row">
        <label>Max per day (ETH)</label>
        <input type="number" step="0.1" value={maxPerDay} onChange={e => setMaxPerDay(e.target.value)} />
      </div>
      <div className="row">
        <label>Policy active</label>
        <input type="checkbox" checked={active} onChange={e => setActive(e.target.checked)} />
      </div>
      <button onClick={() => { onSave(maxPerTx, maxPerDay); }}>Save Policy</button>
    </div>
  );
}
