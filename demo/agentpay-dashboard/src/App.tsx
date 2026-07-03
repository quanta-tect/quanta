import { useState } from 'react';
import { useMockMode, useAgentState, useReceipts, simulatePayment } from './lib/mock';

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="section">
      <h2>{title}</h2>
      {children}
    </section>
  );
}

function Field({ label, value, onChange, placeholder, type = 'text' }: any) {
  return (
    <label className="field">
      <span>{label}</span>
      <input
        type={type}
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
      />
    </label>
  );
}

export default function App() {
  const { mockMode, setMockMode } = useMockMode();
  const { agent, registerAgent, updatePolicy, setAuthorizedSpender } = useAgentState();
  const { receipts, addReceipt } = useReceipts();

  const [name, setName] = useState('');
  const [owner, setOwner] = useState('');
  const [metadata, setMetadata] = useState('');
  const [maxPerTx, setMaxPerTx] = useState('0.01');
  const [maxPerDay, setMaxPerDay] = useState('0.05');
  const [policyActive, setPolicyActive] = useState(true);
  const [spender, setSpender] = useState('');
  const [payAmount, setPayAmount] = useState('0.001');
  const [payService, setPayService] = useState('openai-api');
  const [paySpender, setPaySpender] = useState('');

  const handleRegister = () => {
    if (!name || !owner) return;
    registerAgent(name, owner, metadata || 'ipfs://demo-agent');
    setName('');
    setOwner('');
    setMetadata('');
  };

  const handlePolicySave = () => {
    updatePolicy({ maxPerTx, maxPerDay, active: policyActive });
  };

  const handleAuthorize = () => {
    if (!spender) return;
    setAuthorizedSpender(spender);
    setSpender('');
  };

  const handlePay = () => {
    if (!paySpender) return;
    const receipt = simulatePayment(agent, payAmount, payService, paySpender);
    addReceipt(receipt);
    setPayAmount('0.001');
    setPayService('openai-api');
    setPaySpender('');
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>Quanta AgentPay Demo</h1>
        <label className="toggle">
          <input
            type="checkbox"
            checked={mockMode}
            onChange={(e) => setMockMode(e.target.checked)}
          />
          <span>Mock mode</span>
        </label>
      </header>

      <Section title="Agent Setup">
        <div className="grid">
          <Field label="Agent name" value={name} onChange={setName} placeholder="MyAgent" />
          <Field label="Owner address" value={owner} onChange={setOwner} placeholder="0x..." />
          <Field label="Metadata URI" value={metadata} onChange={setMetadata} placeholder="ipfs://..." />
        </div>
        <button className="primary" onClick={handleRegister}>
          Register Agent
        </button>
        <div className="readout">
          <strong>Current agent:</strong> {agent.name} ({agent.id}) - owner {agent.owner}
        </div>
      </Section>

      <Section title="Spending Policy">
        <div className="grid">
          <Field label="Max per transaction (QTA)" value={maxPerTx} onChange={setMaxPerTx} placeholder="0.01" />
          <Field label="Daily budget (QTA)" value={maxPerDay} onChange={setMaxPerDay} placeholder="0.05" />
        </div>
        <label className="toggle">
          <input
            type="checkbox"
            checked={policyActive}
            onChange={(e) => setPolicyActive(e.target.checked)}
          />
          <span>Policy active</span>
        </label>
        <button className="primary" onClick={handlePolicySave}>
          Save/Update Policy
        </button>
      </Section>

      <Section title="Authorized Spender">
        <div className="grid">
          <Field label="Spender address" value={spender} onChange={setSpender} placeholder="0x..." />
        </div>
        <button className="primary" onClick={handleAuthorize}>
          Authorize/Update Spender
        </button>
        <div className="readout">
          <strong>Current spender:</strong> {agent.authorizedSpender}
        </div>
      </Section>

      <Section title="Simulate Agent Payment">
        <div className="grid">
          <Field label="Amount (QTA)" value={payAmount} onChange={setPayAmount} placeholder="0.001" />
          <Field label="Service name" value={payService} onChange={setPayService} placeholder="openai-api" />
          <Field label="Spender address" value={paySpender} onChange={setPaySpender} placeholder="0x..." />
        </div>
        <button className="primary" onClick={handlePay}>
          Simulate Payment
        </button>
      </Section>

      <Section title="Receipts / History">
        {receipts.length === 0 && <p className="muted">No receipts yet.</p>}
        <table className="table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Agent</th>
              <th>Amount</th>
              <th>Service</th>
              <th>Status</th>
              <th>TxHash</th>
              <th>Reason</th>
            </tr>
          </thead>
          <tbody>
            {receipts.map((r) => (
              <tr key={r.id}>
                <td>{new Date(r.timestamp).toLocaleString()}</td>
                <td>{r.agentId}</td>
                <td>{r.amount}</td>
                <td>{r.service}</td>
                <td>
                  <span className={`badge badge-${r.status.toLowerCase()}`}>{r.status}</span>
                </td>
                <td className="mono">{r.txHash || '-'}</td>
                <td>{r.reason || '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Section>
    </div>
  );
}
