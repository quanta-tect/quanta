# Sherlock Audit Application — Ready to Submit

> Sherlock = competitive audit + insurance bundle. Cost typically lower than Code4rena.

---

## Submission via web

URL: https://sherlock.xyz/audits/contests/new

---

## Form fields (copy-paste-ready)

### Protocol name
QUANTA

### Protocol description (max 500 chars)
QUANTA is an EVM contract suite for AI agent economic agency: quantum-safe wrapped token (ERC-20 with burn), on-chain AI agent registry with spending policies, x402-style payment channels for micropayments, and AI model marketplace with auto-royalty distribution. Designed for the AI agent economy on Base.

### GitHub repository
https://github.com/quanta-tect/quanta

### Branch/commit for audit
`main` (latest commit hash to be frozen 1 week before contest)

### Contracts in scope
- `contracts/src-v1.1/QuantaToken.sol` (~176 SLoC)
- `contracts/src-v1.1/AIAgentRegistry.sol` (~224 SLoC)
- `contracts/src-v1.1/AIPaymentChannel.sol` (~226 SLoC)
- `contracts/src-v1.1/AIModelMarketplace.sol` (~231 SLoC)
- Total: ~857 SLoC

### Out of scope
- `lib/` (OpenZeppelin and other dependencies)
- `script/`, `test/`, `test-v1.1/`, `test-invariant/`, `test-formal/`
- Legacy `src/` (v1.0 — known issues, see SECURITY_AUDIT.md)
- Off-chain: Python prototype, TypeScript SDK
- Frontend (audited separately)

### Documentation provided
- Whitepaper: docs/WHITEPAPER.md
- Internal audit (30 findings, all fixed): SECURITY_AUDIT.md
- Threat model: docs-security/BRIDGE_SECURITY_REVIEW.md
- Incident response: docs-security/INCIDENT_RESPONSE.md
- NatSpec: 100% public/external functions

### Test coverage
- Unit: 92% lines, 87% branches
- Fuzz: Foundry invariant tests, 100K runs
- Formal: Halmos critical properties

### Trust assumptions
- **Owner** (multisig 3/5, will be 5/9 at scale):
  - Can pause contracts
  - Can update tax rate (bounded ≤1%)
  - Can authorize/revoke tax collectors
  - Can authorize/revoke reputation oracles
  - Can propose bridge changes (48h timelock)
- **Reputation oracles**: trusted to adjust agent reputations bounded [0, 10000]
- **Tax collectors** (Marketplace, Channel): can burn their own balance only

### Known issues (won't pay)
1. Centralization: Owner has significant power. Pre-mainnet we use Gnosis Safe 3/5 with 48h timelock.
2. EVM contracts use ECDSA, not Dilithium. Quantum-safety only on future L1.
3. Agent daily-cap is sliding window, not strict calendar day.
4. Bridge interface is stub — real bridge will use audited infra (LayerZero/Hyperlane).
5. All Critical/High findings from internal audit v1.0 (see SECURITY_AUDIT.md)

### Severity preference
Standard Sherlock severity matrix.

### Prize pool requested
$30,000 (or USD-equivalent in QTA at TGE valuation)

### Audit duration
7 days

### Specific concerns
1. Payment channel state machine: are there any sequences leading to insolvency?
2. Marketplace CEI: any reentrancy paths despite nonReentrant?
3. Bridge timelock: any way to bypass via reentrancy or self-call?
4. Tax burn accounting: any way to burn more than allowed cap?
5. Agent registry: any way to bypass spending policy?

### Founder availability during contest
16 hours/day on Sherlock Discord + GitHub.
Response SLA: 2 hours for clarifications.

### Insurance interest
Yes — interested in Sherlock coverage post-audit.

---

## After acceptance

Sherlock will send:
- Sponsor agreement (review with lawyer)
- Calendar slot (usually 2-3 weeks out)
- Pre-contest checklist (freeze code, finalize scope)
- Marketing kit (Twitter announcement template)

## Pre-contest preparation (1 week before)

- [ ] Freeze code on `main` branch
- [ ] No PRs merged until contest ends
- [ ] Run all security tools one final time
- [ ] Update SECURITY_AUDIT.md with any new findings
- [ ] Prepare answers to top-20 likely questions (FAQ document)
- [ ] Notify community of upcoming audit (builds anticipation)
- [ ] Set up Discord channel #sherlock-audit-questions

## During contest

- Daily standup with team to review submitted findings
- Respond to questions within 2 hours
- Don't reveal hints
- Don't argue severity until end (judges decide)

## After contest

- Receive judge report (within 2 weeks)
- Address each finding (fix code + write tests)
- Submit fixes for re-review
- Pay bounties (Sherlock handles distribution)
- Publish final report on GitHub + Mirror
