# 🔐 Course 05: Multisig Best Practices

**Audience**: Team / Treasurers
**Duration**: 60 minutes
**Prerequisites**: Course 01 + 03

---

## What is a multisig?

A multisig wallet requires **M of N signatures** to execute any transaction.

For QUANTA: **3 of 5** — need 3 of 5 signers to approve.

```
Single-sig wallet:           [Single key] → execute
Multisig 3/5:                [Key A] + [Key B] + [Key C] → execute
                              (any 3 of the 5 keys can authorize)
```

**Why**:
- Single key lost = funds lost forever
- Single key stolen = funds drained
- Multisig: need to compromise 3 simultaneously (much harder)

---

## Module 1: Multisig design decisions (15 min)

### Threshold (M of N)

| M / N | Pros | Cons | Use case |
|-------|------|------|----------|
| 1 / 1 | Fast | Single point of failure | NEVER for mainnet treasury |
| 2 / 2 | Both must agree | One uncooperative = stuck | NO (too fragile) |
| 2 / 3 | One signer can be offline | Only 1 compromise needed | Small DAOs |
| **3 / 5** | **Balanced** | **Recommended** | **Most projects** |
| 4 / 7 | More secure | Operationally harder | Mid-sized |
| 5 / 9 | Very secure | Many to coordinate | Ronin (got hacked anyway!) |
| 7 / 11 | Industry leading | Slow | Top DeFi protocols |

**Rule of thumb**: M = ⌈N/2⌉ + 1 for safety, N ≥ 5 for diversity.

### Signer diversity

| Diversity axis | Why important | Example |
|----------------|---------------|---------|
| Geographic | Survive local disasters / govt seizures | Signers in 5 different countries |
| Organizational | No collusion via shared employer | Different companies / independents |
| Technical | No common vulnerability | Mix of Ledger / Trezor / GridPlus |
| Network | Survive ISP outages | Different ISPs / VPN |
| Time zone | 24/7 coverage | Asia + EU + Americas |
| Personal | Survive personal incidents | Mix of ages, family situations |

**Anti-pattern**: 5 signers all in Silicon Valley, all on Gmail, all use Ledger, all employed by founder.

### Threshold dynamics

- **Increase threshold** as TVL grows
- **Decrease N** as team shrinks (but not below 5)
- **Annual review** of who's still appropriate

---

## Module 2: Operational practices (20 min)

### Proposing transactions

**Before proposing**:
- [ ] Coordinate with team (Slack/Signal heads-up)
- [ ] Document purpose (link to Issue/PR)
- [ ] Test on testnet first
- [ ] Verify calldata matches intent

**Format**:
```
Proposal #42
Action: setAITaxRate(50)
Purpose: Reduce tax to 0.5% as part of Q3 economic adjustment
Discussion: github.com/quanta/issues/123
Risk: Low — bounded function (max 1%)
Reviewers needed: 2 (3 sigs total)
Execution window: Within 48 hours
```

### Reviewing transactions

**Every signer MUST**:
- [ ] Read transaction details on Safe UI (not just blindly approve)
- [ ] Verify contract address (cross-reference with deployment file)
- [ ] Decode function name
- [ ] Decode parameters
- [ ] Verify hardware wallet shows SAME details before approving
- [ ] If anything differs → REJECT and ask team

**Anti-pattern**: "I trust the proposer, just sign quickly"
**Correct**: Verify independently every single time.

### The 30-second rule

Spend at LEAST 30 seconds reviewing each tx before signing. Most attacks rely on careless signers.

Set a personal rule: **No matter how trivial, count to 30** while reviewing.

### Signing order

If proposer is ALSO a signer:
- They sign first (shows commitment)
- Other signers verify independently
- Last signer triggers execution

For sensitive operations (treasury, ownership):
- Threshold = N (all must sign)
- Higher friction, but maximum safety

---

## Module 3: Emergency procedures (15 min)

### Pre-staged emergency transactions

For incidents, you DON'T want to be debating syntax. Pre-stage:

```javascript
// .multisig-emergency/pause-token.json
{
  "to": "0xQuantaTokenAddress",
  "value": "0",
  "data": "0x8456cb59",  // pause() selector
  "operation": 0,
  "purpose": "Emergency pause QuantaToken"
}

// .multisig-emergency/pause-channel.json
// .multisig-emergency/pause-marketplace.json
// .multisig-emergency/pause-bridge.json
```

In incident: one click → all signers see same pre-validated tx.

### Communication during incident

**Channel hierarchy** (use in this order):
1. **Signal group** (E2E encrypted, signers only)
2. **Backup: phone calls**
3. **Don't use Telegram for sensitive** (less secure)
4. **NEVER use Discord** for multisig coordination (public-ish, breached often)

**Discipline**:
- All decisions logged in Signal group
- Use "incident commander" pattern (one person leads, others execute)
- After incident: archive Signal messages to private log

### Signer unreachable scenarios

| Scenario | Action |
|----------|--------|
| One signer on vacation | Backup signer (designated per primary) |
| Signer device broken | Restore from steel backup, get back online |
| Signer's country has internet outage | Other 4 must operate |
| Signer in hospital | Wait OR designate emergency backup access |
| Signer became hostile / left company | Rotate (4 of 5 sigs to remove) |
| Signer's keys compromised | EMERGENCY: rotate immediately, pause first |

### Threshold under attack

If you suspect attack:
- **Pause first** (1 sig may be enough if you have emergency pause role)
- **Then investigate** with full threshold
- **Don't try to "outpace" attacker** — they may already have N-1 sigs

---

## Module 4: Common multisig hacks & lessons (10 min)

### Ronin Bridge ($625M, 2022)

**What happened**: 4 of 9 signers controlled by Sky Mavis (one company). Phishing attack got their keys. Attacker had 4/9 already, just needed 1 more. Got it via a 5th signer Sky Mavis had temporarily granted control to.

**Lessons**:
- Never have > ⌊N/2⌋ signers from same org
- Never grant temporary signing rights
- Use proper key rotation, not delegation
- 5/9 wasn't enough security — should have been 7/9 minimum

### Harmony Bridge ($100M, 2022)

**What happened**: 2 of 5 signers had keys stored in shared Slack channel for "convenience". Slack was compromised.

**Lessons**:
- NEVER store keys digitally
- Hardware wallets for ALL signers, NO exceptions
- Audit signer practices regularly

### Multichain ($126M, 2023)

**What happened**: Founder (sole signer of multiple keys) was arrested in China. All operations ceased. Funds frozen forever.

**Lessons**:
- TRUE diversity: no single person should be able to halt operations
- Legal entity considerations
- Geographic distribution of signers (not all in jurisdictions where you can be detained simultaneously)

### Munchables ($62M, 2024)

**What happened**: Project's upgradeable contract owner was changed to a wallet that turned out to belong to the attacker (insider).

**Lessons**:
- Insider threat is real
- Background check signers
- Use timelock on all ownership changes
- Public attestation of identities (community pressure)

---

## TL;DR

1. **3/5 minimum, 5/9 better** for mainnet treasury
2. **5+ countries, 5+ organizations, 5+ hardware wallet brands** for diversity
3. **Hardware wallets ONLY** — no exceptions, ever
4. **Pre-stage emergency txs** for quick pause
5. **30-second rule** on every signing
6. **Signal for coordination**, never Discord/Telegram for sensitive
7. **Quarterly drills** so you can execute under stress
8. **Annual review** of signer fitness + threshold
9. **Transparent attestation** — community knows who signers are
10. **Plan for incidents BEFORE they happen** — not during

Your multisig is the **foundation of trust** in your protocol. Treat it accordingly.
