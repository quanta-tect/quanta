# 🛡️ QUANTA Wallet UI

> Safe wallet for QUANTA with **transaction simulation** — the #1 defense against frontend hacks and signing-based scams.

## Why simulate transactions?

The Bybit hack ($1.5B in 2025) didn't break smart contracts. It tricked users into signing draining transactions through a compromised UI. **No smart contract security can prevent this** — only client-side simulation can.

### What our wallet shows BEFORE you sign

For every transaction, simulate against live blockchain state and display:

1. **Balance changes** — exactly how much will leave/enter each address
2. **Token approvals** — flag any unlimited spend
3. **Contract risk** — flag contracts not in whitelist
4. **Recipient checks** — flag known scammer addresses (Forta lists)
5. **Gas estimate** — true cost including burn
6. **Slippage** (for swaps) — minimum received

If the wallet shows "$50K will leave your account" and the website said "$50 will leave" → **YOU SEE THE DISCREPANCY BEFORE SIGNING**.

## Architecture

```
User                  Wallet UI                Tenderly API
 │                        │                       │
 │  Initiate send         │                       │
 ├───────────────────────▶│                       │
 │                        │  POST /simulate       │
 │                        ├──────────────────────▶│
 │                        │                       │
 │                        │  Simulation result    │
 │                        │◀──────────────────────┤
 │  Show diff             │                       │
 │◀───────────────────────┤                       │
 │                        │                       │
 │  Confirm/Cancel        │                       │
 ├───────────────────────▶│                       │
 │                        │  Sign + broadcast     │
 │                        │  (hardware wallet)    │
```

## Production stack

In production, this would integrate:

| Service | What it does | Cost |
|---------|--------------|------|
| **Tenderly Simulate API** | True blockchain simulation | Free tier: 100/month |
| **Blowfish** | Phishing detection | Free for users |
| **Pocket Universe** | Approval risk scoring | Free |
| **Forta scam DB** | Known bad addresses | Free |
| **WalletConnect** | Connect to any wallet | Free |
| **Viem** | Ethereum client library | Free |
| **wagmi** | React hooks for wallet | Free |

## Setup (real implementation, not just demo HTML)

```bash
# Create Next.js project
npx create-next-app@latest quanta-wallet --typescript --tailwind --app
cd quanta-wallet

# Install dependencies
npm install viem wagmi @tanstack/react-query connectkit
npm install @tenderly/sdk

# Environment variables
echo "NEXT_PUBLIC_TENDERLY_ACCESS_KEY=..." > .env.local
echo "NEXT_PUBLIC_TENDERLY_PROJECT=..." >> .env.local
echo "NEXT_PUBLIC_WALLETCONNECT_ID=..." >> .env.local

# Run
npm run dev
```

## Key code patterns

### Simulating with Tenderly (real impl)

```typescript
import { Tenderly } from "@tenderly/sdk";

const tenderly = new Tenderly({
  accessKey: process.env.NEXT_PUBLIC_TENDERLY_ACCESS_KEY!,
  accountName: "...",
  projectName: "...",
});

async function simulateTransaction(tx: TransactionRequest) {
  const sim = await tenderly.simulator.simulateTransaction({
    network_id: "8453",
    from: tx.from,
    to: tx.to,
    input: tx.data,
    value: tx.value?.toString() ?? "0",
    save: false,
    save_if_fails: false,
    simulation_type: "full",
  });

  // Extract balance changes, events, errors
  return {
    success: sim.transaction.status,
    balanceChanges: extractBalanceChanges(sim),
    events: sim.transaction.transaction_info?.logs ?? [],
    gasUsed: sim.transaction.gas_used,
    error: sim.transaction.error_message,
  };
}
```

### Detecting unlimited approval scam

```typescript
function detectScams(simResult: SimResult, tx: Tx) {
  const warnings = [];

  // Pattern 1: Unlimited approval
  for (const event of simResult.events) {
    if (event.name === "Approval" &&
        BigInt(event.args.value) === 2n ** 256n - 1n) {
      warnings.push({
        severity: "danger",
        message: `Unlimited spend approval to ${event.args.spender}. ` +
                 `If this contract is malicious, ALL your ${event.args.token} can be drained.`,
      });
    }
  }

  // Pattern 2: Send to known scammer
  const scammers = await fetch("https://api.forta.network/scam-addresses").then(r => r.json());
  if (scammers.includes(tx.to.toLowerCase())) {
    warnings.push({
      severity: "danger",
      message: "Recipient is a known scammer address (Forta DB).",
    });
  }

  // Pattern 3: Suspiciously large balance change
  if (simResult.balanceChanges.some(c => c.diff > parseEther("100000"))) {
    warnings.push({
      severity: "warning",
      message: "Very large balance change. Verify amount carefully.",
    });
  }

  return warnings;
}
```

### Hardware wallet integration

```typescript
import { createWalletClient, custom } from "viem";
import { mainnet } from "viem/chains";

// For Ledger:
import { LedgerHQProvider } from "@ledgerhq/hw-app-eth";

const walletClient = createWalletClient({
  chain: base,
  transport: custom(window.ethereum), // or Ledger provider
});

async function signWithHardware(tx: TransactionRequest) {
  // Hardware wallet displays tx details
  // User physically presses button to approve
  const hash = await walletClient.sendTransaction({
    account: userAddress,
    to: tx.to,
    value: tx.value,
    data: tx.data,
  });
  return hash;
}
```

## Security features checklist

### What this wallet provides
- ✅ Transaction simulation before signing
- ✅ Known scammer detection
- ✅ Unlimited approval warning
- ✅ Balance change preview
- ✅ Hardware wallet support
- ✅ EIP-712 typed data display (decoded, not hex)
- ✅ Multi-sig support (via Safe SDK)
- ✅ Spending policy display for AI agents

### What it does NOT do (intentionally)
- ❌ Custody funds (you keep your keys)
- ❌ Auto-sign anything (always require user)
- ❌ Connect to unauthenticated dapps
- ❌ Allow blind signing (forces decoded display)
- ❌ Share data with us

## Deployment

```bash
# Deploy to Vercel (free tier)
npx vercel

# OR deploy to IPFS (decentralized, no DNS attack surface)
npm run build
npx ipfs-deploy out/
```

**Recommend**: Both. Primary on Vercel, backup on IPFS. If Vercel ever compromised, users have working IPFS version.

## Open-source it

This wallet code should be MIT licensed and open. Why:
1. Users can audit (vs blind trust)
2. Other QUANTA projects can fork
3. Detection rules improve via community PRs
4. Reproducible builds prove no hidden code

## License
MIT
