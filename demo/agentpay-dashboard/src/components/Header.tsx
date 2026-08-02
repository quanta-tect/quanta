import type { Mode } from '../app/types.js';

export function Header({ mode, onModeChange, contracts: _contracts }: { mode: Mode; onModeChange: (m: Mode) => void; contracts: any }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
      <div>
        <h1 style={{ fontSize: 20, margin: 0 }}>Quanta AgentPay Demo</h1>
        <p style={{ fontSize: 12, color: '#6b7280', margin: 0 }}>Give an AI agent a wallet, a spending policy, and a payment receipt.</p>
      </div>
      <div className="row" style={{ margin: 0 }}>
        <label>Mode</label>
        <select value={mode} onChange={e => onModeChange(e.target.value as Mode)}>
          <option value="mock">Mock / Local</option>
          <option value="sepolia">Base Sepolia</option>
        </select>
      </div>
    </div>
  );
}
