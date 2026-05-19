# 🌉 War Game 06 — Unusual Bridge Mint Pattern

**Difficulty**: 🔥🔥 Medium
**Duration**: 45 minutes
**Objective**: Detect potential bridge exploit, halt mints without breaking legitimate operations.

---

## Scenario

Forta alert fires at 9 AM:

```
🟠 HIGH: QUANTA-BRIDGE-LARGE-MINT
Detector: bridge_anomaly
Time: 09:14 UTC

Anomaly: 500,000 QTA minted via bridge in single tx.
Rolling 24h avg: 12,000 QTA.
Recipient: 0xNEW_ADDRESS_NEVER_SEEN_BEFORE
Source chain attestation: present
Validator sigs: 5 of 7 (above threshold)
```

The bridge mint is **technically valid** (passes all checks). But:
- 40× larger than normal
- New recipient address
- Just under detection threshold (some bots would miss)
- No corresponding lock event on source chain visible yet (might just be slow propagation)

**Is this a real attack, or legitimate big customer?**

---

## Facilitator injects

| T+ | Event |
|----|-------|
| 00:00 | Forta alert (above) |
| 00:05 | Second mint: 750K QTA to different new address |
| 00:10 | Third mint: 1M QTA |
| 00:15 | If not paused: Discord user "Did you guys raise lock cap? Seeing massive mints" |
| 00:20 | Source chain check: NO matching lock txs (this is the smoking gun) |
| 00:30 | If still not paused: "RIP QUANTA, bridge being drained" Twitter trending |

---

## What team must do

### Phase 1: Diagnose (first 10 min)

1. **Cross-chain check**:
   - Query source chain for matching `Locked` events
   - **If NONE exist for these mints → critical bridge bug**
2. **Validator status**:
   - Are validators behaving correctly?
   - Check signature aggregator logs
3. **Code review**:
   - Recently deployed changes?
   - Any known issue with the relayer?

### Phase 2: Pause decision (10-20 min)

This is the hard part. Options:

| Action | When | Risks |
|--------|------|-------|
| **Pause everything** | High confidence it's an attack | False alarm = downtime, FUD |
| **Pause mints, allow burns** | Partial confidence | Users can still exit, no new mint risk |
| **Rate-limit mints to 10K/hr** | Low confidence | Slow legitimate use, but stops drain |
| **Do nothing, monitor** | Convinced it's legitimate | If wrong, lose everything |

**Recommended**: Pause mints, allow burns. Communicate clearly.

### Phase 3: Forensics (20-45 min)

1. **Identify attack vector**:
   - Was it signature replay?
   - Were validators compromised?
   - Bug in relayer?
   - Bug in verifier?
2. **Quantify loss**:
   - Total over-mint = mint - actual locks
   - Where did the over-minted tokens go?
3. **Recovery plan**:
   - Can we burn the over-minted tokens? (Need attacker cooperation OR pause + migrate)
   - Bug fix timeline?
   - Re-enable bridge timeline?

---

## ⚠️ Common mistakes

| Mistake | Why bad |
|---------|---------|
| Waiting for "100% certainty" before pausing | Lose millions while debating |
| Pausing without explaining why | Community thinks YOU are the bad actor |
| Pausing only mint, forgetting to pause burn | Asymmetric exit creates run on bridge |
| Trying to "outrun" attacker by emergency upgrade | Usually fail, sometimes worse |
| Blaming validators publicly before investigation | Defamation risk + alienates them |

---

## ✅ Excellent response

```
T+03 Alert acknowledged, lead designated
T+05 Cross-chain query: NO matching locks → bridge bug confirmed
T+07 Multisig proposal: pause bridge mints (not burns)
T+12 3/5 sigs, pause executed
T+15 Tweet: "We've detected anomalous bridge mints and paused mint functionality as a precaution. Burns/exits remain enabled. Investigating. No user action needed yet."
T+20 Discord: detailed explanation for crypto-literate users
T+25 Forensics: identified bug in verifier (off-by-one in signature index)
T+30 Quantified: 2.25M QTA over-minted (2.5% of supply)
T+40 Recovery plan:
     - Tokens minted to 3 attacker addresses
     - Cannot recover without consent
     - Treasury will burn equivalent amount to neutralize inflation
     - Bug fix being written
T+60 Public statement with details
T+24h Fix deployed, bridge re-enabled
T+48h Treasury burns 2.25M QTA, supply restored
T+7d Post-mortem published, validators audited
```

---

## 🛡️ Prevention (post-drill action items)

1. **Solvency invariant on-chain**:
   ```solidity
   require(totalMinted <= totalLockedOnSourceChain, "insolvency");
   ```
2. **Rate limit per hour**: max 50K QTA / hour global
3. **Auto-pause on anomaly**: if mint > 5× avg, pause automatically
4. **Multiple data sources for source chain verification**:
   - Don't trust single relayer
   - Use 3 independent oracles
5. **Insurance fund**: separate pool to make users whole during incidents
6. **Phased TVL caps**: max $1M bridge TVL for first 3 months
7. **Bug bounty for bridge specifically**: $500K+ critical, $50K high

---

## Bridge security is HARD

This drill exists because:
- $3B+ lost to bridge hacks 2021-2025
- Even "audited" bridges (Wormhole, Ronin) got exploited
- Custom bridges are the #1 risk vector for new L1s

**Lesson**: For QUANTA v1, use **existing audited bridges** (LayerZero, Hyperlane). Don't build custom unless absolutely necessary.

When you do build custom (post-L1 launch), invest **disproportionately** in:
- Multiple independent audits
- Formal verification of verifier
- Massive bug bounty
- Phased rollout with TVL caps
- 24/7 monitoring with auto-pause
