import type { Receipt } from '../app/types.js';

export function ReceiptsHistory({ receipts }: { receipts: Receipt[] }) {
  if (!receipts.length) return <div className="card"><h2>5. Receipts / History</h2><p style={{ fontSize: 13, color: '#6b7280' }}>No receipts yet.</p></div>;

  return (
    <div className="card">
      <h2>5. Receipts / History</h2>
      <table>
        <thead>
          <tr>
            <th>Time</th>
            <th>Agent</th>
            <th>Amount</th>
            <th>Service</th>
            <th>Status</th>
            <th>Tx / Reason</th>
          </tr>
        </thead>
        <tbody>
          {receipts.slice().reverse().map(r => (
            <tr key={r.id}>
              <td>{new Date(r.timestamp).toLocaleTimeString()}</td>
              <td style={{ maxWidth: 140, overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.agentId.slice(0, 10)}...</td>
              <td>{r.amount ? r.amount.toString() : '-'}</td>
              <td>{r.service}</td>
              <td>
                <span className={`badge ${r.status === 'success' ? 'badge-success' : 'badge-error'}`}>{r.status}</span>
              </td>
              <td style={{ maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.status === 'success' ? (r.txHash?.slice(0, 18) + '...') : r.reason}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
