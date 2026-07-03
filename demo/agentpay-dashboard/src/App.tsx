import { useState, useMemo } from "react";
import { createAgent, simulatePayment } from "./lib/mock";
import "./App.css";

function fmtWei(wei: bigint): string {
  const eth = Number(wei) / 1e18;
  return `${eth.toFixed(4)} ETH`;
}

function timeAgo(ts: number): string {
  const diff = Math.floor((Date.now() - ts) / 1000);
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  return `${Math.floor(diff / 3600)}h ago`;
}

export default function App() {
  const [agents, setAgents] = useState<ReturnType<typeof createAgent>[]>([]);
  const [selectedAgentId, setSelectedAgentId] = useState<string>("");
  const [receipts, setReceipts] = useState<any[]>([]);
  const [authorizedSpenders, setAuthorizedSpenders] = useState<Set<string>>(
    new Set(),
  );

  // Form state
  const [owner, setOwner] = useState("0xOwner1");
  const [wallet, setWallet] = useState("0xWallet1");
  const [agentName, setAgentName] = useState("");
  const [metadata, setMetadata] = useState("ipfs://bafy.../agent-card.json");
  const [maxPerTx, setMaxPerTx] = useState("0.1");
  const [maxPerDay, setMaxPerDay] = useState("1");
  const [policyActive, setPolicyActive] = useState(true);
  const [spenderAddr, setSpenderAddr] = useState("");
  const [payAmount, setPayAmount] = useState("0.01");
  const [serviceName, setServiceName] = useState("openai-gpt4");
  const [caller, setCaller] = useState(wallet);

  const selectedAgent = useMemo(
    () => agents.find((a) => a.agentId === selectedAgentId),
    [agents, selectedAgentId],
  );

  async function handleRegister(e: React.FormEvent) {
    e.preventDefault();
    if (!agentName.trim()) return;
    const a = createAgent({
      owner,
      wallet,
      name: agentName.trim(),
      metadataURI: metadata || "",
    });
    a.policy.maxPerTx = parseFloat(maxPerTx) * 1e18 ? (BigInt(Math.floor(parseFloat(maxPerTx) * 1e18))) : 0n;
    a.policy.maxPerDay = parseFloat(maxPerDay) * 1e18 ? (BigInt(Math.floor(parseFloat(maxPerDay) * 1e18))) : 0n;
    a.policy.active = policyActive;
    setAgents((prev) => [...prev, a]);
    setSelectedAgentId(a.agentId);
    setAgentName("");
  }

  function handleAuthorize() {
    if (!spenderAddr.trim()) return;
    setAuthorizedSpenders((prev) => {
      const next = new Set(prev);
      next.add(spenderAddr.trim());
      return next;
    });
    setSpenderAddr("");
  }

  function handleRevoke() {
    if (!spenderAddr.trim()) return;
    setAuthorizedSpenders((prev) => {
      const next = new Set(prev);
      next.delete(spenderAddr.trim());
      return next;
    });
    setSpenderAddr("");
  }

  function handleSimulatePayment(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedAgent) return;
    const amountWei = parseFloat(payAmount) * 1e18 ? (BigInt(Math.floor(parseFloat(payAmount) * 1e18))) : 0n;
    const result = simulatePayment(selectedAgent, amountWei, serviceName, caller);
    setReceipts((prev) => [result, ...prev]);
    setSelectedAgentId((id) => {
      const updated = agents.find((a) => a.agentId === id);
      if (updated) {
        // sync state
        setAgents((prev) =>
          prev.map((a) => (a.agentId === id ? updated : a)),
        );
      }
      return id;
    });
  }

  function handleDeactivate() {
    if (!selectedAgent) return;
    setAgents((prev) =>
      prev.map((a) =>
        a.agentId === selectedAgentId ? { ...a, active: false, policy: { ...a.policy, active: false } } : a,
      ),
    );
  }

  function getFailLabel(reason?: string) {
    switch (reason) {
      case "unauthorized_spender":
        return "Unauthorized spender";
      case "over_max_tx":
        return "Over max per transaction";
      case "over_daily_budget":
        return "Over daily budget";
      case "policy_inactive":
        return "Policy inactive / agent deactivated";
      default:
        return reason || "Unknown";
    }
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>⚛️ QUANTA AgentPay Demo</h1>
        <p>
          Give an AI agent a wallet, a spending policy, and a payment receipt.
        </p>
        <div className="badge">Mock / Local Mode</div>
      </header>

      <main className="grid">
        <section className="card">
          <h2>1. Agent Setup</h2>
          <form onSubmit={handleRegister} className="form">
            <label>
              Owner address
              <input value={owner} onChange={(e) => setOwner(e.target.value)} />
            </label>
            <label>
              Agent wallet
              <input value={wallet} onChange={(e) => setWallet(e.target.value)} />
            </label>
            <label>
              Agent name
              <input
                value={agentName}
                onChange={(e) => setAgentName(e.target.value)}
                placeholder="ResearchBot"
              />
            </label>
            <label>
              Metadata URI
              <input
                value={metadata}
                onChange={(e) => setMetadata(e.target.value)}
              />
            </label>
            <button type="submit">Create / Register Agent</button>
          </form>

          <div className="list">
            <strong>Registered agents:</strong>
            {agents.length === 0 && <span className="muted">None yet</span>}
            {agents.map((a) => (
              <div
                key={a.agentId}
                className={`item ${selectedAgentId === a.agentId ? "selected" : ""}`}
              >
                <div>
                  <div>{a.name}</div>
                  <div className="muted">
                    {a.agentId.slice(0, 10)}...
                  </div>
                </div>
                <div>
                  <span className={`pill ${a.active ? "green" : "red"}`}>
                    {a.active ? "active" : "inactive"}
                  </span>
                </div>
                <button onClick={() => setSelectedAgentId(a.agentId)}>
                  Select
                </button>
              </div>
            ))}
          </div>
        </section>

        <section className="card">
          <h2>2. Spending Policy</h2>
          {selectedAgent ? (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                setAgents((prev) =>
                  prev.map((a) =>
                    a.agentId === selectedAgentId
                      ? {
                          ...a,
                          policy: {
                            ...a.policy,
                            maxPerTx: BigInt(Math.floor(parseFloat(maxPerTx) * 1e18)),
                            maxPerDay: BigInt(Math.floor(parseFloat(maxPerDay) * 1e18)),
                            active: policyActive,
                          },
                        }
                      : a,
                  ),
                );
              }}
              className="form"
            >
              <label>
                Max per tx (ETH)
                <input
                  type="number"
                  step="0.001"
                  value={(Number(selectedAgent.policy.maxPerTx) / 1e18).toFixed(4)}
                  onChange={(e) => setMaxPerTx(e.target.value)}
                />
              </label>
              <label>
                Max per day (ETH)
                <input
                  type="number"
                  step="0.01"
                  value={(Number(selectedAgent.policy.maxPerDay) / 1e18).toFixed(4)}
                  onChange={(e) => setMaxPerDay(e.target.value)}
                />
              </label>
              <label className="toggle">
                <input
                  type="checkbox"
                  checked={policyActive}
                  onChange={(e) => setPolicyActive(e.target.checked)}
                />
                Policy active
              </label>
              <button type="submit">Save / Update Policy</button>
              <button
                type="button"
                onClick={handleDeactivate}
                className="danger"
              >
                Deactivate Agent
              </button>
            </form>
          ) : (
            <p className="muted">Select an agent first.</p>
          )}
        </section>

        <section className="card">
          <h2>3. Authorized Spender</h2>
          <div className="form inline">
            <label>
              Spender address
              <input
                value={spenderAddr}
                onChange={(e) => setSpenderAddr(e.target.value)}
                placeholder="0x..."
              />
            </label>
            <div className="actions">
              <button type="button" onClick={handleAuthorize}>
                Authorize
              </button>
              <button type="button" onClick={handleRevoke} className="secondary">
                Revoke
              </button>
            </div>
          </div>
          <div className="list">
            <strong>Authorized spenders:</strong>
            {Array.from(authorizedSpenders).length === 0 && (
              <span className="muted">None yet</span>
            )}
            {Array.from(authorizedSpenders).map((s) => (
              <div key={s} className="item">
                <span>{s}</span>
              </div>
            ))}
          </div>
        </section>

        <section className="card">
          <h2>4. Simulate Agent Payment</h2>
          {selectedAgent ? (
            <form onSubmit={handleSimulatePayment} className="form">
              <label>
                Agent
                <input value={selectedAgent.name} readOnly />
              </label>
              <label>
                Amount (ETH)
                <input
                  type="number"
                  step="0.001"
                  value={payAmount}
                  onChange={(e) => setPayAmount(e.target.value)}
                />
              </label>
              <label>
                Service / model / API name
                <input
                  value={serviceName}
                  onChange={(e) => setServiceName(e.target.value)}
                />
              </label>
              <label>
                Caller address
                <input value={caller} onChange={(e) => setCaller(e.target.value)} />
              </label>
              <button type="submit">Simulate Payment</button>
            </form>
          ) : (
            <p className="muted">Select an agent first.</p>
          )}
        </section>

        <section className="card">
          <h2>5. Receipts / History</h2>
          {receipts.length === 0 && (
            <p className="muted">No payments yet.</p>
          )}
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Agent</th>
                  <th>Amount</th>
                  <th>Service</th>
                  <th>Status</th>
                  <th>Reason / Tx</th>
                </tr>
              </thead>
              <tbody>
                {receipts.map((r) => (
                  <tr key={r.id}>
                    <td>{timeAgo(r.timestamp)}</td>
                    <td>{r.agentName}</td>
                    <td>{fmtWei(r.amount)}</td>
                    <td>{r.service}</td>
                    <td>
                      <span className={`pill ${r.status === "success" ? "green" : "red"}`}>
                        {r.status}
                      </span>
                    </td>
                    <td>
                      {r.reason
                        ? getFailLabel(r.reason)
                        : r.txHash?.slice(0, 10) + "..."}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </main>

      <footer className="app-footer">
        <p>
          Base Sepolia config: edit <code>.env</code> and enable real mode.
          See <code>.env.example</code>.
        </p>
      </footer>
    </div>
  );
}
