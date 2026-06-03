# Code4rena Audit Application — Ready to Submit

> **Status**: TEMPLATE FILLED — review + customize bracketed items, then submit at code4rena.com/sponsors

---

## Submission email

**To**: sponsors@code4rena.com
**Subject**: QUANTA — Audit Contest Inquiry — Quantum-safe AI-native protocol

---

## Email body

Hi Code4rena team,

I'm reaching out about hosting an audit contest for QUANTA, an EVM contract suite designed for AI agent economic agency on Base.

**Quick facts:**
- 4 contracts, ~860 SLoC total (manageable scope)
- Pure Solidity 0.8.24, no proxies, no upgradeability
- Open source MIT from day 1: https://github.com/quanta-tect/quanta
- Pre-audit complete: 30 internal findings already fixed (see SECURITY_AUDIT.md)
- Foundry-based: tests, fuzz, invariants, Halmos all included
- Documentation: whitepaper, NatSpec, threat model, incident runbook

**Why C4 specifically:**
We chose C4 over single-firm audits because:
1. AI agent primitives are novel → need breadth of perspectives
2. We want public visibility for community trust
3. We've prepared the codebase to maximize warden ROI (good docs = good findings)

**Budget**: $50,000 USD prize pool (flexible based on contest length/scope discussion)
**Timeline**: Flexible. Ideally 7-day contest in July 2026

**Available materials for diligence:**
- GitHub repo (link above)
- Whitepaper: https://github.com/quanta-tect/quanta
- Internal audit: SECURITY_AUDIT.md
- Demo on Base Sepolia: https://github.com/quanta-tect/quanta

Can we schedule a 30-min intro call?

Best,
QUANTA Foundation
Founder, QUANTA Foundation
team@quanta.network | @Quanta_Protocol | @quanta_protocol

---

## Pre-call preparation checklist

- [ ] Repo is clean (no WIP branches in main)
- [ ] README links to all key documents
- [ ] Tests pass: `forge test` shows green
- [ ] Coverage > 90%: `forge coverage`
- [ ] SECURITY_AUDIT.md is up to date
- [ ] Known issues clearly documented
- [ ] Whitepaper is current with code
- [ ] You can deploy fresh testnet in <10 min (will be asked)

## What C4 will ask on the call

1. **Scope**: which exact files? LoC count? (Have ready)
2. **Trust model**: who's trusted? What can owner do? (Reference threat model)
3. **Known issues**: list (so wardens don't waste time)
4. **Severity**: how do you classify? (Use C4 standard)
5. **Budget**: minimum $40K, sweet spot $50-100K
6. **Timeline**: 5-day, 7-day, or 14-day contest
7. **Engagement**: will you be available on Discord during contest?

## After the call

C4 sends you:
- Standard sponsor agreement
- Audit prep checklist
- Calendar slot (usually 2-4 weeks out)
- Initial scoping doc to refine

## Funding sources to help cover $50K

If you don't have $50K cash:

1. **Optimism RetroPGF**: reimburses up to $50K for audits of OP Stack apps (Base = OP Stack ✓)
2. **Base Builder Grant**: up to $5K credits
3. **Arbitrum DAO grants**: even though you're on Base, sometimes cross-fund security
4. **Ethereum Foundation Ecosystem Support**: small grants for audits of public goods
5. **Public crowdfunding**: Gitcoin Grants quarterly rounds
6. **Token-paid**: C4 accepts payment in protocol tokens (QTA) at agreed valuation

**Practical reality**: Many post-revenue projects pay $50-150K from treasury for audits. It's a normal cost of operating.

## Alternative: Apply for FREE/SUBSIDIZED contest

**Sherlock "Watson contest"** (cheaper):
- Cost: $30K minimum
- Similar quality to C4
- Apply: sherlock.xyz

**CodeHawks**:
- Cost: $5-25K
- Smaller wardens pool but cheaper
- Apply: codehawks.cyfrin.io

**Cantina (Spearbit-affiliated)**:
- Cost: $40-120K
- Top-tier wardens
- Apply: cantina.xyz

**Immunefi Boost** (NEW 2025):
- Free contest with proceeds from bug bounties
- Apply: immunefi.com
