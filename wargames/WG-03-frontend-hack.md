# 🌐 War Game 03 — Frontend Supply Chain Attack

**Difficulty**: 🔥🔥🔥 Hard
**Duration**: 60 minutes
**Objective**: Identify compromised frontend, take it down, restore from safe version, communicate.

---

## Scenario

It's a normal Tuesday. Then complaints start:

> User A: "I tried to claim my staking rewards and it asked me to approve unlimited spend on ALL my tokens. Looks weird."
>
> User B: "Same here! Approved it because I trusted you guys. Now my wallet is empty."
>
> User C: "Just lost 50,000 QTA. WTF is going on with quanta.foundation??"

**Your smart contracts are fine.** Your FRONTEND has been compromised.

This is the Bybit attack pattern ($1.5B in 2025): contracts secure, but frontend served malicious JS that tricked users into signing draining transactions.

---

## Possible attack vectors

Facilitator picks one:

1. **DNS hijack**: domain registrar account taken over, DNS points to attacker's server
2. **CDN compromise**: Cloudflare/AWS S3 bucket public-write, attacker swapped JS
3. **Dependency attack**: npm package you depend on was hijacked, malicious code injected
4. **GitHub compromise**: PR with malicious code merged by social engineering
5. **Vercel/Netlify account hack**: deploy key stolen

---

## Facilitator injects

| T+ | Event | How |
|----|-------|-----|
| 00:00 | User A Discord message about weird approval | Inject via helper |
| 00:02 | User B message confirming pattern | Inject |
| 00:05 | Twitter mentions starting to spike | Show graph |
| 00:10 | Reports: 20 users affected, ~500K QTA drained | Compile list |
| 00:15 | If team hasn't taken down site: 50 users affected, 2M QTA | Escalate |
| 00:25 | Crypto Twitter influencer (10K followers): "QUANTA frontend hacked, DO NOT USE" | Tweet |
| 00:35 | Forensics clue (drop subtly): Recent commit by "trusted dev" had base64-encoded payload | Pin to channel |
| 00:50 | Reset for debrief |

---

## What team must do

### Phase 1: Containment (first 15 min)

1. **Verify it's real** (not just user error)
   - Check transactions on Etherscan
   - Confirm approvals are unusual
2. **Take the site DOWN immediately**:
   - DNS: redirect to maintenance page
   - OR: Cloudflare → page rule → 503
   - OR: Vercel → pause deployment
3. **Block additional damage**:
   - Tweet IMMEDIATELY: "🚨 DO NOT INTERACT WITH quanta.foundation. Suspected compromise. Investigating. Use only contracts directly via Etherscan."
   - Pin tweet, post in Discord, send email blast
4. **Revoke any active deploy keys**:
   - Vercel/Netlify tokens
   - GitHub PATs
   - CDN access keys

### Phase 2: Forensics (15-45 min)

1. **What was compromised?**
   - Check DNS records (cloudflare audit log)
   - Check Vercel deploy history (was there a recent deploy?)
   - Check GitHub commit log (any suspicious PRs?)
   - Check npm package-lock.json (any unexpected dep changes?)
2. **What did attacker do?**
   - Diff current frontend JS vs last known-good
   - Identify malicious code
   - Identify attacker addresses receiving drained funds
3. **How many users affected?**
   - Query all unusual approval txs
   - Tag affected addresses
   - Estimate $$ loss

### Phase 3: Recovery (45 min - 24h)

1. **Restore from safe version**:
   - Rollback Vercel deploy to last-known-good
   - OR: deploy from IPFS pinned version
   - OR: rebuild from verified GitHub commit
2. **Increase security**:
   - Subresource Integrity (SRI) for all scripts
   - Multi-sig required for production deploys
   - 2FA on all accounts (verify all)
3. **Help affected users**:
   - Publish list of compromised addresses
   - Coordinate with exchanges to flag attacker addresses
   - Setup reimbursement plan if treasury allows

### Phase 4: Communication

Public template:

```
🚨 INCIDENT UPDATE [TIME UTC]

WHAT HAPPENED:
At [TIME], our website (quanta.foundation) was serving malicious JavaScript
that prompted users to approve excessive token allowances. Users who signed
these transactions had tokens drained.

OUR SMART CONTRACTS ARE NOT AFFECTED. Only the website was compromised.

IMPACT:
- ~X users affected
- ~Y QTA / $Z drained
- Attacker address: 0x...

WHAT WE'VE DONE:
- Frontend taken down at [TIME]
- Restored from verified backup at [TIME]
- Rotated all deployment credentials
- Engaged Chainalysis to trace funds
- Reported to FBI IC3 and OFAC

WHAT YOU SHOULD DO:
- If you used our website between [TIME] and [TIME], check your token approvals at revoke.cash
- Revoke any approvals to addresses you don't recognize
- If you were drained, file claim at [URL]

WE WILL COMPENSATE AFFECTED USERS via the treasury.
```

---

## ⚠️ Common mistakes

| Mistake | Why bad |
|---------|---------|
| "Let's just push a fix and tweet about it after" | Users continue getting drained |
| Taking down site silently | Looks like cover-up |
| Blaming individual employee publicly | Legal liability + chilling effect |
| Promising compensation before assessing | Can't honor → trust destroyed |
| Forgetting to rotate keys after | Attacker still has access |

---

## ✅ Excellent response

```
T+02 User reports cross-referenced, real
T+04 Site taken down (Cloudflare maintenance page)
T+05 Emergency tweet pinned + Discord ping
T+07 Email blast to 5000 users
T+10 Forensics begins on Tenderly + GitHub
T+15 Identified: malicious script injected via npm dependency
T+20 npm: removed bad dep, rebuilt
T+25 Cleaned frontend deployed to IPFS (immutable backup)
T+30 DNS pointed to IPFS gateway via Cloudflare
T+35 Site live again (with maintenance banner explaining)
T+40 Compromised commits force-reverted in GitHub
T+45 All deploy keys rotated
T+60 Detailed post-mortem published
T+24h Reimbursement plan published
```

---

## 🛡️ Prevention checklist (post-drill action items)

- [ ] Subresource Integrity (SRI) on every <script> tag
- [ ] No third-party CDN scripts (host everything yourself)
- [ ] Lock dependencies (`package-lock.json` committed, never auto-update)
- [ ] Automated dependency scanning (Dependabot + Socket.dev)
- [ ] Multi-sig required for production deploys (use Vercel's team approval)
- [ ] 2FA mandatory on GitHub, Vercel, Cloudflare, npm, domain registrar
- [ ] Hardware key (YubiKey) for 2FA where possible
- [ ] IPFS deploys as immutable backup (users can access even if domain compromised)
- [ ] Reproducible builds (anyone can verify hash matches commit)
- [ ] Transaction simulation in UI (warn user before signing unusual tx)
- [ ] Regular phishing training for team
