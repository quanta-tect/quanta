# 🛡️ Course 01: Security Basics for Everyone

**Audience**: ALL QUANTA users (not just devs)
**Duration**: 30 minutes
**Prerequisites**: None

---

## Why this matters

In crypto, **YOU are your own bank**. There's no customer service. No fraud reversal. If you lose your money, it's gone forever.

But unlike traditional banking, you have **mathematical certainty** that you're in control. The trade-off: you must learn basic security.

This course teaches the bare minimum to not get hacked.

---

## Module 1: The Golden Rules (5 min)

### Rule 1: Never share your seed phrase

Your **seed phrase** (or "recovery phrase", "mnemonic") is 12 or 24 random words.

It IS your wallet. Anyone with these 24 words has all your money. Forever.

- ❌ Never type it into a website
- ❌ Never type it into an app (except hardware wallet setup)
- ❌ Never photograph it
- ❌ Never save it in a password manager (some are safe, but easy to mess up)
- ❌ Never email it, text it, paste it in Discord
- ❌ Never share with "support staff" (they're scammers)
- ❌ Never share with anyone, ever, for any reason

✅ Write it on **steel backup card** (paper degrades, can burn)
✅ Store in 2 locations (home safe + bank vault)
✅ Tell ONE trusted person where it is (for inheritance)

### Rule 2: Use a hardware wallet for anything > $500

Software wallets (MetaMask, Phantom) are convenient but live on your computer. If your computer is hacked → wallet hacked.

Hardware wallets (Ledger, Trezor, GridPlus) keep keys offline. To sign a tx, you physically press a button on the device. Even with a hacked computer, attacker can't sign.

**Best practice**:
- Daily spending wallet: software (MetaMask)
- Savings: hardware wallet
- Keep > 80% of crypto in hardware

### Rule 3: Verify EVERY transaction before signing

Most hacks aren't smart contract bugs. They're tricks to get YOU to sign a malicious transaction.

Before clicking "Confirm":
- ✅ Is the recipient address correct? (Verify last 4 + first 4 chars)
- ✅ Is the amount correct?
- ✅ Are you approving a SPECIFIC amount or "unlimited"?
- ✅ Are you on the right network? (Mainnet vs testnet)
- ✅ Does the simulation match what the website said?

If anything looks off, **REJECT and ask in community first**.

---

## Module 2: Common attacks (10 min)

### Attack 1: Phishing websites

Attacker creates `qunata-foundation.com` (note typo) that looks identical to real site.

You:
- Connect wallet → fine, still safe
- Approve "unlimited spend" thinking you're using real site → DRAINED

**Defense**:
- Bookmark official URL
- Type URL manually, never click links in DMs/emails
- Check URL char-by-char (especially after "/")
- Use anti-phishing wallet (some show known scam alerts)

### Attack 2: Fake support DMs

You post in Discord: "Help! My tx failed!"

Within 5 minutes, "support staff" DMs you offering help. They send a link to "fix it" — you connect wallet → DRAINED.

**Defense**:
- **Real support never DMs first**. Ever.
- If unsure, ask in PUBLIC channel: "Is this DM legit?"
- Disable DMs from non-friends (Discord settings)

### Attack 3: Approval exploits

You think you're approving 100 QTA for a swap. But the website tricks your wallet into approving `2^256 - 1` (effectively infinite).

Six months later, that swap site is hacked. Attacker sweeps all your approved tokens.

**Defense**:
- Use wallet that decodes approvals clearly
- Set EXACT amounts in approval (not max)
- Revoke approvals you no longer need: revoke.cash
- Use QUANTA Wallet (simulates before sign)

### Attack 4: SIM swap

Attacker convinces your phone carrier to transfer your number to their SIM. They then reset your email password → access your exchange account → drain.

**Defense**:
- Don't use SMS 2FA — use authenticator app (Google Authenticator, Authy)
- Better: hardware key (YubiKey)
- Set carrier PIN to prevent unauthorized SIM changes
- Use email provider with hardware-key 2FA (Gmail, ProtonMail)

### Attack 5: Clipboard malware

Malware on your computer detects when you copy a crypto address and replaces it with attacker's address.

You paste, click send, sign → tokens go to attacker.

**Defense**:
- Verify pasted address still matches what you copied (first 6 + last 4 chars)
- Hardware wallet shows recipient address on its screen — verify there too
- Don't keep large amounts on infected computers (factory reset suspicious machines)

### Attack 6: Honeypot tokens

You buy a hyped new token. Price goes up. You try to sell → tx fails.

The token contract has logic: anyone except creator can buy, no one can sell.

**Defense**:
- Only buy from DEXes for tokens you've personally researched
- Use tools like honeypot.is to check before buying
- If something promises 1000x in days, it's a scam

---

## Module 3: Wallet hygiene (10 min)

### Multiple wallets strategy

Maintain at least 3 wallets:

| Wallet | Purpose | Hot/Cold |
|--------|---------|----------|
| **Daily** | Small amounts, frequent use | Hot (MetaMask) |
| **DeFi** | Specific protocol interaction | Hot (separate) |
| **Vault** | Savings, > $1000 | Cold (hardware) |

Reasons:
- If "Daily" gets compromised, only small loss
- "DeFi" isolation: if one protocol you use gets hacked, only that wallet's risk
- "Vault" rarely interacts with web → near-zero exploit surface

### Approve granularly

```
❌ approve(swap_router, MAX_UINT256)
✅ approve(swap_router, 100 QTA)   // exact amount for this trade
```

After trade: `approve(swap_router, 0)` to revoke.

Costs a bit more gas. Saves $$$$ when that router eventually gets hacked.

### Regular approval audit

Every 3 months:
1. Go to revoke.cash → connect wallet
2. See list of every contract you've approved
3. Revoke anything you don't actively use
4. Especially: revoke unlimited approvals

---

## Module 4: Tools we recommend (5 min)

### Free essential tools

| Tool | What it does | URL |
|------|--------------|-----|
| **MetaMask** | Software wallet | metamask.io |
| **Ledger / Trezor** | Hardware wallet | ledger.com / trezor.io |
| **revoke.cash** | Audit + revoke approvals | revoke.cash |
| **Etherscan** | Verify transactions, contracts | etherscan.io |
| **Tenderly** | See what tx will do before signing | tenderly.co |
| **Phalcon** | Visualize complex txs | phalcon.xyz |
| **Blowfish** | Browser extension, scam protection | blowfish.xyz |
| **Pocket Universe** | Transaction risk scoring | pocketuniverse.app |
| **De.Fi Scanner** | Token contract scanner | de.fi |
| **honeypot.is** | Detect honeypot tokens | honeypot.is |

### Browser hygiene

- Use **dedicated browser** for crypto (e.g., Brave) separate from daily Chrome
- Few extensions: only MetaMask, Pocket Universe, Blowfish — nothing else
- Don't log into Google in crypto browser
- Hardware key (YubiKey) for crypto-related Google account
- Keep browser updated weekly

---

## Module 5: When something goes wrong (5 min)

### You think you've been hacked

1. **Move funds IMMEDIATELY** to a fresh wallet
   - From a CLEAN computer (boot from USB Linux if unsure)
   - Use Etherscan to check what's left
2. **Don't sign anything** from possibly-compromised wallet
3. **Ask in community** with details
4. **Report to Chainalysis Reactor** (free) — adds attacker to watchlist
5. **File with FBI IC3** if US citizen

### You signed a malicious approval

1. Go to revoke.cash IMMEDIATELY
2. Revoke the malicious approval
3. Move remaining funds to fresh wallet
4. Don't pay any "recovery scammers" who reach out

### Your hardware wallet is lost/stolen

1. Use seed phrase to restore on a new device
2. Send all funds to a NEW wallet (with NEW seed phrase)
3. Old device is now useless (attacker would also need PIN, but assume worst)

---

## Quiz (5 min)

Self-test. Answer in head:

1. Where should you NEVER type your seed phrase?
2. What's the #1 difference between hardware and software wallets?
3. What does "unlimited approval" mean and why is it dangerous?
4. If support DMs you offering help, what should you do?
5. What tool do you use to revoke approvals you no longer need?

**Answers**:
1. Any digital device except hardware wallet setup
2. Hardware wallet keys never touch internet-connected computer
3. Contract can withdraw any amount of token any time → if hacked, drained
4. Block them — real support never DMs first
5. revoke.cash

If you missed any, re-read that section.

---

## Action items

- [ ] Bookmark official QUANTA URL
- [ ] Buy hardware wallet if you have > $500 in crypto
- [ ] Set up authenticator app for 2FA (replace SMS)
- [ ] Install Blowfish + Pocket Universe browser extensions
- [ ] Visit revoke.cash and audit current approvals
- [ ] Tell ONE trusted person where your backup is
- [ ] Complete next course (02-scams.md)

---

## TL;DR

1. **Seed phrase = your money.** Steel backup, 2 locations, no digital storage.
2. **Hardware wallet for > $500.** Software OK for daily.
3. **Verify every tx before signing.** Don't blind sign.
4. **No support staff DMs you first.** Block them.
5. **Approve exact amounts.** Revoke when done.
6. **Multiple wallets** for isolation.
7. **When in doubt, ask publicly** (not in DMs).

**You're now safer than 95% of crypto users.** That's not paranoid — that's competent.
