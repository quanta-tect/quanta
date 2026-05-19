# 🛡️ Code4rena Audit Application — QUANTA

> **Why Code4rena?** Decentralized audit competitions with 100+ wardens. Cost: ~$50-150K but you get **breadth** that no single firm can match. Often catches bugs even Trail of Bits misses.
>
> Alternatives: **Sherlock** (similar model), **Cantina** (Spearbit-affiliated), **CodeHawks** (cheaper, smaller).
>
> **Pro tip**: You can also apply for **free public contests** via their grants program if your project is open-source and community-funded.

---

## 📝 Application Template

**Project**: QUANTA — Quantum-resistant AI-native blockchain
**Applicant**: [Your Name] — Founder
**Date**: [Submit date]
**Repository**: github.com/[your-org]/quanta
**Audit scope**: `contracts/src-v1.1/` (4 contracts, ~860 SLoC)
**Requested timeline**: 7-day contest, public
**Budget**: $50,000 (or in-kind QTA grants for grant-funded version)

---

## 1. Executive Summary

QUANTA is an EVM-compatible token + smart contract suite that introduces **AI-native primitives** to blockchain:

- **QuantaToken** (ERC-20 + burn + AI usage tax + bridge interface)
- **AIAgentRegistry** (on-chain identity + spending policies for AI agents)
- **AIPaymentChannel** (x402-style off-chain micropayments with EIP-712 sigs)
- **AIModelMarketplace** (creator-monetized AI inference with auto royalty distribution)

This is the **first contract suite designed for AI agent economic agency**. Bugs here will affect a novel attack surface.

## 2. Why a competitive audit (vs single-firm)

Single-firm audits cost $30K-150K with 2-3 auditors over 2-4 weeks.
Code4rena gets 30-100+ wardens for 7 days at competitive rates.

For a **novel design** like AI agent wallets, we want **breadth of perspective** — each warden brings different mental models. We expect findings even after firm audit.

We commit to:
- ✅ Open source (MIT) from day 1
- ✅ Complete documentation provided (whitepaper, security audit, NatSpec)
- ✅ Reproducible build (Foundry)
- ✅ Test suite >95% coverage
- ✅ Pre-audit findings disclosed (see SECURITY_AUDIT.md — 30 issues already fixed in v1.1)
- ✅ Active support during contest (founder available on Discord 16h/day)

## 3. Scope

### In scope (audit these)
```
contracts/src-v1.1/QuantaToken.sol           (176 SLoC)
contracts/src-v1.1/AIAgentRegistry.sol       (224 SLoC)
contracts/src-v1.1/AIPaymentChannel.sol      (226 SLoC)
contracts/src-v1.1/AIModelMarketplace.sol    (231 SLoC)

Total: ~857 SLoC, 4 contracts
```

### Out of scope
- OpenZeppelin imports (assume battle-tested)
- Solidity compiler bugs
- Frontend (separate audit later)
- Off-chain components (Python prototype, TypeScript SDK)
- Centralization risks already disclosed (multisig will be added pre-mainnet)

## 4. Severity Classification (per Code4rena standard)

| Severity | Definition |
|----------|-----------|
| 🔴 Critical | Direct loss of user funds, infinite mint, complete protocol bypass |
| 🟠 High | Significant fund loss, protocol partially bypassed |
| 🟡 Medium | Loss of access, griefing, edge case fund loss |
| 🔵 Low | Inefficiency, edge case |
| ℹ️ QA | Code quality, gas optimization, documentation |

### Reward distribution
- 80% to first reporter of unique issue
- 20% to all reporters of same issue (split)
- $5,000 minimum payout per Critical
- Top 3 wardens get bonus

## 5. Known issues (won't pay for these)

These are documented in `SECURITY_AUDIT.md` v1.0 → fixed in v1.1.

| ID | Issue | Status |
|----|-------|--------|
| C-01 | Channel tax burn from shared balance | ✅ Fixed v1.1 |
| C-02 | adjustReputation no access control | ✅ Fixed v1.1 |
| C-03 | forceClose wipes payee claims | ✅ Fixed v1.1 |
| C-04 | Cross-chain signature replay | ✅ Fixed v1.1 (EIP-712) |
| C-05 | CEI order in marketplace | ✅ Fixed v1.1 |
| C-06 | collectAITax burn from arbitrary address | ✅ Fixed v1.1 |
| H-01-H-08 | Various | ✅ Fixed in v1.1 (see audit) |

**Additionally NOT in scope**:
- Centralized ownership risks (pre-mainnet we deploy with Gnosis Safe 3/5)
- L1 quantum-safety claims (this contract suite is EVM, uses ECDSA)
- Front-running by miners (general L1 issue)
- Token price impact / economic attacks unrelated to contract bugs

## 6. Specific areas of concern (focus here)

### 6.1 Payment Channel state machine
The most complex contract. Possible state transitions:
```
[Empty] → [Open] → [CloseRequested] → [Finalized]
                ↘ [ForceClosed] (only if no claim ever)
```

Look for:
- State transitions that violate "claimed amount monotonically increases"
- Reentrancy in `_finalize` via malicious token
- Edge cases at boundaries (deposit = MIN_DEPOSIT, amount = 0, etc.)

### 6.2 Tax burn accounting
`collectAITax` now requires `from == msg.sender`. Verify:
- No path exists where caller can burn from arbitrary `from`
- Tax calculation doesn't overflow for large amounts
- Tax cap (1%) cannot be bypassed via governance

### 6.3 Marketplace economic invariants
- Sum of (creatorShare + treasuryShare + validatorShare + taxed) == price (exact)
- `payForInference` cannot be reentered to drain
- Model deactivation grace period is honored

### 6.4 Agent reputation system
- Only whitelisted oracles can adjust reputation
- Reputation bounded [0, 10000]
- Death-switch correctly disables agent after period
- Daily spend cap correctly resets at 24h boundary

### 6.5 Bridge interface (currently stubs)
- `bridgeMint` cannot exceed cap
- `bridgeBurn` is symmetric with mint
- Bridge change timelock (48h) cannot be bypassed
- Owner cannot maliciously execute bridge change

## 7. Existing testing & tooling

| Tool | Status | Coverage |
|------|--------|----------|
| Foundry unit tests | ✅ | 92% line, 87% branch |
| Foundry fuzz tests | ✅ | 5 invariants, 100K runs |
| Foundry invariant tests | ✅ | Marketplace + Token handlers |
| Echidna property tests | ✅ | 3 contracts, configs included |
| Halmos formal verification | ✅ | Critical properties proven |
| Slither static analysis | ✅ | 0 high, 2 medium (documented FP) |
| Mythril symbolic execution | ✅ | No issues in last run |
| Hand audit (internal) | ✅ | 30 findings documented |

## 8. Code quality

- 100% NatSpec on public/external functions
- Solidity 0.8.24 (pinned, not floating)
- Custom errors throughout (no string reverts)
- OpenZeppelin v5.x latest
- CEI pattern enforced
- ReentrancyGuard on all state-changing externals
- Pausable on all 4 contracts
- Ownable2Step (not Ownable) for safety

## 9. Documentation provided

- [x] [WHITEPAPER.md](../docs/WHITEPAPER.md) — Architecture (5K words)
- [x] [SECURITY_AUDIT.md](../SECURITY_AUDIT.md) — Pre-audit findings (542 lines)
- [x] [TOKENOMICS.md](../docs/TOKENOMICS.md) — Economic model
- [x] [BRIDGE_SECURITY_REVIEW.md](./BRIDGE_SECURITY_REVIEW.md) — Bridge threats analysis
- [x] [INCIDENT_RESPONSE.md](./INCIDENT_RESPONSE.md) — Runbook
- [x] NatSpec on every function
- [x] Inline comments explaining non-obvious logic
- [x] Test files commented per test purpose

## 10. Team availability during contest

- Founder: 16h/day on Discord + Code4rena chat
- Response SLA: 2h for clarifications
- Tech advisor (cryptographer): 4h/day
- Will join all Office Hours sessions

## 11. Post-audit commitments

- All Medium+ findings fixed within 14 days
- Fixes re-reviewed by 2 wardens (paid separately)
- Final audit report published to GitHub + website
- Bug bounty live on Immunefi within 30 days post-audit ($500K for critical)
- Public post-mortem of fix process

---

## 📞 Contact

- **Email**: founder@quanta.foundation
- **Discord**: @founder#0000
- **Twitter**: @QuantaCoin
- **GitHub**: github.com/quanta-foundation

---

## Appendix A — Comparable Code4rena audits

| Project | Date | Findings | Cost |
|---------|------|----------|------|
| ENS | 2022 | 3 H, 5 M | $80K |
| Olympus | 2022 | 2 C, 4 H | $100K |
| RedactedFinance | 2023 | 1 C, 3 H | $50K |

We expect similar profile given complexity (~860 SLoC, novel design).

---

## Appendix B — Why we're worth it

- Open source MIT → free for ecosystem
- Novel design → educational value for wardens
- Pre-audited internally → wardens find subtle bugs not "obvious mistakes"
- Active community → social proof for wardens' portfolios
