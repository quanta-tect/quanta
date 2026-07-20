import { useState } from 'react';
import { useAccount, useConnect, useDisconnect, useSwitchChain, useWriteContract } from 'wagmi';
import { injected } from 'wagmi/connectors';
import { useMockMode, useAgentState, useReceipts, simulatePayment } from './lib/mock';
import { loadConfig } from './lib/config';
import {
  AIAgentRegistryABI,
  createBaseReceipt,
  baseExplorerUrl,
  weiFromZyx,
  bytes32AgentId,
  BaseReceipt,
} from './lib/contracts';

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

type ErrorReason =
  | 'wallet_not_connected'
  | 'wrong_network'
  | 'missing_address'
  | 'unauthorized_spender'
  | 'policy_inactive'
  | 'over_max_per_transaction'
  | 'over_daily_budget'
  | 'user_rejected'
  | 'contract_revert'
  | 'unknown_error';

interface AppError {
  reason: ErrorReason;
  message: string;
}

function requireRealReady(
  address?: string,
  isConnected?: boolean,
  chainId?: number,
  config?: { chainId: number; agentRegistryAddress: string; zyxTokenAddress: string },
): AppError | null {
  if (!isConnected || !address) {
    return { reason: 'wallet_not_connected', message: 'Connect wallet first.' };
  }
  if (chainId !== undefined && chainId !== config!.chainId) {
    return { reason: 'wrong_network', message: `Wrong network. Switch to Base Sepolia (${config!.chainId}).` };
  }
  if (!config!.agentRegistryAddress || config!.agentRegistryAddress === '0x') {
    return { reason: 'missing_address', message: 'AIAgentRegistry address missing in .env.' };
  }
  return null;
}

function errToReceiptReason(err: AppError): BaseReceipt['reason'] {
  return err.reason as BaseReceipt['reason'];
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
  const registryWrite = useWriteContract();

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
  const [realStatus, setRealStatus] = useState<string>('');
  const [realAgentId, setRealAgentId] = useState<string>('');
  const [realReceipts, setRealReceipts] = useState<BaseReceipt[]>([]);

  const pushRealReceipt = (r: BaseReceipt) => {
    setRealReceipts(prev => [r, ...prev]);
  };

  const missingAddresses = [
    ['Agent Registry', config.agentRegistryAddress],
    ['Payment Channel', config.paymentChannelAddress],
    ['Marketplace', config.marketplaceAddress],
    ['ZYX Token', config.zyxTokenAddress],
  ].filter(([, a]) => !a || a === '0x');

  const isWrongNetwork = !mockMode && isConnected && chainId != null && chainId !== config.chainId;

  const envStatusLabel = mockMode ? 'Mock Mode' : missingAddresses.length === 0 ? 'Base Sepolia Configured' : 'Missing Addresses';
  const envStatusClass = mockMode ? 'badge-mock' : missingAddresses.length === 0 ? 'badge-configured' : 'badge-warn';

  const walletStatusLabel = isWrongNetwork ? 'Wrong Network' : isConnected ? 'Wallet Connected' : 'Base Sepolia Configured';
  const walletStatusClass = isWrongNetwork ? 'badge-warn' : isConnected ? 'badge-ok' : 'badge-configured';

  const shortAddress = address ? `${address.slice(0, 6)}...${address.slice(-4)}` : '';

  const handleRegister = async () => {
    if (!name) return;

    if (mockMode) {
      registerAgent(name, owner || (address || ''), metadata || 'ipfs://demo-agent');
      setName('');
      setOwner('');
      setMetadata('');
      return;
    }

    const err = requireRealReady(address, isConnected, chainId, config);
    if (err) {
      setRealStatus(err.message);
      const receipt = createBaseReceipt('registerAgent');
      receipt.status = 'FAILED';
      receipt.reason = errToReceiptReason(err);
      receipt.error = err.message;
      pushRealReceipt(receipt);
      return;
    }

    setRealStatus('Submitting registerAgent...');
    const agentId = bytes32AgentId(address as string, `${Date.now()}`);
    setRealAgentId(agentId);
    const receipt = createBaseReceipt('registerAgent');
    pushRealReceipt(receipt);

    try {
      const hash = await registryWrite.writeContractAsync({
        address: config.agentRegistryAddress as `0x${string}`,
        abi: AIAgentRegistryABI,
        functionName: 'registerAgent',
        args: [agentId, metadata || 'ipfs://demo-agent', weiFromZyx(maxPerTx), weiFromZyx(maxPerDay)],
      });
      receipt.status = 'SUCCESS';
      receipt.txHash = hash;
      receipt.explorerUrl = baseExplorerUrl(hash);
      receipt.reason = undefined;
      setRealStatus(`Registered. AgentId: ${agentId}`);
    } catch (e) {
      receipt.status = 'FAILED';
      receipt.reason = 'user_rejected';
      receipt.error = e instanceof Error ? e.message : 'Transaction failed';
      setRealStatus(`Register failed: ${receipt.error}`);
    }
  };

  const handleUpdatePolicy = async () => {
    if (mockMode) {
      updatePolicy({ maxPerTx, maxPerDay, active: policyActive });
      return;
    }

    if (!realAgentId) {
      setRealStatus('Register an agent first.');
      return;
    }

    const err = requireRealReady(address, isConnected, chainId, config);
    if (err) {
      setRealStatus(err.message);
      const receipt = createBaseReceipt('updatePolicy');
      receipt.status = 'FAILED';
      receipt.reason = errToReceiptReason(err);
      receipt.error = err.message;
      pushRealReceipt(receipt);
      return;
    }

    setRealStatus('Submitting updatePolicy...');
    const receipt = createBaseReceipt('updatePolicy');
    pushRealReceipt(receipt);

    try {
      const hash = await registryWrite.writeContractAsync({
        address: config.agentRegistryAddress as `0x${string}`,
        abi: AIAgentRegistryABI,
        functionName: 'updatePolicy',
        args: [realAgentId as `0x${string}`, weiFromZyx(maxPerTx), weiFromZyx(maxPerDay)],
      });
      receipt.status = 'SUCCESS';
      receipt.txHash = hash;
      receipt.explorerUrl = baseExplorerUrl(hash);
      receipt.reason = undefined;
      setRealStatus('Policy updated on-chain.');
    } catch (e) {
      receipt.status = 'FAILED';
      receipt.reason = 'user_rejected';
      receipt.error = e instanceof Error ? e.message : 'Transaction failed';
      setRealStatus(`Policy update failed: ${receipt.error}`);
    }
  };

  const handleAuthorize = async () => {
    if (!spender) return;

    if (mockMode) {
      setAuthorizedSpender(spender);
      setSpender('');
      return;
    }

    const err = requireRealReady(address, isConnected, chainId, config);
    if (err) {
      setRealStatus(err.message);
      const receipt = createBaseReceipt('setAuthorizedSpender');
      receipt.status = 'FAILED';
      receipt.reason = errToReceiptReason(err);
      receipt.error = err.message;
      pushRealReceipt(receipt);
      setSpender('');
      return;
    }

    setRealStatus('Submitting setAuthorizedSpender...');
    const receipt = createBaseReceipt('setAuthorizedSpender');
    pushRealReceipt(receipt);

    try {
      const hash = await registryWrite.writeContractAsync({
        address: config.agentRegistryAddress as `0x${string}`,
        abi: AIAgentRegistryABI,
        functionName: 'setAuthorizedSpender',
        args: [spender as `0x${string}`, true],
      });
      receipt.status = 'SUCCESS';
      receipt.txHash = hash;
      receipt.explorerUrl = baseExplorerUrl(hash);
      receipt.reason = undefined;
      setSpender('');
      setRealStatus('Authorized spender set on-chain.');
    } catch (e) {
      receipt.status = 'FAILED';
      receipt.reason = 'contract_revert';
      receipt.error = e instanceof Error ? e.message : 'Transaction failed';
      receipt.detail = 'Only owner can call setAuthorizedSpender. Expected in a public demo.';
      setSpender('');
      setRealStatus(`Authorize failed: ${receipt.error}`);
    }
  };

  const handlePayment = async () => {
    if (!paySpender) return;

    if (mockMode) {
      const receipt = simulatePayment(agent, payAmount, payService, paySpender);
      addReceipt(receipt);
      setPayAmount('0.001');
      setPayService('openai-api');
      setPaySpender('');
      return;
    }

    if (!realAgentId) {
      setRealStatus('Register an agent first.');
      return;
    }

    const err = requireRealReady(address, isConnected, chainId, config);
    if (err) {
      setRealStatus(err.message);
      const receipt = createBaseReceipt('checkAndRecordSpend');
      receipt.status = 'FAILED';
      receipt.reason = errToReceiptReason(err);
      receipt.error = err.message;
      pushRealReceipt(receipt);
      return;
    }

    const numAmount = parseFloat(payAmount);
    const maxTx = parseFloat(agent.policy.maxPerTx);
    const maxDay = parseFloat(agent.policy.maxPerDay);

    if (!agent.policy.active) {
      const receipt = createBaseReceipt('checkAndRecordSpend');
      receipt.status = 'FAILED';
      receipt.reason = 'policy_inactive';
      receipt.error = 'Policy inactive.';
      pushRealReceipt(receipt);
      setRealStatus('Payment blocked: policy inactive.');
      return;
    }

    if (paySpender.toLowerCase() !== agent.authorizedSpender.toLowerCase()) {
      const receipt = createBaseReceipt('checkAndRecordSpend');
      receipt.status = 'FAILED';
      receipt.reason = 'unauthorized_spender';
      receipt.error = 'Spender not authorized.';
      pushRealReceipt(receipt);
      setRealStatus('Payment blocked: unauthorized spender.');
      return;
    }

    if (numAmount > maxTx) {
      const receipt = createBaseReceipt('checkAndRecordSpend');
      receipt.status = 'FAILED';
      receipt.reason = 'over_max_per_transaction';
      receipt.error = `Amount ${payAmount} exceeds max per tx ${agent.policy.maxPerTx}.`;
      pushRealReceipt(receipt);
      setRealStatus('Payment blocked: over max per transaction.');
      return;
    }

    if (numAmount > maxDay) {
      const receipt = createBaseReceipt('checkAndRecordSpend');
      receipt.status = 'FAILED';
      receipt.reason = 'over_daily_budget';
      receipt.error = `Amount ${payAmount} exceeds daily budget ${agent.policy.maxPerDay}.`;
      pushRealReceipt(receipt);
      setRealStatus('Payment blocked: over daily budget.');
      return;
    }

    setRealStatus('Submitting checkAndRecordSpend...');
    const receipt = createBaseReceipt('checkAndRecordSpend');
    pushRealReceipt(receipt);

    try {
      const hash = await registryWrite.writeContractAsync({
        address: config.agentRegistryAddress as `0x${string}`,
        abi: AIAgentRegistryABI,
        functionName: 'checkAndRecordSpend',
        args: [realAgentId as `0x${string}`, weiFromZyx(payAmount)],
      });
      receipt.status = 'SUCCESS';
      receipt.txHash = hash;
      receipt.explorerUrl = baseExplorerUrl(hash);
      receipt.reason = undefined;
      setRealStatus('Spend recorded on-chain.');
    } catch (e) {
      receipt.status = 'FAILED';
      receipt.reason = 'user_rejected';
      receipt.error = e instanceof Error ? e.message : 'Transaction failed';
      setRealStatus(`Spend record failed: ${receipt.error}`);
    }
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>Zeusyxa AgentPay Demo</h1>
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
          {missingAddresses.map(([name, a]) => (
            <div key={name}>
              {name}: {a || '<missing>'}
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

      {realStatus && <div className="readout"><strong>Status:</strong> {realStatus}</div>}
      {realAgentId && !mockMode && <div className="readout"><strong>AgentId:</strong> {realAgentId}</div>}

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
          <Field label="Max per transaction (ZYX)" value={maxPerTx} onChange={setMaxPerTx} placeholder="0.01" />
          <Field label="Daily budget (ZYX)" value={maxPerDay} onChange={setMaxPerDay} placeholder="0.05" />
        </div>
        <label className="toggle">
          <input type="checkbox" checked={policyActive} onChange={(e) => setPolicyActive(e.target.checked)} />
          <span>Policy active</span>
        </label>
        <button className="primary" onClick={handleUpdatePolicy}>Save/Update Policy</button>
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
          <Field label="Amount (ZYX)" value={payAmount} onChange={setPayAmount} placeholder="0.001" />
          <Field label="Service name" value={payService} onChange={setPayService} placeholder="openai-api" />
          <Field label="Spender address" value={paySpender} onChange={setPaySpender} placeholder="0x..." />
        </div>
        <button className="primary" onClick={handlePayment}>
          {mockMode ? 'Simulate Payment' : 'Record Spend'}
        </button>
      </Section>

      <Section title="Receipts / History">
        {receipts.length === 0 && realReceipts.length === 0 && <p className="muted">No receipts yet.</p>}
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
            {[...receipts, ...realReceipts].map((r) => {
              const isReal = 'action' in r;
              const agentId = isReal ? realAgentId || '-' : (r as any).agentId;
              const amount = isReal ? '-' : (r as any).amount;
              const service = isReal ? (r as BaseReceipt).action : (r as any).service;
              const status = r.status;
              const txHash = (r as any).txHash || '-';
              const txCell = (r as BaseReceipt).txHash ? (
                <a className="mono" href={(r as BaseReceipt).explorerUrl || `https://sepolia.basescan.org/tx/${(r as BaseReceipt).txHash}`} target="_blank" rel="noreferrer">
                  {(r as BaseReceipt).txHash}
                </a>
              ) : (
                <span className="mono">{txHash}</span>
              );
              const reason = (r as BaseReceipt).error || (r as BaseReceipt).detail || (r as any).reason || '-';
              return (
                <tr key={r.id}>
                  <td>{new Date(r.timestamp).toLocaleString()}</td>
                  <td className="mono">{agentId}</td>
                  <td>{amount}</td>
                  <td>{service}</td>
                  <td><span className={`badge badge-${status.toLowerCase()}`}>{status}</span></td>
                  <td>{txCell}</td>
                  <td>{reason}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </Section>
    </div>
  );
}
