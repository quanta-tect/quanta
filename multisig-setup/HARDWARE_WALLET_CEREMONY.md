# 🔐 Hardware Wallet Key Ceremony — Step by Step

> **Goal**: Generate 5 hardware wallets for QUANTA multisig signers in a way that proves no one had unilateral control.
>
> **Duration**: 2-3 hours per signer (in parallel = 1 day total)
> **Cost**: ~$130 per signer (hardware wallet) + $20 (steel backup) = ~$750 total
> **Witnesses**: At least 2 non-signers should observe the recorded ceremony

---

## 🛒 Equipment shopping list (per signer)

**Hardware wallet** (pick 1, use different brands across signers for vendor diversity):
- [ ] **Ledger Nano X** ($149) — most popular, mobile via Bluetooth
- [ ] **Trezor Safe 3** ($79) — open source firmware, good security
- [ ] **GridPlus Lattice1** ($397) — best UX for multisig, large screen
- [ ] **Keystone 3 Pro** ($169) — air-gapped (no USB/Bluetooth)
- [ ] **SafePal S1** ($49) — cheapest, air-gapped

**Steel backup** (NEVER paper — burns/water destroys):
- [ ] **Billfodl** ($95) — most popular, easy to use
- [ ] **Cryptosteel Capsule** ($79) — water/fire-proof
- [ ] **CrypTag** ($75) — DIY alternative

**Other supplies**:
- [ ] **Tamper-evident bag** (Amazon ~$10/pack) — store hardware wallet when not in use
- [ ] **Notebook + pen** for non-secret notes during ceremony
- [ ] **Phone or camera** for recording (signer's choice if want public proof)
- [ ] **Bank safe deposit box** for one backup copy

---

## 📜 Pre-ceremony checklist

### Personal preparation (signer does alone)
- [ ] Identified secure physical location (home office, no windows visible)
- [ ] Ensured no smart home cameras/devices recording
- [ ] Computer is updated, antivirus run
- [ ] Browser cache cleared, no extensions except MetaMask
- [ ] Have backup hardware wallet (failure rate ~5%)
- [ ] Phone in another room (avoid leaked notifications)
- [ ] 2-hour uninterrupted time blocked off

### Team coordination
- [ ] All 5 signers scheduled (parallel is fine, must complete same day)
- [ ] Coordinator on Zoom/Signal video for each signer
- [ ] Witness available (1-2 non-signer team members)
- [ ] Recording method agreed (or "no recording, attest later")

---

## 🎬 The Ceremony — 11 steps

### Step 1: Unbox + verify (10 min)

🎥 START RECORDING (if doing public attestation)

1. Show camera the **unopened box** with all factory seals intact
2. Read box's anti-tampering features aloud
3. Open box on camera
4. Verify components match manufacturer's official packaging list:
   - [ ] Hardware wallet device
   - [ ] USB cable
   - [ ] Recovery seed cards (paper — we'll discard, use steel)
   - [ ] Stickers / lanyard / etc.
5. **CHECK**: Is the device's screen blank/welcome (factory fresh)?
6. **CHECK**: Are any of the recovery cards pre-filled? (If yes → STOP, fraud, return)

### Step 2: Power on, set PIN (10 min)

1. Connect to computer via USB
2. Press buttons to power on
3. Choose "Set up as new device"
4. **PIN selection**:
   - Minimum 6 digits (4 is too weak)
   - Don't use birthday, anniversary, phone numbers
   - Recommend: random 8 digits, memorize via mnemonic
5. Enter PIN twice
6. **Important**: Write PIN on a paper, store in DIFFERENT location from seed (so single break-in doesn't get both)

### Step 3: Generate seed phrase (15 min)

⚠️ **CRITICAL**: This is the only time the seed phrase will exist in clear text. Do NOT:
- ❌ Photograph it
- ❌ Type it into ANYTHING digital
- ❌ Speak it aloud (smart speakers may listen)
- ❌ Show it to camera

✅ Do:
1. Cover camera lens during this step (point away)
2. Device displays 24 words (write down each)
3. Write on the included **paper** card first (for verification only — we'll burn it)
4. Verify each word by re-displaying on device
5. Device will quiz you: re-enter words 3, 7, 12, 24 — confirms you wrote them correctly

### Step 4: Transfer to steel backup (20 min)

1. Open Billfodl / Cryptosteel
2. Carefully transfer each word's first 4 letters (industry standard)
3. **Triple-check** by reading back
4. Close the steel case, ensure it can't be tampered without obvious damage

### Step 5: Destroy paper backup (5 min)

1. Verify seed words on steel match what you wrote on paper
2. Cut paper card into small pieces
3. Burn pieces (literally — in metal bowl, outdoor area, safely)
4. Disperse ashes
5. **Why so paranoid?** Because if anyone EVER finds that paper card, they have your money. Forever.

### Step 6: Test recovery (15 min)

⚠️ **CRITICAL**: Verify backup ACTUALLY works before trusting it.

1. Reset hardware wallet to factory settings
2. Choose "Restore wallet"
3. Enter all 24 words from your steel backup (NOT memory)
4. Verify your address matches what it was before
5. **If addresses match**: backup works
6. **If different**: catastrophic error in transcription — start over

### Step 7: Connect to MetaMask (10 min)

1. Open MetaMask in browser
2. Click account icon → "Connect hardware wallet"
3. Choose your wallet brand
4. Connect via USB (or Bluetooth for Ledger)
5. Select account 0 (default)
6. Verify address matches what device shows

### Step 8: Confirm address with team (5 min)

🎥 RESUME RECORDING (if paused)

1. Coordinator on Zoom asks: "Signer #2, please display your address to camera"
2. Read address aloud (last 8 chars enough for verification)
3. Coordinator pastes into shared signer registry
4. Other team members verify it's unique (no collision with existing signers)

### Step 9: Send test transaction (15 min)

1. Coordinator transfers $1 worth of ETH to signer's address (Base testnet OK for practice)
2. Wait for confirmation
3. Signer sends $0.50 back to coordinator
4. **Hardware wallet displays transaction details** — verify before approving
5. Approve on device
6. Transaction confirms — signer can now sign

### Step 10: Store hardware wallet securely (10 min)

1. Place hardware wallet in tamper-evident bag
2. Seal bag (signature across seal)
3. Photograph seal (note tamper-evidence)
4. Store in:
   - **Primary**: Home safe (fireproof, bolted to floor)
   - **Backup steel**: Bank safe deposit box (separate from primary)
5. Document storage location in offline-only document (encrypted with team key)

### Step 11: Sign attestation (30 min)

🎥 ENSURE RECORDING (this is the public proof)

1. Open `multisig-attestation.txt` (template below)
2. Each signer fills in their section
3. Each signer signs attestation with their newly-created hardware wallet
4. Coordinator combines all signatures
5. Upload to GitHub + Mirror.xyz + IPFS

🎥 STOP RECORDING

---

## 📋 Attestation template

```
QUANTA MULTISIG KEY CEREMONY ATTESTATION
=========================================

Ceremony date: 2026-MM-DD
Ceremony coordinator: [Name]
Witnesses: [Names]
Recording: [IPFS hash or YouTube URL]

SAFE INFORMATION
Network: Base mainnet (chainId 8453)
Safe address: 0xSAFE_ADDRESS
Threshold: 3 of 5

SIGNER ATTESTATIONS
===================

Signer 1: [Full Name]
  Public address: 0x...
  Hardware wallet: [Brand, Model, Serial]
  Country of residence: [Country]
  Organization: [Affiliation]
  Backup location: [Vault/Safe — keep general, not specific]
  Reachable 24/7 via: [Signal / Telegram username]
  Backup person: [Name + relationship]
  Signature: [Hex from hardware wallet signing this document]
  Public commitment: "I attest that I:
    - Generated this key on a brand-new hardware wallet
    - Followed all 11 ceremony steps
    - Stored seed phrase only on steel backup
    - Did not share seed phrase with anyone
    - Will not store seed phrase digitally
    - Understand I am responsible for this key
    - Will rotate within 30 days if compromise suspected
    - Will pause and announce in case of emergency"

[Repeat for Signers 2-5]

COORDINATOR ATTESTATION
=======================
I [Name] coordinated this ceremony and confirm:
- Each signer performed steps independently
- I had no access to any signer's seed phrase
- I observed no security violations
- All addresses are listed correctly above

Signature: [Hex from coordinator's hardware wallet]

WITNESS ATTESTATIONS
====================
I [Witness Name] observed [signer's portion] and confirm:
- Ceremony followed documented procedure
- No security violations observed
- Recording is unedited and complete

Signature: [Hex]

[Repeat for each witness]

CRYPTOGRAPHIC COMMITMENT
========================
SHA-256 of this document (excluding signatures): [hash]
On-chain commitment tx: 0x... (commit to Base via simple transaction)
Date attestation published: [date]
URL: github.com/[org]/quanta/blob/main/multisig-attestation.txt
IPFS pin: bafy...
```

---

## 🚨 What to do if ceremony goes wrong

| Issue | Action |
|-------|--------|
| Hardware wallet won't power on | Use backup wallet (have spare) |
| Forgot to record beginning | Document with photos, redo ceremony if possible |
| Seed phrase transcription error discovered later | Start over with new wallet — old key compromised |
| Signer's spouse/family walked in during seed step | Decide if they saw seed → if yes, start over |
| Camera recorded seed by accident | Delete recording with witnesses, start over |
| Wrong number of words on display | Wrong wallet firmware — return device |
| Hardware wallet asks for seed during setup | NOT factory new — return |
| Address doesn't match after restore test | Transcription wrong — start over |

**Rule**: If ANYTHING feels wrong, start over. Cost of redo = $130. Cost of compromise = $1M+.

---

## 🔄 Annual key rotation

Hardware wallets should be rotated annually to:
- Replace aging devices
- Update firmware to latest version
- Re-verify backups still work
- Add new signers / remove old

### Rotation process
1. Each signer generates NEW hardware wallet (follow this guide)
2. Multisig proposal: `swapOwner(prevOwner, oldAddress, newAddress)` for each signer
3. Need 3/5 sigs to execute (so coordinate with rotation order carefully)
4. After rotation: old hardware wallet wiped + destroyed
5. New attestation document published

---

## 🛡️ Anti-coercion measures

In case a signer is being physically coerced (kidnapping, "wrench attack"):

### Duress signals
Agree in advance on **innocuous-seeming phrases** that mean "I'm under duress":
- "Let me get back to you on this"
- Specific emoji combo in Signal message
- Wrong-but-specific answer to a routine question

### Procedure when duress detected
1. Other signers acknowledge silently (don't tip off attacker)
2. IMMEDIATELY pause all contracts (3 sigs from non-duress signers)
3. Call local police for kidnapping
4. After signer is safe: rotate their key
5. Investigate breach scope

### Decoy wallets (optional advanced)
Each signer maintains a "decoy" hot wallet with $1-10K visible. If coerced, they "comply" with the decoy, buying time for emergency response on real multisig.

---

## ✅ Post-ceremony validation

```bash
# Verify all 5 addresses are in the Safe
cast call $SAFE_ADDRESS "getOwners()(address[])" --rpc-url $BASE_RPC

# Should output all 5 signer addresses
# Verify threshold
cast call $SAFE_ADDRESS "getThreshold()(uint256)" --rpc-url $BASE_RPC

# Should output: 3

# Test signing (each signer signs a no-op tx)
# All 5 should successfully sign within 24 hours
```

---

## 📚 References

- Ledger ceremony guide: support.ledger.com/article/360002731113
- Trezor ceremony guide: trezor.io/learn/setup
- Gnosis Safe setup: docs.safe.global/safe-core-protocol/safe
- Coinbase Custody ceremony: youtube.com/watch?v=xdRy-7H_5oM (real example)

---

**The ceremony you're about to do will be the foundation of QUANTA's security forever.**
**Take it seriously. Don't rush. Get it right the first time.**
