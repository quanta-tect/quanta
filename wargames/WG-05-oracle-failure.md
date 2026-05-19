# 📊 War Game 05 — Reputation Oracle Returns Bad Data

**Difficulty**: 🔥🔥 Medium
**Duration**: 45 minutes
**Objective**: Detect oracle malfunction, decide on pause-or-investigate, restore correct state.

---

## Scenario

Your reputation oracle (which adjusts AI agent scores based on off-chain behavior) starts returning **wildly incorrect data**:

- Top-rated agents (rep 9500) dropped to 100
- Sketchy agents (rep 1000) boosted to 10000
- 50+ agents affected in 5 minutes

The oracle is supposed to be your trusted bot. What happened?

**Possibilities**:
1. Bug in oracle code (most likely)
2. Oracle's private key compromised
3. Data source (e.g., off-chain database) corrupted
4. Deliberate manipulation by oracle operator
5. Replay attack (old txs being re-submitted)

---

## Facilitator injects

| T+ | Event |
|----|-------|
| 00:00 | Forta alert: 20 reputation drops > 5000 in 1 hour |
| 00:05 | User complaint in Discord: "Why is my agent suddenly rep 200?" |
| 00:10 | Top creator: "My model just lost 50% of customers because rep dropped" |
| 00:20 | More complaints; pattern becomes clear |
| 00:30 | Oracle operator: "I'm investigating, may have been a config push" |

---

## What team must do

### Phase 1: Triage (5-15 min)

1. **Confirm pattern**:
   - Query last 100 ReputationChanged events
   - Look for anomalies (mass changes, single oracle, etc.)
2. **Classify**:
   - Bug? (oracle running stale code)
   - Hack? (key compromise, unexpected signer)
   - Operator error? (deployed wrong config)
3. **Decision: Disable oracle?**
   - If clearly malfunctioning: `setReputationOracle(badOracle, false)` via multisig
   - Pros: stops bleeding
   - Cons: no reputation updates until restored

### Phase 2: Investigation (15-30 min)

1. **Diff oracle behavior**:
   - Compare on-chain calls vs expected calls
   - Check oracle's off-chain logs
   - Identify discrepancy
2. **Identify root cause**:
   - Code bug? Where?
   - Data corruption? When?
   - Key compromise? Last legitimate use?
3. **Quantify damage**:
   - How many agents affected?
   - Total reputation change?
   - Revenue impact for creators?

### Phase 3: Restoration (30-45 min)

1. **Calculate correct state**:
   - Snapshot reputation BEFORE oracle malfunction
   - Compute "should have been" values
2. **Restore options**:
   - **A**: Oracle re-sends correct values (`adjustReputation(delta=correction)`)
   - **B**: Add `adminSetReputation(agentId, value)` admin function via upgrade (heavy)
   - **C**: Deploy new contract, migrate state (heaviest)
3. **Implement option A** (simplest):
   - Oracle runs script: for each affected agent, calculate `correction_delta` and apply
4. **Verify restoration**:
   - Check reputations match pre-incident snapshot
   - Notify affected users

---

## 🛡️ Prevention (post-drill action items)

The oracle problem highlights real design issues:

### Trust assumptions
- Currently: single oracle is fully trusted within its bounds
- Better: **multiple oracles + median** (like Chainlink)
- Best: **on-chain commitment** to data with off-chain proof (zk)

### Rate limits
- Add: max N adjustments per oracle per hour
- Add: max delta per call (e.g., ±1000 per single call)
- Add: cooldown between adjustments to same agent

### Multisig oracle
- Require 2/3 oracle signers for big changes (delta > 2000)
- Single oracle for minor changes

### Audit trail
- All oracle calls logged with reason
- Public dashboard showing recent adjustments
- Anyone can challenge anomalies

---

## ✅ Excellent response

```
T+05 Anomaly confirmed via Forta + Discord reports
T+10 Multisig proposal: setReputationOracle(badOracle, false)
T+18 3/5 sigs collected, oracle disabled
T+20 Tweet: "We've temporarily disabled the reputation oracle due to detected anomalies. Reputations are frozen at last-correct values. Investigating."
T+30 Root cause: oracle deployed v2 with off-by-one in delta calculation
T+35 Fix: roll back oracle to v1
T+40 Restoration script written: re-adjust all 50 affected agents by inverse delta
T+45 Multisig re-enables oracle (with new code) + signs restoration batch
T+50 Verify: reputations restored to pre-incident values
T+60 Post-mortem published
T+24h: Add multi-oracle requirement to v2 contracts (longer-term fix)
```

---

## Lessons that typically emerge

1. **Single oracle is single point of failure** — design for redundancy
2. **No automated bounds checking** — should reject delta > threshold automatically
3. **No "dry-run" mode** for oracle — could have caught bug before deploy
4. **No staging environment** for oracle — went straight to mainnet
5. **No CHANGELOG required** for oracle config pushes — accountability lacking
