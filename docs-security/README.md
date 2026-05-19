# 🛡️ QUANTA Security — Complete Documentation

> The most important folder in this repo. Read EVERY file before launching to mainnet.

## 📑 Documents in this folder

| File | Purpose | Read when |
|------|---------|-----------|
| **[BRIDGE_SECURITY_REVIEW.md](./BRIDGE_SECURITY_REVIEW.md)** | 15 bridge attack vectors + mitigations | Before designing any cross-chain functionality |
| **[INCIDENT_RESPONSE.md](./INCIDENT_RESPONSE.md)** | 5-minute → 24h runbook for exploits | Practice quarterly, keep printed copy |
| **[AUDIT_APPLICATION_CODE4RENA.md](./AUDIT_APPLICATION_CODE4RENA.md)** | Template for audit contest applications | When ready for external audit |
| **[AUDIT_OPTIONS_COMPARISON.md](./AUDIT_OPTIONS_COMPARISON.md)** | Compare audit firms by cost/coverage | Budgeting security spend |
| **[forta-detection-bot.js](./forta-detection-bot.js)** | Real-time monitoring bot | Deploy after mainnet launch |

## 📊 Also see at repo root

| File | Purpose |
|------|---------|
| **[../SECURITY.md](../SECURITY.md)** | Public security policy + reporting |
| **[../SECURITY_AUDIT.md](../SECURITY_AUDIT.md)** | Full internal audit (30 findings v1.0 → fixed v1.1) |

## 🧪 Security tooling in `contracts/`

| File | What it does |
|------|--------------|
| `contracts/test-v1.1/SecurityFixes.t.sol` | Regression tests for each finding |
| `contracts/test-invariant/FoundryInvariants.t.sol` | Foundry built-in invariant tests |
| `contracts/test-invariant/*.sol` + `echidna.yaml` | Echidna property tests |
| `contracts/test-formal/HalmosSpecs.t.sol` + `halmos.toml` | Halmos formal verification |
| `contracts/slither.config.json` | Slither configuration |
| `contracts/run-all-security.sh` | One-command full suite |
| `.github/workflows/security.yml` | CI: Slither + Mythril + secret scan |

## 🎯 Security maturity model

Where you are on the journey:

```
Level 0: "It compiles"                                    ⬜
Level 1: Manual review by self                            ⬜
Level 2: Slither/Mythril CI                               ✅ (you are here)
Level 3: Fuzz + invariant tests                           ✅
Level 4: Formal verification of critical props            ✅
Level 5: External audit (1 firm)                          ⬜
Level 6: Multi-firm audits + public contest               ⬜
Level 7: Continuous bug bounty + Forta monitoring         ⬜
Level 8: Insurance + war games + ISO 27001                ⬜
```

Each level catches ~50% of remaining bugs. **You need Level 5+ for mainnet with real value.**

## 💸 Total security investment for mainnet readiness

| Phase | Cost | Time | Bug-catch % |
|-------|------|------|-------------|
| L0-L4 (self) | $0 | 1 month | ~65% |
| L5 (1 audit) | $30-75K | 3 months | ~85% |
| L6 (2 audits + contest) | $100-200K | 4 months | ~93% |
| L7-L8 (full program) | $200-500K/year | ongoing | ~98% |

**For a $10M TVL project**: Spend $100K+ on security. Not optional.
**For a $100M TVL project**: Spend $500K+/year. Cost of doing business.

## 🚦 Pre-mainnet gates (don't skip)

- [ ] All v1.1 security fixes applied
- [ ] Test coverage >95% lines, >90% branches
- [ ] All invariant tests pass at 100K runs
- [ ] Slither: 0 high, 0 medium (or documented FPs)
- [ ] Mythril: 0 findings
- [ ] Halmos: all critical properties proven
- [ ] At least 1 external audit (any firm)
- [ ] All audit findings fixed + re-verified
- [ ] Bug bounty live $100K+ for 30 days
- [ ] Multisig 3/5 minimum (5/9 preferred)
- [ ] Timelock 48h on all admin functions
- [ ] Incident response runbook + on-call schedule
- [ ] Forta detection bot deployed
- [ ] War game exercise completed
- [ ] Insurance pool funded (5% of expected TVL)
- [ ] Public disclosure of all known limitations

## 🔄 Continuous security (post-launch)

| Cadence | Activity |
|---------|----------|
| Every PR | CI: Slither + tests + coverage |
| Weekly | Mythril deep scan |
| Monthly | Review Forta alerts, tune thresholds |
| Quarterly | War game exercise, signer audit |
| Annually | Full re-audit, key rotation |
| On incident | Execute runbook, publish post-mortem |

## 📚 External resources

### Tools (all free)
- [Slither](https://github.com/crytic/slither) — static analysis
- [Mythril](https://github.com/Consensys/mythril) — symbolic execution
- [Echidna](https://github.com/crytic/echidna) — property-based fuzzing
- [Halmos](https://github.com/a16z/halmos) — symbolic testing
- [Forta](https://forta.network) — runtime monitoring
- [Tenderly](https://tenderly.co) — simulation + alerting

### Reading
- [Building Secure Smart Contracts](https://github.com/crytic/building-secure-contracts) — Trail of Bits
- [SWC Registry](https://swcregistry.io) — 140+ vulnerability classes
- [Solidity Patterns](https://github.com/fravoll/solidity-patterns)
- [rekt.news](https://rekt.news) — learn from past exploits
- [DeFi Hacks DB](https://defiyield.app/rekt-database)

### Communities
- [Secureum](https://www.secureum.xyz) — security education
- [r/ethdev](https://reddit.com/r/ethdev)
- [0xMacro Discord](https://0xmacro.com)
- [Code4rena Discord](https://code4rena.com/discord)

## ⚠️ Final word

Security is not a feature you ship and forget. It's a **practice** you do every day.

The projects that survive 5+ years all share one trait: **paranoia disguised as professionalism**.

Be paranoid. Be professional. Ship secure code. Your users are trusting you with their money.

— QUANTA Foundation
