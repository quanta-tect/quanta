# 🚨 QUANTA Incident Response Runbook

> **THIS IS THE MOST IMPORTANT DOCUMENT IN THE REPO.**
>
> When a critical bug is being actively exploited, **every minute = $X lost**. Average DeFi exploit drains 80% of TVL in **first 47 minutes**. You don't have time to think — you need to **execute this runbook**.

---

## 📞 First 5 minutes — TRIAGE

### Who's on call?
Maintain a `oncall.md` file with:
```
Week of [date]: PrimaryName (+phone, Telegram, Signal)
Backup: SecondName (+phone)
Escalation: FounderName (+phone, always reachable)
```

### Step 1: Confirm it's real (60 sec)
- [ ] Open Tenderly dashboard → check recent txs for anomaly
- [ ] Open Etherscan/Basescan → look at contract event log
- [ ] Check Forta alerts (forta.network/alerts)
- [ ] Check Discord #alerts channel
- [ ] **DO NOT PANIC** — false alarms happen

### Step 2: Classify severity (60 sec)

| Class | Definition | Action |
|-------|-----------|--------|
| 🔴 **P0** | Funds being actively drained, OR critical bug being exploited | PAUSE IMMEDIATELY |
| 🟠 **P1** | Vulnerability discovered, NOT yet exploited | Coordinate disclosure |
| 🟡 **P2** | Suspicious activity, unconfirmed | Monitor + investigate |
| 🟢 **P3** | False alarm | Document + adjust alerts |

### Step 3: For P0 — PAUSE NOW (3 min)

If pause multisig is set up:
1. Open Gnosis Safe at safe.global
2. Connect with your hardware wallet (1 of N signers)
3. Propose `pause()` transaction on affected contract
4. Ping other signers via Telegram #emergency channel
5. **Need 1 of N for pause (emergency mode), N/M for unpause**

```solidity
// Pre-loaded calldata for emergency pause:
// QuantaToken: 0x8456cb59
// AIPaymentChannel: 0x8456cb59
// AIModelMarketplace: 0x8456cb59
// AIAgentRegistry: (no pause, doesn't hold funds)
```

**While waiting for signatures**: post to Twitter/Discord:
> 🚨 We're investigating a potential issue with QUANTA contracts. We're pausing as a precaution. Funds are safe / we are working to confirm. Updates every 15 min.

---

## 📋 The Next 60 Minutes — DAMAGE CONTROL

### T+05 to T+15 — Verify pause worked
- [ ] Confirm `paused()` returns true on all affected contracts
- [ ] Confirm tx attempts now revert
- [ ] Take screenshots of pause tx for record

### T+15 to T+30 — Forensics
- [ ] Identify attacker address(es)
- [ ] Quantify loss (in USD + tokens)
- [ ] Identify attack vector (which function? which contract?)
- [ ] Check if exploit is reusable on other deployments
- [ ] Notify other chains if multi-chain

**Tools**:
- Tenderly: simulate the exploit tx to understand it
- Phalcon Explorer (phalcon.xyz): tx visualization
- DeFiLlama Hacks dashboard: similar past exploits

### T+30 to T+45 — Communication

#### Public statement template
```
🚨 INCIDENT UPDATE [TIME UTC]

WHAT HAPPENED:
At [TIME UTC], we detected [BRIEF DESCRIPTION]. We immediately paused 
[CONTRACT NAME] to prevent further impact.

CURRENT STATUS:
- Contract paused: ✅
- Funds at risk: [AMOUNT] in [CONTRACT]
- Funds confirmed safe: [AMOUNT] in [CONTRACT]
- Investigation: In progress

WHAT WE'RE DOING:
[Action items]

WHAT YOU SHOULD DO:
- DO NOT interact with [CONTRACT] until further notice
- DO NOT trust any DM offering "recovery services" — those are SCAMS
- Follow @QuantaCoin for updates every 30 min

NEXT UPDATE: [TIME UTC + 30 min]
```

#### Post on:
- [ ] Twitter (pinned)
- [ ] Discord #announcements (with @everyone)
- [ ] Telegram channel
- [ ] Mirror.xyz (longer form)
- [ ] Email blast to known users
- [ ] Email to: CertiK, PeckShield, Forta (industry notification)

### T+45 to T+60 — Mitigation decision

**Decision tree**:

```
Is the exploit ongoing?
├── YES → Keep paused. Begin code fix. Skip to "Recovery" section.
└── NO → Was it a one-time event?
    ├── YES → Assess if pause still needed. Maybe unpause with monitoring.
    └── NO → Could it recur? If yes, stay paused until patched.
```

---

## 🛠️ Recovery (Hours 1-24)

### Option A: Patch & redeploy (most common)

1. **Fork main branch** → `incident-YYYY-MM-DD`
2. **Write the fix** (smallest possible diff)
3. **Write tests proving fix** (regression test for this exact exploit)
4. **Internal review** (at least 2 engineers)
5. **Quick external review** (page audit firm hotline if you have one)
6. **Deploy new contract**
7. **Migrate state** (if needed):
   - Snapshot pre-exploit state from block N-1
   - Deploy new contract
   - Restore balances via merkle airdrop or manual mapping
8. **Update frontend** to use new addresses
9. **Test on testnet first** (even in emergency, 1 hour testnet = save 10 hours pain)
10. **Announce migration plan**

### Option B: Hot fix via upgrade (if proxy)

If contracts are upgradeable:
1. Write minimum-diff fix
2. Go through normal multisig + timelock IF possible
3. If true emergency: emergency upgrade (1 of N) → fix → restore normal timelock

⚠️ **WARNING**: Emergency upgrade powers should ONLY exist if absolutely necessary. They are a centralization risk.

### Option C: User migration (worst case)

If contracts irrecoverable:
1. Snapshot user balances at safe block
2. Deploy completely new contracts
3. Allow users to claim from snapshot via merkle proof
4. Old contracts marked deprecated, frontend blocks interaction

---

## 💰 Compensation & Insurance

### If users lost funds:

1. **Treasury reimbursement** (if treasury has funds)
2. **Insurance claim**:
   - Nexus Mutual (if covered)
   - Sherlock (if covered)
3. **Recovery negotiation**:
   - Try to negotiate with attacker for 10% bounty in exchange for return
   - On-chain message to attacker address
   - Coordinate with chain analysis firms (Chainalysis, TRM Labs)
4. **Legal recourse**:
   - Report to FBI IC3 (if US users)
   - File at OFAC (sanctions if applicable)
   - Engage crypto forensics firm

### Bounty negotiation template (on-chain message)
```
Hello, this is the QUANTA Foundation team.

We acknowledge that you exploited a vulnerability in our contracts and 
took [X] tokens.

We're offering a [10-15]% white-hat bounty (= [Y] tokens) if you return 
[100-Z]% of funds to [official treasury address] within 72 hours.

This is a one-time offer. No questions asked. No legal action.

After 72 hours, we will:
1. Coordinate with law enforcement
2. Engage Chainalysis to trace funds
3. Work with exchanges to flag your addresses
4. Reach out to OFAC for sanctions consideration

We hope you'll do the right thing.

— QUANTA Foundation
```

---

## 📊 War Game Exercises (do these BEFORE you need to)

### Quarterly drills
- [ ] **Drill 1**: Simulate critical bug found on Twitter. Practice pause flow.
- [ ] **Drill 2**: Simulate multisig signer unreachable. Test backup signer.
- [ ] **Drill 3**: Simulate frontend hack. Practice taking down + replacing.
- [ ] **Drill 4**: Simulate active exploit. Time the full response.

### Metrics to improve
| Metric | Target |
|--------|--------|
| Time to detect | <5 min |
| Time to first signer ack | <10 min |
| Time to pause (P0) | <15 min |
| Time to first public statement | <30 min |
| Time to RCA published | <24h |

---

## 🛡️ Post-incident

### Within 72 hours
- [ ] Detailed post-mortem published (be transparent — community will respect honesty)
- [ ] Independent review of fix
- [ ] User compensation begun
- [ ] All other code reviewed for similar bugs
- [ ] Audit firms notified of new attack pattern

### Within 30 days
- [ ] Re-audit of all contracts
- [ ] New tests added covering exploited pattern
- [ ] Bug bounty increased (visible demonstration of taking security seriously)
- [ ] Detection rules added to Forta
- [ ] Operational improvements (faster pause, more on-call coverage)

### Within 90 days
- [ ] War game exercise based on this specific incident
- [ ] Public training material so other projects can learn
- [ ] Hire dedicated security engineer if you don't have one

---

## 📞 Critical contacts (FILL THESE IN BEFORE LAUNCH)

```yaml
# Internal
oncall_primary:     "Name <phone> <telegram> <signal>"
oncall_backup:      "Name <phone> <telegram>"
founder_24x7:       "Name <phone>"
tech_lead:          "Name <phone>"
legal_counsel:      "Name <email>"
pr_lead:            "Name <phone>"

# External — Security partners
audit_firm_hotline: "Firm <phone>"
forta_alerts:       "support@forta.org"
tenderly_support:   "support@tenderly.co"

# External — Industry response
certik_emergency:   "incident@certik.com"
peckshield_alerts:  "contact@peckshield.com"
slowmist_emergency: "team@slowmist.com"

# Government
fbi_ic3:           "ic3.gov"
ofac:              "ofac.treasury.gov"

# Crypto forensics
chainalysis:       "investigations@chainalysis.com"
trm_labs:          "support@trmlabs.com"

# Exchanges (to flag attacker addresses)
binance_security:  "compliance@binance.com"
coinbase_security: "trust@coinbase.com"
okx_security:      "compliance@okx.com"
kraken_security:   "compliance@kraken.com"

# Insurance
nexus_mutual:      "support@nexusmutual.io"
sherlock:          "audits@sherlock.xyz"

# Bridges (if attack involves bridge)
layerzero:         "security@layerzero.network"
wormhole:          "security@wormhole.com"
hyperlane:         "security@hyperlane.xyz"
```

---

## ⚠️ Common mistakes during incidents

| Mistake | Why it's bad | Do instead |
|---------|--------------|-----------|
| Trying to pause without coordinating signers | Tx fails, time wasted | Pre-stage tx, ping signers first |
| Posting "we're investigating" with no detail for hours | Community panics, FUD spreads | Update every 30 min with whatever you know |
| Trying to "outsmart" attacker via deploy race | Usually lose | Just pause and migrate cleanly |
| Hiding the breach | Always comes out, destroys trust | Be transparent from minute 1 |
| Promising compensation before assessing | Can't honor promise | Say "we're committed to making users whole, details TBD" |
| Negotiating publicly with attacker | They'll demand more | Use on-chain messages only |
| Letting devs deploy fix without review | Hot patches introduce new bugs | Even in emergency: 2 pairs of eyes |
| Forgetting to update frontend | Users keep trying old contract | Update RPC + addresses everywhere |
| Forgetting smaller chains | Multi-chain hack continues | Pause ALL deployments simultaneously |
| Not preserving evidence | Can't prosecute / claim insurance | Snapshot chain state, save logs |

---

## 📖 References — Learn from others' pain

- **Wormhole post-mortem**: Got $326M back via Jump Trading bailout. Wouldn't have happened without VC backing.
- **Euler Finance**: Negotiated with hacker, got 95% returned. Took 23 days of pressure.
- **Compound bug 2021**: $80M misallocated due to upgrade bug. Recovered ~30% through community goodwill.
- **Poly Network 2021**: $611M stolen, all returned by "Mr. White Hat" after pressure.
- **bZx 2020**: Multiple exploits taught them: pause functionality is NOT optional.
- **Curve 2023**: Vyper compiler bug. Curve's response = textbook. Read the post-mortem.

---

## 🎯 The mindset

When something goes wrong in production crypto, you'll feel:
- 😱 Panic ("we're ruined")
- 😡 Anger ("how did this happen")
- 😢 Despair ("I should quit crypto")

**All normal. All wrong.**

The right mindset:
- 🧊 **Cold focus**: every minute matters, execute the runbook
- 🔍 **Investigative**: understand exactly what happened
- 📣 **Transparent**: community trust survives bugs; it doesn't survive cover-ups
- 🛠️ **Action-oriented**: bad outcomes happen; great responses define your project

**The projects that survived $50M+ hacks are those that responded with grace, transparency, and competence.**

You can't prevent every bug. You CAN control your response. **Practice this runbook BEFORE you need it.**

---

**Last updated**: 2026-05-16
**Next drill**: [Schedule it now]
**Runbook owner**: [Founder name]
