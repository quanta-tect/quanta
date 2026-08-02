import { useState } from 'react';

export function SimulatePayment({ agent, onResult, mode: _mode }: { agent: any; onResult: (r: any) => void; mode: string }) {
  const [amount, setAmount] = useState('0.01');
  const [service, setService] = useState('openai-gpt4o');
  const [spender, setSpender] = useState('0xMarketplace0000000000000000000000');

  const simulate = () => {
    onResult({
      id: crypto.randomUUID(),
      timestamp: Date.now(),
      agentId: agent.agentId,
      amount: 0n,
      service,
      status: 'success' as const,
      txHash: '0x' + Array.from(crypto.getRandomValues(new Uint8Array(32))).map(b => b.toString(16).padStart(2, '0')).join(''),
    });
  };

  return (
    <div className="card">
      <h2>4. Simulate Agent Payment</h2>
      <div className="row">
        <label>Amount (ETH)</label>
        <input type="number" step="0.001" value={amount} onChange={e => setAmount(e.target.value)} />
      </div>
      <div className="row">
        <label>Service/model</label>
        <input value={service} onChange={e => setService(e.target.value)} />
      </div>
      <div className="row">
        <label>Spender</label>
        <input value={spender} onChange={e => setSpender(e.target.value)} placeholder="0xMarketplace..." />
      </div>
      <button onClick={simulate}>Simulate Payment</button>
    </div>
  );
}
