# 🔓 War Game 02 — Multisig Signer Compromised

**Difficulty**: 🔥🔥 Medium
**Duration**: 45 minutes
**Objective**: Rotate compromised signer before attacker can collect 2 more sigs.

---

## Scenario

It's 3 AM. You get a Signal message from Signer 2:

> "Guys I think my hardware wallet was stolen from my hotel room. I just got back from dinner and it's gone. PIN was 4 digits. Address is [0x...] — has it been used?"

**Your team has hours, maybe minutes, before attacker:**
1. Cracks PIN (4 digits = brute force in seconds with specialized tools)
2. Discovers it's a QUANTA multisig signer
3. Coordinates with other compromised signer (if exists)
4. Proposes malicious tx (transfer ownership to attacker)
5. If 2 more signers sign by accident OR coordination → game over

---

## Facilitator injects

| T+ | Event | Who |
|----|-------|-----|
| 00:00 | Signer 2 Signal message above | Facilitator |
| 00:05 | Etherscan check: signer's address tried `addOwner` tx 2 min ago | Show via Tenderly |
| 00:15 | "Helpful" community member DMs: "Hey saw you guys posted a tx, you want me to sign it for you?" (red flag: not how multisig works) | Helper |
| 00:25 | Signer 3 (in Australia, sleeping): unresponsive | Don't reply for whole drill |
| 00:35 | New tx proposed to Safe: `transferOwnership(0xAttackerAddr)` for QuantaToken | Helper or facilitator submits |

---

## What team must do

1. **Verify Signer 2's identity** (in case it's social engineering)
   - Video call (face must match)
   - Ask question only real Signer 2 knows
2. **Lock the compromised signer out**:
   - Propose `removeOwner(compromisedAddr)` + `addOwner(newAddr)`
   - Need 3/5 sigs (NOT including compromised)
3. **Reach Signer 3, 4, 5** urgently
4. **Reject any malicious tx** in the multisig
5. **Document everything** for post-mortem
6. **Public statement** about key rotation (transparency builds trust)

---

## ⚠️ Common mistakes

| Mistake | Why bad |
|---------|---------|
| Panic-signing rotation tx without verifying first | Could sign wrong replacement address |
| Telling community immediately ("we're being attacked") | Causes bank-run before you've contained |
| Trying to "race" attacker to sign first | Slower than rotation, riskier |
| Not removing compromised signer immediately | Attacker has time to coordinate |
| Adding a "temporary" hot wallet signer to speed things up | Permanent security regression |

---

## ✅ Good response

```
T+02 Signer 2 message acknowledged
T+03 Incident commander designated
T+05 Video call started with Signer 2 — verified identity
T+07 Question asked: "What city did we last meet in?" (Signer 2 answers)
T+08 New hardware wallet prepared by Signer 2 (or facilitator pretends)
T+10 New address shared: 0xNEW...
T+11 Safe tx proposed: `swapOwner(prev, compromised, new)`
T+12 Signer 1 (you) signs
T+13 Signer 4 contacted via Signal, briefed, signs (T+18)
T+20 Signer 3 reached on phone, briefed, but can't sign for 30 min
T+25 Signer 5 reached, signs immediately
T+27 Rotation tx executes (3/5 sigs)
T+28 Verify on-chain: old signer removed, new added
T+30 Reject any pending suspicious txs
T+35 Public statement: "We've successfully rotated a multisig signer key as a precaution. No funds at risk. Operations continue normally. Details in 24h."
T+45 Internal post-mortem starts
```

---

## 💡 Lessons typically learned

1. **Need an "out-of-band" verification system** (memorable question, video, etc.)
2. **Need pre-defined replacement signer addresses** ready
3. **Signal group has gaps** in coverage hours
4. **Backup signer for each primary** not defined
5. **No clear "who's incident commander" right now** — needs rotation schedule

---

## Backup scenarios (variations to mix in)

- **Variant A**: Two signers compromised simultaneously (insider attack)
- **Variant B**: Signer is being coerced (kidnapping / wrench attack) — they signal with code phrase
- **Variant C**: Hardware wallet not stolen, but maker (Ledger/Trezor) announces vulnerability
- **Variant D**: Phishing attack — signer almost signed malicious tx, caught it last moment
