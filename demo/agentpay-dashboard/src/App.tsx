import { useState } from 'react';
import { useAccount, useConnect, useDisconnect, useSwitchChain } from 'wagmi';
import { injected } from 'wagmi/connectors';
import { useMockMode, useAgentState, useReceipts, simulatePayment } from './lib/mock';
import { loadConfig } from './lib/config';

function Section({ title, children, muted }: { title: string; children: React.ReactNode; muted?: boolean }) {
  return (
    <section className={`section${muted ? ' section-muted' : ''}`}>
      <h2>{title}</h2>
      {children}
    </section>
  );
}

function Field({ label, value, onChange, placeholder, type = 'text' }: { label: string; value: string; onChange: (v: string) => void; placeholder?: string; type?: string }) {
  return (
    <label className="field">
      <span>{label}</span>
      <input type={type} value={value} placeholder={placeholder} onChange={(e) => onChange(e.target.value)} />
    </label>
  );
}

export default function App() {
  const config = loadConfig();
  const { mockMode, setMockMode } = useMockMode();
  const { agent, registerAgent, updatePolicy, setAuthorizedSpender } = useAgentState();
  const { receipts, addReceipt } = useReceipts();

  const { address, isConnected, chainId } = useAccount();
  const { connect } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain } = useSwitchChain();

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

  const missingAddresses = [
    ['Agent Registry', config.agentRegistryAddress],
    ['Payment Channel', config.paymentChannelAddress],
    ['Marketplace', config.marketplaceAddress],
    ['QTA Token', config.qtaTokenAddress],
  ].filter(([, address]) => !address || address === '0x');

  const isWrongNetwork = !mockMode && isConnected && chainId != null && chainId !== config.chainId;

  const envStatusLabel = mockMode ? 'Mock Mode' : missingAddresses.length === 0 ? 'Base Sepolia Configured' : 'Missing Addresses';
  const envStatusClass = mockMode ? 'badge-mock' : missingAddresses.length === 0 ? 'badge-configured' : 'badge-warn';

  const walletStatusLabel = isWrongNetwork ? 'Wrong Network' : isConnected ? 'Wallet Connected' : 'Base Sepolia Configured';
  const walletStatusClass = isWrongNetwork ? 'badge-warn' : isConnected ? 'badge-ok' : 'badge-configured';

  const shortAddress = address ? `${address.slice(0, 6)}...${address.slice(-4)}` : '';

  return (
    <div className="app">
      <header className="app-header">
        <h1>Quanta AgentPay Demo</h1>
        <div className="status-pills">
          <span className={`badge ${envStatusClass}`}>{envStatusLabel}</span>
          {!mockMode && (
            <span className={`badge ${walletStatusClass}`}>{walletStatusLabel}</span>
          )}
        </div>
        <label className="toggle">
          <input type="checkbox" checked={mockMode} onChange={(e) => setMockMode(e.target.checked)} />
          <span>Mock mode</span>
        </label>
      </header>

      {!mockMode && missingAddresses.length > 0 && (
        <div className="alert warn">
          <strong>Configuration warning:</strong> set contract addresses in <code>.env</code>.<br />
          {missingAddresses.map(([name, address]) => (
            <div key={name}>
              {name}: {address || '<missing>'}
            </div>
          ))}
        </div>
      )}

      {isWrongNetwork && (
        <div className="alert warn">
          <strong>Wrong network:</strong> switch wallet to Base Sepolia (chainId {config.chainId}).
          <button className="primary" onClick={() => switchChain({ chainId: config.chainId })}>Switch to Base Sepolia</button>
        </div>
      )}

      {!mockMode && !isConnected && (
        <div className="alert info">
          Connect a wallet to use Base Sepolia mode. Mock mode remains enabled until you turn it off.
          <button className="primary" onClick={() => connect({ connector: injected() })}>Connect Wallet</button>
        </div>
      )}

      {isConnected && (
        <div className="readout">
          <strong>Wallet:</strong> {shortAddress}{' '}
          <button className="secondary" onClick={() => disconnect()}>Disconnect</button>
        </div>
      )}

      <Section title="Agent Setup">
        <div className="grid">
          <Field label="Agent name" value={name} onChange={setName} placeholder="MyAgent" />
          <Field label="Owner address" value={owner} onChange={setOwner} placeholder="0x..." />
          <Field label="Metadata URI" value={metadata} onChange={setMetadata} placeholder="ipfs://..." />
        </div>
        <button className="primary" onClick={handleRegister}>Register Agent</button>
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
          <input type="checkbox" checked={policyActive} onChange={(e) => setPolicyActive(e.target.checked)} />
          <span>Policy active</span>
        </label>
        <button className="primary" onClick={handlePolicySave}>Save/Update Policy</button>
      </Section>

      <Section title="Authorized Spender">
        <div className="grid">
          <Field label="Spender address" value={spender} onChange={setSpender} placeholder="0x..." />
        </div>
        <button className="primary" onClick={handleAuthorize}>Authorize/Update Spender</button>
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
        <button className="primary" onClick={handlePay}>Simulate Payment</button>
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
                <td><span className={`badge badge-${r.status.toLowerCase()}`}>{r.status}</span></td>
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
