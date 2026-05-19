# Immunefi Bug Bounty Setup — Ready to Configure

> **Goal**: Live bug bounty program for QUANTA, capped initially at $10K to start free/cheap.

---

## Why Immunefi (vs alternatives)

| Platform | Pros | Cons | Best for |
|----------|------|------|----------|
| **Immunefi** | Industry standard, largest hunter pool | 10% platform fee | Established protocols |
| **HackerOne** | Cheaper for small projects | Less crypto-specialized | Bootstrapped |
| **Hats Finance** | Decentralized, can use protocol tokens | Smaller pool | Token-based payments |
| **Cantina** | Higher-quality whitehats | Smaller pool | Post-audit complement |

**Recommendation**: Start with Immunefi at $10K cap → grow to $1M as TVL grows.

---

## Submission via web

URL: https://immunefi.com/bug-bounty-program/

Login/signup with team email, then "Add a project".

---

## Form data (ready to paste)

### Project info

**Project name**: QUANTA
**Project URL**: https://quanta.foundation (or GitHub if no domain yet)
**Project description**:
> QUANTA is a quantum-resistant AI-native blockchain protocol. Smart contracts enable AI agent economic agency: on-chain wallets with spending policies, x402-style micropayments, on-chain AI model marketplace, and ERC-20 token with deflationary burn.

**Technology stack**: Solidity 0.8.24, Foundry, OpenZeppelin
**Languages**: Solidity, TypeScript

### Assets in scope (smart contracts)

| Asset | Type | Chain | Address |
|-------|------|-------|---------|
| QuantaToken | Smart Contract | Base | `0x___YOUR_DEPLOYED_ADDRESS___` |
| AIAgentRegistry | Smart Contract | Base | `0x___YOUR_DEPLOYED_ADDRESS___` |
| AIPaymentChannel | Smart Contract | Base | `0x___YOUR_DEPLOYED_ADDRESS___` |
| AIModelMarketplace | Smart Contract | Base | `0x___YOUR_DEPLOYED_ADDRESS___` |

### Impacts in scope

**Critical** ($5,000 - $10,000):
- Direct theft of any user funds
- Permanent freezing of funds (>24 hours)
- Protocol insolvency
- Insertion of malicious approval/transferFrom paths
- Manipulation of governance voting result
- Theft of unclaimed yield
- Smart contract unable to operate due to lack of token funds
- Permanently locking all multisig signers out

**High** ($2,000 - $5,000):
- Theft of unclaimed yield
- Permanent freezing of unclaimed yield
- Temporary freezing of funds (>1 hour, < 24 hours)
- Theft of bug bounty rewards

**Medium** ($500 - $2,000):
- Smart contract unable to operate due to lack of token funds (recoverable)
- Block stuffing
- Griefing (no profit to attacker, but funds inaccessible)
- Theft of gas
- Unbounded gas consumption

**Low** ($100 - $500):
- Contract fails to deliver promised returns, but doesn't lose value
- Unauthorized access to non-fund functions
- Excessive gas usage

### Out of scope

- Front-end vulnerabilities (separate program)
- DoS or rate-limiting from infrastructure (not contract)
- Known issues in `SECURITY_AUDIT.md`
- Issues only exploitable with privileged access (owner, oracle)
- Theoretical issues without PoC
- Best practice critiques
- Code style issues
- Gas optimizations (use Code4rena gas-optimization contests)
- Issues in dependencies (OpenZeppelin) — report upstream
- Issues requiring access to leaked/lost private keys

### Proof of concept required?

YES for all submissions. Reports must include:
- Working PoC on Base Sepolia fork OR mainnet (Tenderly fork acceptable)
- Step-by-step reproduction
- Suggested fix

### Total bounty pool

Initial: **$10,000 USD** (in QTA, USDC, or ETH at hunter's choice)
Plan to scale:
- $100K within 3 months of mainnet
- $500K within 6 months
- $1M within 12 months (industry standard)

### Funding source
Treasury multisig (Gnosis Safe 3/5)

### Response time SLA
- Acknowledgment: 24 hours
- Triage: 72 hours
- Payment: within 14 days of fix

### Disclosure terms
- Coordinated disclosure (whitehat respects timeline)
- Public disclosure 30 days after fix deployed (with whitehat credit)
- Whitehat may not exploit at scale (single PoC tx only)
- Whitehat agrees not to extort

### Contact info
- **Email**: security@quanta.foundation
- **Discord**: discord.gg/quanta (#security-disclosure private channel)
- **Signal**: ____________
- **PGP**: (publish key on website + here)

---

## After submission

Immunefi reviews (3-7 days) and either:
- ✅ Approves → goes live
- 🔄 Asks for clarifications
- ❌ Rejects (rare, usually due to obvious centralization or scam signals)

Once live:
- Whitehats can submit reports
- You receive notifications via Immunefi dashboard
- Triage in their UI
- Fund payments through Immunefi escrow

---

## Monthly maintenance

- [ ] Review any open reports (acknowledge SLA)
- [ ] Pay bounties promptly
- [ ] Update contract addresses if deploying new versions
- [ ] Scale bounty cap as TVL grows
- [ ] Publish "Hall of Fame" of whitehat contributors

---

## Pro tips

1. **Pay full advertised bounty** — even if you think it's "almost" critical, pay critical. Reputation > $5K.
2. **Respond fast** — top hunters work multiple programs simultaneously. Fast response = they prioritize your program.
3. **Public credit** — ask permission, then publicly thank whitehat. Builds your reputation as a good actor.
4. **Don't dispute severity** — accept Immunefi's classification. Disputing kills trust.
5. **Tier the program** — start small ($10K), scale up as you grow.
6. **"Whitehat retainer"** — invite top hunters to ongoing $500-1000/month retainer for first-look access.
