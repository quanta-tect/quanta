import { useState, useEffect } from 'react';
import { useAccount, useConnect, useDisconnect, useSwitchChain, useWriteContract } from 'wagmi';
import { injected } from 'wagmi/connectors';
import { useMockMode, useAgentState, useReceipts, simulatePayment } from './lib/mock';
import { loadConfig } from './lib/config';
import {
  AIAgentRegistryABI,
  createBaseReceipt,
  baseExplorerUrl,
  weiFromQta,
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
  config?: { chainId: number; agentRegistryAddress: string; qtaTokenAddress: string },
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

function friendlyReason(r?: string): string {
  if (!r) return '-';
  const map: Record<string, string> = {
    user_rejected: 'User rejected transaction',
    contract_revert: 'Contract reverted',
    wallet_not_connected: 'Wallet not connected',
    wrong_network: 'Wrong network',
    missing_address: 'Missing contract address',
    unauthorized_spender: 'Spender not authorized',
    policy_inactive: 'Policy inactive',
    over_max_per_transaction: 'Over max per transaction',
    over_daily_budget: 'Over daily budget',
  };
  return map[r] || r;
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

  useEffect(() => {
    if (!mockMode && config.marketplaceAddress && config.marketplaceAddress !== '0x') {
      setSpender(prev => prev || config.marketplaceAddress);
    }
  }, [mockMode, config.marketplaceAddress]);

  const missingAddresses = [
    ['Agent Registry', config.agentRegistryAddress],
    ['Payment Channel', config.paymentChannelAddress],
    ['Marketplace', config.marketplaceAddress],
    ['QTA Token', config.qtaTokenAddress],
  ].filter(([, a]) => !a || a === '0x');

  const isWrongNetwork = !mockMode && isConnected && chainId != null && chainId !== config.chainId;

  const envStatusLabel = mockMode ? 'Mock Mode' : missingAddresses.length === 0 ? 'Base Sepolia Configured' : 'Missing Addresses';
  const envStatusClass = mockMode ? 'badge-mock' : missingAddresses.length === 0 ? 'badge-configured' : 'badge-warn';

  const walletStatusLabel = isWrongNetwork ? 'Wrong Network' : isConnected ? 'Wallet Connected' : 'Wallet Disconnected';
  const walletStatusClass = isWrongNetwork ? 'badge-warn' : isConnected ? 'badge-ok' : 'badge-warn';

  const expectedOwner = (config.ownerAddress || '').toLowerCase();
  const isOwner = isConnected && address ? address.toLowerCase() === expectedOwner : false;

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
        args: [agentId, metadata || 'ipfs://demo-agent', weiFromQta(maxPerTx), weiFromQta(maxPerDay)],
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
        args: [realAgentId as `0x${string}`, weiFromQta(maxPerTx), weiFromQta(maxPerDay)],
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

    if (!isOwner) {
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
      receipt.detail = 'Only owner can call setAuthorizedSpender.';
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
        args: [realAgentId as `0x${string}`, weiFromQta(payAmount)],
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

  const ownerLabel = isOwner ? 'Yes (connected wallet)' : (expectedOwner ? `No (expected ${expectedOwner.slice(0, 6)}...${expectedOwner.slice(-4)})` : 'Unknown');
  const ownerClass = isOwner ? 'badge-ok' : 'badge-warn';

  const contractLinks = [
    ['QuantaToken', config.qtaTokenAddress],
    ['AIAgentRegistry', config.agentRegistryAddress],
    ['AIPaymentChannel', config.paymentChannelAddress],
    ['AIModelMarketplace', config.marketplaceAddress],
  ] as const;

  return (
    <div className="app">
      <header className="app-header">
        <div>
          <h1>Wallet with rules for AI agents</h1>
          <p className="muted">Budgets, permissions, and on-chain receipts</p>
        </div>
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

      {!mockMode && (
        <Section title="Real Mode Status">
          <div className="grid">
            <div className="field">
              <span>Connected wallet</span>
              <div className="readout">{isConnected ? shortAddress : '-'}</div>
            </div>
            <div className="field">
              <span>Expected owner / deployer</span>
              <div className="readout">{expectedOwner ? `${expectedOwner.slice(0, 6)}...${expectedOwner.slice(-4)}` : '-'}</div>
            </div>
            <div className="field">
              <span>Is registry owner</span>
              <div className={`badge ${ownerClass}`}>{ownerLabel}</div>
            </div>
          </div>
          <div className="readout">
            <strong>Contract addresses:</strong>
            <ul className="list">
              {contractLinks.map(([name, addr]) => (
                <li key={name as string}>
                  {name as string}: <span className="mono">{addr || '-'}</span>{' '}
                  {addr && addr !== '0x' ? (
                    <a className="mono" href={`https://sepolia.basescan.org/address/${addr}`} target="_blank" rel="noreferrer">
                      BaseScan
                    </a>
                  ) : null}
                </li>
              ))}
            </ul>
          </div>
        </Section>
      )}

      {!mockMode && missingAddresses.length > 0 && (
        <div className="alert warn">
          <strong>Configuration warning:</strong> set contract addresses in <code>.env.local</code>.<br />
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
          {!mockMode && <span className={`badge ${ownerClass}`}>Owner: {ownerLabel}</span>}
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
          <Field label="Max per transaction (QTA)" value={maxPerTx} onChange={setMaxPerTx} placeholder="0.01" />
          <Field label="Daily budget (QTA)" value={maxPerDay} onChange={setMaxPerDay} placeholder="0.05" />
        </div>
        <label className="toggle">
          <input type="checkbox" checked={policyActive} onChange={(e) => setPolicyActive(e.target.checked)} />
          <span>Policy active</span>
        </label>
        <button className="primary" onClick={handleUpdatePolicy}>Save/Update Policy</button>
      </Section>

      <Section title="Authorized Spender">
        <p className="muted">Only the registry owner can authorize global spenders.</p>
        <div className="grid">
          <Field label="Spender address" value={spender} onChange={setSpender} placeholder="0x..." />
        </div>
        {!mockMode && !isOwner && (
          <div className="alert warn">Only the registry owner can authorize global spenders.</div>
        )}
        <button className="primary" onClick={handleAuthorize} disabled={!mockMode && !isOwner}>Authorize/Update Spender</button>
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
              <th>Action</th>
              <th>Tx</th>
              <th>Status</th>
              <th>Reason</th>
              <th>Source</th>
            </tr>
          </thead>
          <tbody>
            {[...receipts, ...realReceipts].map((r) => {
              const isReal = 'action' in r;
              const action = isReal ? (r as BaseReceipt).action : (r as any).action || 'simulatePayment';
              const status = r.status;
              const txHash = (r as BaseReceipt).txHash;
              const explorerUrl = (r as BaseReceipt).explorerUrl;
              const reason = friendlyReason((r as BaseReceipt).error || (r as BaseReceipt).reason || (r as any).reason);
              const source = (r as any).isMock ? 'Mock' : 'Real';
              const txCell = txHash ? (
                <a className="mono" href={explorerUrl || `https://sepolia.basescan.org/tx/${txHash}`} target="_blank" rel="noreferrer">
                  {txHash}
                </a>
              ) : (
                <span className="mono">-</span>
              );
              return (
                <tr key={r.id}>
                  <td>{new Date(r.timestamp).toLocaleString()}</td>
                  <td className="mono">{action}</td>
                  <td>{txCell}</td>
                  <td><span className={`badge badge-${status.toLowerCase()}`}>{status}</span></td>
                  <td>{reason}</td>
                  <td><span className={`badge badge-${source === 'Mock' ? 'mock' : 'configured'}`}>{source}</span></td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </Section>
    </div>
  );
}
