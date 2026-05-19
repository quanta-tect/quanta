# 🔐 QUANTA Multisig Setup — Complete Guide

> **Goal**: Set up 3/5 Gnosis Safe multisig on Base, with hardware wallets, geographic distribution, and proper key ceremony.
>
> **Time required**: 4-6 hours initial + 1 hour per signer onboarding
> **Cost**: ~$30-50 (hardware wallets for signers if needed) + $5-10 deploy gas

---

## 📐 Architecture Decision

### Recommended for QUANTA at different stages

| Stage | Setup | Why |
|-------|-------|-----|
| Testnet | 1/1 hot wallet | Speed > security on testnet |
| **Mainnet launch ($0-1M TVL)** | **3/5 Safe** | Balance: decentralized but operable |
| Growth ($1M-10M TVL) | 5/7 Safe + 48h timelock | More signers = less collusion risk |
| Scale ($10M-100M TVL) | 7/11 Safe + 7-day timelock | Industry standard |
| Mature ($100M+) | DAO governance + emergency multisig | True decentralization |

### Why 3/5 (not 2/3 or 5/9)?

- **2/3**: Single compromised signer + 1 collusion = drain. Too fragile.
- **3/5**: Need 3 simultaneous compromises. Each signer is geographically + organizationally distinct.
- **5/9**: Too operationally complex for small team (need 5 sigs every tx)
- **Most exploits**: 5/9 or smaller (Ronin = 5/9, Harmony = 2/5). 7/11 has not been exploited.

### Signer profile

Each signer MUST be:
- ✅ Real person (not an entity) with **verifiable identity**
- ✅ Has hardware wallet (Ledger / Trezor / GridPlus)
- ✅ Lives in **different country** from other signers
- ✅ Affiliated with **different organization** (no co-employees)
- ✅ Available 24/7 for emergencies (or designated backup)
- ✅ Bonded with personal reputation (community knows them)

---

## 🛠️ Pre-Setup Checklist

Before the key ceremony:

- [ ] 5 signers committed in writing
- [ ] Each signer has hardware wallet (verified working)
- [ ] Each signer has secure offline backup of seed phrase
- [ ] Communication channel set up (Signal group, NOT Telegram/Discord)
- [ ] Time-zone coverage planned (24/7 reachable for emergencies)
- [ ] Legal entity decided (Foundation? LLC? Cayman?)
- [ ] Insurance policy quoted
- [ ] Backup signer identified for each primary

---

## 🎬 The Key Ceremony (Day 0)

### What you'll do
Generate the multisig together, in a recorded session, so the community can verify no single party had unilateral control at any moment.

### Setup (Each signer, individually, BEFORE ceremony)

```bash
# 1. Unbox NEW hardware wallet (recorded video preferred)
# 2. Initialize device:
#    - Set 4-8 digit PIN
#    - Write seed phrase on PROVIDED steel backup card
#    - DO NOT photograph or type seed phrase digitally
#    - Store seed in 2 locations (home safe + bank vault)
# 3. Install Ethereum app on device
# 4. Connect to MetaMask in "hardware wallet" mode
# 5. Verify address matches what device shows
# 6. Send small test tx (0.001 ETH) to confirm signing works
# 7. Report address to coordinator via Signal
```

### Ceremony Day (Live video call, recorded)

#### Step 1: Deploy Gnosis Safe (15 min)

**Coordinator does this:**

1. Open https://app.safe.global
2. Connect coordinator's hardware wallet
3. Switch to **Base mainnet** (chainId 8453)
4. Click "Create new Safe"
5. Name: `QUANTA Foundation Multisig v1`
6. Network: Base
7. **Owners**: paste all 5 addresses (verify with each signer over video)
8. **Threshold**: 3 of 5
9. Review fees (~$5-15)
10. Click "Create" → sign with hardware wallet
11. Wait for confirmation
12. **Copy Safe address** (e.g., `0xSAFE...`) — this becomes QUANTA's owner

#### Step 2: Verify Safe configuration (10 min)

Each signer logs in independently and confirms:
- [ ] Safe address matches
- [ ] All 5 owner addresses correct
- [ ] Threshold = 3
- [ ] Their address is in owners list

#### Step 3: Test signing flow (30 min)

Practice transaction (DON'T deploy real contracts yet):

```
1. Coordinator proposes a no-op tx (e.g., transfer 0 ETH to self)
2. Signer A signs via hardware wallet
3. Signer B signs via hardware wallet
4. Signer C signs via hardware wallet
5. Coordinator executes → tx confirms on-chain
6. Verify in Safe UI: 3/5 signatures shown
```

**Why practice?** First real tx during incident = panic + mistakes. Practice = muscle memory.

#### Step 4: Document everything (30 min)

Create `multisig-attestation.txt`:

```
QUANTA Multisig Key Ceremony Attestation
=========================================
Date: YYYY-MM-DD HH:MM UTC
Safe address: 0xSAFE_ADDRESS_HERE
Network: Base mainnet (chainId 8453)
Threshold: 3 of 5

Signer 1:
  Address: 0x...
  Name: [Real name]
  Country: [Country]
  Org: [Independent / Org name]
  Hardware: Ledger Nano X / Trezor Safe 3 / etc.
  Backup location: [Safe deposit box / fireproof safe]

Signer 2-5: [same format]

Coordinator: [Name]
Recording: [IPFS hash or YouTube unlisted]
Witnesses: [Other team members present]

Cryptographic commitment (verify on-chain):
  Tx hash of Safe deployment: 0x...
  Tx hash of test signing: 0x...
```

Sign attestation with all 5 hardware wallets + publish to GitHub + Mirror.xyz.

#### Step 5: Transfer ownership of contracts (1h)

For each contract, propose tx via Safe:

```javascript
// On each QUANTA contract (Token, Registry, Channel, Marketplace):
contract.transferOwnership(SAFE_ADDRESS);
// Then SAFE accepts (Ownable2Step):
contract.acceptOwnership();
```

Order:
1. AIPaymentChannel.transferOwnership(SAFE) → Safe accepts
2. AIModelMarketplace.transferOwnership(SAFE) → Safe accepts
3. AIAgentRegistry.transferOwnership(SAFE) → Safe accepts
4. QuantaToken.transferOwnership(SAFE) → Safe accepts

⚠️ **Token is last** because some other contracts depend on its admin functions.

Verify after each: `owner()` returns Safe address.

---

## 📜 Day-to-Day Operations

### Proposing a transaction

Any signer can propose:

```
1. Go to https://app.safe.global → select QUANTA Safe
2. Click "New transaction" → "Contract interaction"
3. Paste contract address + ABI (or use saved app)
4. Select function (e.g., `setAITaxRate(uint16)`)
5. Fill parameters
6. Click "Create transaction"
7. Sign with hardware wallet → propagates to other signers
```

### Approving (other signers)

```
1. Get notification (Safe email/push)
2. Open Safe app → review pending transaction
3. ⚠️ READ the transaction details CAREFULLY:
   - Correct contract address?
   - Correct function name?
   - Correct parameters?
   - Decoded human-readable preview?
4. If satisfied, sign with hardware wallet
5. If suspicious, REJECT + raise alarm in Signal group
```

### Execution

Once threshold reached (3/5), any signer (or anyone holding ETH for gas) can execute.

---

## 🔥 Emergency Procedures

### Pause flow (need 3/5)

**Pre-stage** the pause tx so it's ready to execute fast:

```javascript
// Pre-encoded calldata for emergency:
const pauseCalldata = "0x8456cb59"; // pause() selector

// Pre-create the Safe transaction object, save to:
// .multisig-emergency/pause-token.json
// .multisig-emergency/pause-channel.json
// .multisig-emergency/pause-marketplace.json
```

In emergency:
1. Signer 1 opens pre-staged tx, signs (T+1 min)
2. Signal alert to all signers (T+2 min)
3. Signer 2 signs (T+5 min)
4. Signer 3 signs (T+10 min)
5. Execute (T+11 min)
6. Public announcement (T+15 min)

**Target: Pause completed in <15 minutes from alarm.**

### Signer compromised

If one signer reports compromise:
1. **Immediately** propose `removeOwner` + `addOwner` (replace compromised)
2. Need 3/5 to execute owner change
3. Until executed, remaining 4 signers must coordinate
4. Public statement after rotation complete

### Signer unreachable (vacation, illness, etc.)

- Each signer designates **backup person** with hardware wallet
- Backup is NOT on multisig, but knows how to act FOR signer
- Process: video-verify identity → guided ceremony to use backup wallet
- If signer cannot be reached AT ALL within 7 days, propose removal

---

## 🛡️ Safe Modules (advanced, recommended)

### 1. Spending Limit module

Allows daily limits without full multisig sigs:

```
Setup: Safe → Apps → "Spending Limit"
Add: 1000 QTA/day per signer
Use case: routine payments don't need 3/5
Emergencies: still go through full multisig
```

### 2. Roles module (Zodiac)

Granular permissions per role:

```
Role "operator": can call setAITaxRate but NOT transferOwnership
Role "treasurer": can transfer from treasury but NOT change bridge
Role "emergency": can pause but NOT unpause
```

### 3. Timelock module

ALL admin actions delayed 48h (configurable):

```
Setup: Safe → Apps → "OpenZeppelin Defender" → "Defender Admin"
Configure: 48h delay on all transactions to QUANTA contracts
Override: only with 5/5 signatures (emergency)
```

**Strongly recommended for mainnet.**

---

## 📋 Annual Maintenance

| Task | Cadence |
|------|---------|
| Verify all signers still have working hardware wallets | Quarterly |
| Test signing ceremony (no-op tx) | Quarterly |
| Rotate signer keys (replace devices) | Annually |
| Add/remove signers as team changes | As needed |
| Review threshold (may increase as TVL grows) | Annually |
| War game: signer compromised drill | Semi-annually |
| Update Signal group, contact list | Continuously |
| Refresh attestation document | Annually |

---

## 🔗 Useful Links

- Gnosis Safe app: https://app.safe.global
- Safe Transaction Service API: https://safe-transaction-base.safe.global
- Safe deploy guide: https://docs.safe.global
- Zodiac modules: https://zodiac.wiki
- OpenZeppelin Defender: https://defender.openzeppelin.com (free tier exists)

---

## ⚠️ Common Mistakes (Don't do these)

1. ❌ All signers in same country → if local government seizes one, easy to grab others
2. ❌ Signers using same email provider → 1 Google breach = many compromised
3. ❌ Signers in same Telegram group as community → social engineering attack surface
4. ❌ Using same hardware wallet brand for all → 1 vendor bug = all vulnerable
5. ❌ "I'll just keep seed phrase digitally for backup" → laptop hack = funds gone
6. ❌ Practicing with mainnet ETH → expensive mistakes
7. ❌ Not testing recovery from backup → discover seed phrase wrong during incident
8. ❌ Sharing Safe URL publicly with threshold info → makes attack planning easier

---

## 💡 Pro Tips

1. **Use different hardware wallet brands** across signers (1× Ledger, 1× Trezor, 1× GridPlus, 1× Keystone, 1× SafePal)
2. **Backup hardware wallets** stored in signer's safe deposit box
3. **Quarterly drill**: pretend signer X is compromised, practice rotation
4. **Public signer profile** (Twitter handle, GitHub, etc.) so community knows who they are
5. **Sign attestation** with each hardware wallet → IPFS pinned → links from official site

---

**Last updated**: 2026-05-16
**Next ceremony review**: [Schedule with team]
