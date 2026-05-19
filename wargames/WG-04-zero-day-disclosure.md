# 🐛 War Game 04 — Whitehat Reports Critical Bug

**Difficulty**: 🔥 Easy
**Duration**: 30 minutes
**Objective**: Handle disclosure professionally, fix before exploit, reward whitehat appropriately.

---

## Scenario

You wake up to this email at security@quanta.foundation:

> Subject: Critical vulnerability in QuantaToken
>
> Hi team,
>
> I'm [pseudonym], a security researcher. I found a critical bug in your QuantaToken contract that allows draining the AI marketplace under specific conditions.
>
> I've **NOT** exploited it. I'm following responsible disclosure.
>
> Attached: detailed write-up + proof-of-concept on Sepolia fork (no real funds moved).
>
> I expect a $50,000 bounty per your published policy. Please respond within 24 hours or I will escalate.
>
> — anon_whitehat_xyz

**This is the BEST kind of incident**: someone helping you. But how you respond determines if they help next time too, AND if the community trusts you.

---

## Facilitator injects

| T+ | Event |
|----|-------|
| 00:00 | The email above |
| 00:05 | Whitehat sends second email: "PoC verified working, are you reading this?" |
| 00:15 | If team hasn't replied: whitehat tweets "Reported critical bug to @QuantaCoin 1 hour ago, no response. Should I be worried?" |
| 00:25 | If team handles well: whitehat replies "Great response, working with you" |

---

## What team must do

### Phase 1: Triage (first 30 min)

1. **Acknowledge** within 1 hour (this is the GOLD rule)
   - Email back: "Received, reviewing now, will respond with timeline within 4 hours"
   - This alone prevents 90% of escalation issues
2. **Verify the bug** is real
   - Reproduce on Tenderly fork
   - Confirm severity
3. **Internal severity classification**:
   - If actively exploitable → run incident response (WG-01)
   - If conditionally exploitable → high urgency fix
   - If theoretical → still serious, fix promptly

### Phase 2: Coordination (1-24 hours)

1. **Communicate with whitehat**:
   - Confirm severity classification
   - Discuss bounty amount (be transparent: budget, criteria)
   - Set fix timeline together
   - Agree on disclosure date (usually 30-90 days)
2. **Develop fix in private**:
   - Patch on private branch
   - Internal review (2+ engineers)
   - Have whitehat review the fix
3. **Schedule deploy**:
   - Multisig coordination
   - Testnet test first
   - Mainnet during low-activity window

### Phase 3: Disclosure (after fix deployed)

1. **Publish post-mortem** (within 7 days of fix):
   - What was the bug?
   - How was it found?
   - What was the impact (or potential impact)?
   - How was it fixed?
   - Credit the whitehat (with their permission)
2. **Pay bounty** (within 24 hours of fix):
   - Don't lowball. Pay full advertised amount.
   - Reputation matters more than $50K.
3. **Add to test suite**:
   - Regression test for the exact bug
   - Bonus: similar pattern checks

---

## 📝 Email templates

### Initial acknowledgment

```
Subject: Re: Critical vulnerability in QuantaToken

Hi [pseudonym],

Thank you for the report. We take security seriously and appreciate your responsible disclosure.

We've received your message and are beginning verification. Initial response timeline:
- Within 4 hours: Severity confirmation
- Within 24 hours: Fix plan + bounty discussion
- Within 7 days: Fix deployed
- Within 14 days: Public disclosure (with your credit, if you wish)

Our security@ inbox is monitored 24/7. Direct contact: [Signal username / Telegram].

Best regards,
[Name]
QUANTA Security Team
```

### Bounty offer

```
Subject: Re: Bug bounty for [bug ID]

Hi [pseudonym],

Bug verified. We've classified as Critical per our severity matrix.

Bounty offered: $50,000 USD, payable in QTA, USDC, or ETH (your choice).
Payable to: address you provide.
Timeline: within 24 hours of fix deployment.

In addition:
- Public credit on our security page (if you wish)
- Invitation to QUANTA Security Council (advisory role, paid)
- $5,000 retainer for ongoing review (optional)

Please confirm acceptance and provide payment address. We're targeting [DATE] for deployment.

Thank you for making QUANTA safer.

QUANTA Security Team
```

### Post-mortem template

```
# Post-Mortem: [Bug Title] (CVE-2026-XXXX)

## TL;DR
On [DATE], whitehat researcher [name/pseudonym] reported [bug description] in QuantaToken.
We fixed it within [N] days. No users were affected. We paid $50K bounty.

## Timeline
[Hour by hour log]

## Root Cause
[Technical explanation]

## Impact
[What could have happened if exploited]

## Fix
[What we changed + link to PR/commit]

## Lessons Learned
[What we'll do differently]

## Credit
Special thanks to [whitehat name] for responsible disclosure.

[Link to their Twitter / website]
```

---

## ⚠️ Common mistakes

| Mistake | Why bad |
|---------|---------|
| Not responding for 24+ hours | Whitehat may sell to blackhat OR go public |
| Disputing severity to pay less bounty | Whitehat tweets about you, reputation gone |
| Claiming "we already knew" | Insulting, kills future reports |
| Asking whitehat to sign NDA | Legitimate researchers won't comply, looks suspicious |
| Trying to identify whitehat IRL | Hostile move, community will defend them |
| Patching silently without credit | Whitehat reports it next time on Twitter directly |
| Sending bounty months late | Whitehat tells others, you get no more reports |

---

## ✅ Excellent response

```
T+00:30 Email acknowledged
T+02:00 Bug reproduced + confirmed Critical
T+03:00 Bounty offer sent ($50K, full advertised amount)
T+04:00 Fix branch created, 2 engineers reviewing
T+24:00 Fix passes all tests + whitehat-reviewed
T+48:00 Testnet deploy + whitehat re-verifies fix works
T+72:00 Mainnet deploy via multisig
T+72:30 Bounty paid in full
T+96:00 Post-mortem published with whitehat credit
T+120:00 Whitehat invited to security council
```

**Outcome**: Whitehat tweets positively. Other whitehats see this. You get 5x more reports next quarter. **Antifragile security**.

---

## 🏆 Build a "whitehat-friendly" reputation

Things that attract great researchers:

- ✅ Pay bounties FAST and FULL
- ✅ Credit publicly (with permission)
- ✅ Be transparent about decision-making
- ✅ Treat them as partners, not adversaries
- ✅ Have a Hall of Fame page
- ✅ Send swag (t-shirts, hoodies — researchers LOVE these)
- ✅ Invite to events
- ✅ Maintain relationship over time
- ✅ Refer them to OTHER projects (they remember you)

The best DeFi projects have whitehats actively scanning their code for fun.
The worst ones get exploited by blackhats who tried to disclose first but were ignored.
