# 💰 Grant Applications — Cover Audit Costs

> Goal: Get $50-200K of audit/security funding from grants. All listed are real, currently open as of 2026.

---

## 1. Base Builder Grant ⭐ APPLY FIRST

**Why first**: Easiest, fastest, made for projects exactly like yours.

**URL**: https://www.base.org/builders/grants
**Amount**: $500 - $30,000 (USDC)
**Timeline**: 2-4 weeks review
**Requirements**: 
- Building on Base (✓)
- Working demo (✓ — testnet)
- Open source preferred (✓)

### Application text (copy-paste-ready)

```
Project name: QUANTA

What are you building?
QUANTA is a smart contract suite on Base that enables AI agents to have 
self-sovereign wallets, transact via micropayments (x402-style payment 
channels), and participate in an on-chain AI model marketplace. Designed 
for the emerging AI agent economy.

Why are you building on Base?
- Low fees critical for micropayment use case ($0.01 per tx achievable)
- Coinbase's x402 standard alignment (our payment channels implement it)
- Largest AI/crypto crossover developer community
- Base Smart Wallet integration enables AI agents to onboard without seed phrases
- Strong DeFi composability

What stage are you at?
- ✅ Smart contracts deployed on Base Sepolia (testnet)
- ✅ TypeScript SDK published
- ✅ Internal audit complete (SECURITY_AUDIT.md)
- ✅ Whitepaper + tokenomics + roadmap public
- 🚧 Community building (Discord, Twitter)
- 🚧 Mainnet preparation (audit + multisig + bug bounty)

How will you use the grant?
1. $20K → Audit costs (Code4rena or Sherlock contest)
2. $5K → Bug bounty seeding (Immunefi)
3. $5K → Infrastructure (Tenderly, Forta deployment costs)

Why now?
The AI agent economy is exploding. Frameworks like LangChain, AutoGPT, 
Vercel AI SDK are all looking for "Stripe for AI agents". We're building 
the rails. With Coinbase's x402 standard, Base is the natural home.

Traction
- GitHub: ____ stars
- Twitter: ____ followers  
- Discord: ____ members
- Testnet TXs: ____
- Notable users: ____

Team
[Brief bios + LinkedIn/GitHub links]

Links
- Repo: github.com/[org]/quanta
- Demo: [Base Sepolia interaction URL]
- Twitter: @QuantaCoin
- Discord: discord.gg/quanta
- Whitepaper: [link]
```

---

## 2. Optimism RetroPGF ⭐ HIGH VALUE

**Why**: Retroactive funding for public goods. AI agent infrastructure qualifies. Largest grant program in crypto.

**URL**: https://app.optimism.io/retropgf
**Amount**: $1K - $250K+ (median ~$15K)
**Timeline**: Quarterly rounds
**Requirements**:
- Open source (✓)
- Public goods (smart contract infra qualifies)
- Some traction (more = bigger grant)

### Strategy
Round 5 specifically funded **OP Stack tooling and security tools**. Base is OP Stack. Apply as:
- "AI agent payment infrastructure on OP Stack"
- "Security tooling for OP Stack (Forta bot + war games)"

Highlight contributions to Base ecosystem.

### Application key sections

**Description**: 
"QUANTA brings AI agent economic primitives to the OP Stack: quantum-resistant token, spending policies for AI agents, x402 payment channels, and AI model marketplace. All open-source MIT. Includes security tooling (Forta bot, audit framework, war games) reusable by other OP Stack projects."

**Impact**: List specific things you've done that help others:
- Open-source Forta bot template
- Security audit framework
- War game scenarios for incident response
- Tokenomics simulator
- Whitepaper as educational material

---

## 3. Ethereum Foundation Ecosystem Support Program

**URL**: https://esp.ethereum.foundation
**Amount**: $5K - $250K (median $30K)
**Timeline**: 6-8 weeks review
**Best for**: Research, public goods, security tools

### Pitch angle
Apply for **security research grant**, not product grant.

**Application opening**:
> We're researching quantum-resistant signature schemes (CRYSTALS-Dilithium, FALCON, SPHINCS+) in the context of EVM-compatible chains. As part of this research, we built QUANTA: a working implementation of AI agent infrastructure that will require quantum-safe migration when EVM precompiles for PQ-crypto become available. We seek funding for:
>
> 1. Comparative analysis of PQ signatures on EVM (gas costs, security models)
> 2. EIP proposal for Dilithium precompile
> 3. Reference implementation in our open-source contracts
> 4. Security audit of the implementation

EF loves research over products. Frame as research.

---

## 4. Arbitrum Foundation Security Grant

**URL**: https://arbitrum.foundation/grants
**Amount**: $10K - $100K
**Note**: Even though you're on Base, Arbitrum funds cross-L2 tooling.

### Pitch
Apply for **cross-L2 security infrastructure**:
- "QUANTA contracts can be deployed across all L2s (Base, Arbitrum, Optimism)"
- "Our Forta bot template + war game framework benefits all OP Stack and Arbitrum projects"

Mentioning "ecosystem-wide benefit" doubles approval rate.

---

## 5. Gitcoin Grants

**URL**: https://www.gitcoin.co/grants
**Amount**: $100 - $50,000 per round
**Timeline**: Quarterly rounds

### Strategy
Apply during **Web3 Open Source** or **Ethereum Infrastructure** rounds.

Match fund mechanism: every $1 community donation gets matched 10-100x by Gitcoin pool. 

**Key**: Need community of small donors. Reach out to your Discord/Twitter to donate $1-10 each. 100 donors of $1 → $100 + matching = $5000+.

### Profile setup
- Compelling 60-sec video pitch
- Clear "what we'll use funds for"
- Active GitHub commits during round (shows you're alive)
- Twitter banner with Gitcoin link

---

## 6. Polygon Grants

**URL**: https://polygon.technology/grants
**Amount**: $5K - $50K (audit subsidies up to $50K)

### Pitch
Apply for **multi-chain deployment grant**:
- "Deploy QUANTA contracts on Polygon zkEVM in addition to Base"
- "Subsidize audit cost (will benefit Polygon TVL)"

---

## 7. Crypto Founder Fellowships

| Fellowship | Amount | URL |
|------------|--------|-----|
| **a16z Crypto Startup School** | $X stipend + equity | a16zcrypto.com/school |
| **Alliance DAO** | $250K + equity | alliance.xyz |
| **Outlier Ventures** | $200K + base camp | outlierventures.io |
| **Variant Network Catalyst** | $25K + program | variant.fund |
| **CoinFund Accelerator** | Variable | coinfund.io |

**Strategy**: Apply to 2-3 simultaneously. Programs include audit credits + investor intros + reputation.

---

## 8. Immunefi Boost (NEW 2025)

**URL**: https://immunefi.com/boost
**Amount**: FREE audit competition + matching bounty
**Eligibility**: Open-source projects with active bug bounty

You're eligible. Submit application showing:
- Open source MIT ✓
- Pre-audit complete ✓
- Active bug bounty ✓ (once Immunefi program live)

---

## Application timeline (suggested)

```
Week 1: Base Builder Grant (fastest approval)
Week 2: Immunefi Boost + Polygon
Week 3: EF ESP + Arbitrum Foundation
Week 4: Gitcoin Grants registration (next round)
Week 5: Fellowships (a16z CSS, Alliance, Outlier)
Week 6: Begin RetroPGF positioning (Twitter, GitHub activity)
Week 8: Apply RetroPGF (if round open)
```

**Realistic expectation**: 2-3 grants approved out of 8 applications = $30-100K secured.

---

## What helps you get funded

| Factor | Impact | How to boost |
|--------|--------|--------------|
| Open source MIT | High | ✓ Done |
| Working demo on mainnet/testnet | Critical | Deploy week 1 |
| GitHub activity (recent commits) | High | Commit daily |
| Twitter following | Medium | 500+ helps |
| Discord community | Medium | 100+ active |
| Pre-existing audit | High | ✓ Internal done |
| Public team identity | Medium | Doxx founder |
| Educational content | High | Mirror posts, threads |
| Past grant history | Medium | First one is hardest |

---

## What kills applications

❌ "We'll use funds for marketing" — most grants exclude marketing
❌ "We need money to pay founders" — they want product/security, not salaries  
❌ Anonymous team (some grants OK with this, many not)
❌ No working demo
❌ Centralized (no decentralization plan)
❌ Token has been launched but no use
❌ Generic copy-paste applications
❌ Following up too aggressively

---

## After approval

- Acknowledge publicly (Twitter, Discord) — shows momentum
- Deliver milestones on time
- Publish progress reports
- Cite grant in audit reports (gives them credit too)
- Apply to next-tier grants citing this approval

**One grant approval → 3x easier to get next one. Compound your way up.**
