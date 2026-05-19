# 🔍 Audit Options — Comparison & Strategy

> Goal: maximize security coverage with limited budget. Recommended strategy uses 2-3 audit methods in parallel.

## Cost vs Coverage Matrix

| Option | Cost | Time | Coverage | Best for |
|--------|------|------|----------|----------|
| **Internal review** (DONE) | $0 | 1 day | ⭐⭐ | First pass, obvious bugs |
| **Slither + Mythril CI** (DONE) | $0 | continuous | ⭐⭐ | Known patterns, regressions |
| **Echidna invariants** (DONE) | $0 | 1-24h CPU | ⭐⭐⭐ | State machine bugs |
| **Halmos formal verification** (DONE) | $0 | 1h CPU | ⭐⭐⭐⭐ (specific props) | Critical invariants |
| **CodeHawks contest** | $5K-30K | 1-2 weeks | ⭐⭐⭐ | Indie / early stage |
| **Sherlock contest** | $30K-100K | 1-2 weeks | ⭐⭐⭐⭐ | Mid-stage, public |
| **Code4rena contest** | $50K-150K | 7-21 days | ⭐⭐⭐⭐ | Public, lots of attention |
| **Cantina / Spearbit** | $40K-120K | 2-4 weeks | ⭐⭐⭐⭐⭐ | High-rep wardens |
| **OpenZeppelin** | $50K-200K | 4-8 weeks | ⭐⭐⭐⭐⭐ | Branded credibility |
| **Trail of Bits** | $75K-300K | 4-12 weeks | ⭐⭐⭐⭐⭐⭐ | Top tier, defi blue chip |
| **Halborn** | $50K-200K | 3-8 weeks | ⭐⭐⭐⭐⭐ | Strong defi reputation |
| **Certora (formal)** | $100K-500K | 8-16 weeks | ⭐⭐⭐⭐⭐⭐ | Mathematical proof |

## 💸 Recommended strategy by budget

### Budget < $5K (bootstrap)
1. Internal review (done)
2. Slither + Mythril CI (done)
3. Echidna locally (done)
4. Halmos (done)
5. Apply for **CodeHawks public contest** (sometimes free via sponsorship)
6. Immunefi bug bounty $5K (post-launch)

**Expected coverage**: Catches 60-70% of bugs. Adequate for testnet + small mainnet beta ($100K TVL cap).

### Budget $20-50K (post-grant)
1. Everything above
2. **Sherlock contest** ($30K) → 100+ wardens
3. Bug bounty $100K on Immunefi
4. Phased TVL cap: $1M

**Expected coverage**: 80-85%. Safe for $1M-10M TVL.

### Budget $100K+ (post-Series A or major grants)
1. Everything above
2. **Trail of Bits OR Halborn** ($75K) full audit
3. **Code4rena public contest** ($100K)
4. Bug bounty $500K-1M
5. Insurance via Nexus Mutual

**Expected coverage**: 92-95%. Suitable for $10M-100M TVL.

### Budget $500K+ (mainnet at scale)
1. Everything above
2. **Two independent firms** in parallel
3. **Certora formal verification** of critical invariants
4. Continuous bug bounty $1M+
5. Insurance: $50M-100M cover

**Expected coverage**: 98%+. Industry-leading.

---

## 🆓 Free / nearly-free audit paths (for early stage)

### 1. Grant programs that include audit

| Program | Includes audit? | Apply at |
|---------|-----------------|----------|
| Ethereum Foundation | Sometimes via partnership | esp.ethereum.foundation |
| Base Builder Grants | Up to $5K credits for OpenZeppelin Defender | paragraph.xyz/@grants |
| Optimism RetroPGF | Reimbursement post-audit | optimism.io/retropgf |
| Polygon Grants | Up to $50K audit subsidy | polygon.technology/grants |
| Arbitrum Foundation | $250K+ available for security | arbitrum.foundation |
| Gitcoin Grants | Community-funded, $1K-50K per round | gitcoin.co |

### 2. Bug bounty platforms (pay only on bug found)

| Platform | Min payout | Best for |
|----------|------------|----------|
| **Immunefi** | $1K | Industry standard, big bounties |
| **HackerOne** | $50 | Cheaper, broader hacker pool |
| **Hats Finance** | Variable | Decentralized, treasury-funded |
| **Cantina** | $5K | Higher-quality whitehats |

### 3. Free static analysis (run yourself)

```bash
# Comprehensive free toolkit
pip install slither-analyzer mythril halmos
docker pull trailofbits/eth-security-toolbox

# In our repo
cd contracts && bash run-security-tools.sh

# Echidna via Docker (no install)
docker run -v $PWD:/src trailofbits/echidna \
  echidna /src/contracts/test-invariant/QuantaTokenInvariants.sol \
  --contract QuantaTokenInvariants

# Halmos
halmos --contract HalmosSpecs
```

### 4. Open source communities

| Community | Helps with |
|-----------|-----------|
| **Secureum** Discord | Free review by aspiring auditors |
| **0xMacro** | Cohort audits (paid) |
| **r/ethdev** | Community code review |
| **DeFiHackLabs** | Past exploit patterns |

---

## 📋 Pre-audit preparation checklist

Before engaging ANY auditor, do these (saves $$$ and improves findings):

- [ ] Code freeze (no changes 1 week before audit start)
- [ ] All tests pass + >90% coverage
- [ ] All Slither warnings addressed or documented
- [ ] All public/external functions have NatSpec
- [ ] README explains protocol in non-expert terms
- [ ] Threat model documented (this doc!)
- [ ] Trust assumptions explicit (who/what is trusted)
- [ ] Known issues disclosed (don't pay auditors to find what you know)
- [ ] Deployment plan documented
- [ ] Upgrade path documented (or "not upgradeable")
- [ ] Multisig setup ready
- [ ] Incident response runbook ready

---

## 🎯 Our recommended path (for QUANTA)

**Month 1-2 (now)**: 
- ✅ All free tools (done)
- 📝 Apply for Base Builder Grant + Ethereum Foundation grant
- 📝 Apply for Code4rena (or Sherlock if cheaper)
- 🪲 Launch Immunefi bug bounty at $10K cap

**Month 3-4**:
- If grants land: Cantina/Spearbit audit ($50K)
- If contest happens: address all findings within 14 days
- Increase Immunefi to $100K

**Month 5-6**:
- Second audit (different firm) on FIX'd version
- Public testnet beta with TVL cap
- Forta detection bots deployed

**Month 7+**:
- Trail of Bits / Halborn final audit
- Phased mainnet rollout
- Immunefi $1M

**Total cost over 6 months**: ~$150-300K
**Without grants**: Boostrap with free tools + 1 contest ($30K) for first 6 months.
