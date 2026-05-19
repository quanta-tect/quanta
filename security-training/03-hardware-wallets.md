# 🔒 Course 03: Hardware Wallet Operations

**Audience**: Power users + team members
**Duration**: 60 minutes

> **TL;DR**: Hardware wallet = best ROI security investment. $130 saves potentially $1M+.

## Why hardware wallets

| Threat | Software wallet | Hardware wallet |
|--------|-----------------|-----------------|
| Computer malware | ❌ Vulnerable | ✅ Safe |
| Browser hack | ❌ Vulnerable | ✅ Safe |
| Phishing site | ❌ Vulnerable | ⚠️ Partial (still need to verify on device) |
| Physical theft | Same risk | Same risk |
| Seed phrase leak | Same risk | Same risk |

**Key insight**: HW wallet keeps **private keys offline**. To sign, you physically press buttons. Even on a fully compromised computer, attacker can't sign without you.

## Setup checklist (see `multisig-setup/HARDWARE_WALLET_CEREMONY.md` for full ceremony)

- [ ] Buy direct from manufacturer (NEVER eBay/Amazon 3rd party)
- [ ] Verify factory seal on box
- [ ] Initialize as NEW device
- [ ] Set strong PIN (8 digits, not birthday)
- [ ] Write seed phrase on **steel backup** (not paper)
- [ ] Test recovery: reset device, restore from backup
- [ ] Store in 2 secure physical locations
- [ ] Connect to MetaMask in hardware mode
- [ ] Test small transaction
- [ ] Document ownership/inheritance plan

## Daily operations

### Sending a transaction
1. MetaMask: "Send" with hardware wallet selected
2. **Hardware wallet displays tx details on its screen**
3. **VERIFY**:
   - Recipient address (compare first 4 + last 4 chars with what you intended)
   - Amount
   - Network (chainId)
   - Gas
4. Press confirm button on DEVICE
5. Tx broadcasts

### What NOT to do
- ❌ "Blind signing" mode (turn OFF on Ledger settings)
- ❌ Approve unlimited spend without thinking
- ❌ Skip device verification — that's the WHOLE POINT

## Brand comparison

| Wallet | Pros | Cons | Best for |
|--------|------|------|----------|
| **Ledger Nano X** | Most apps, mobile via BT | Closed firmware, 2020 data leak | General use |
| **Trezor Safe 3** | Open source firmware | Smaller screen | Privacy advocates |
| **GridPlus Lattice1** | Large screen, multisig-friendly | $397 | Multisig signers |
| **Keystone 3 Pro** | Air-gapped (QR code) | Slower | Maximum security |
| **SafePal S1** | Cheap ($49) | Less polish | Budget |

**Recommendation**: For multisig, use 5 DIFFERENT brands across signers (vendor diversity).

## Common mistakes

| Mistake | Lesson |
|---------|--------|
| Photographed seed phrase "as backup" | Phone cloud = attacker access |
| Typed seed into wallet recovery website | That was the scam |
| Stored seed on phone notes | Apps can read |
| Used 4-digit PIN | Brute-forced in seconds |
| Never tested recovery | Found out backup was wrong DURING crisis |
| Bought used from "deal" | Pre-loaded with attacker seed |

## Recovery scenarios

| Scenario | Action |
|----------|--------|
| Device broken | Buy new device, restore from seed |
| PIN forgotten | Factory reset, restore from seed |
| Device lost | Restore on new device, move funds to fresh wallet |
| Device stolen | If PIN unknown, attacker can't access. But move funds NOW. |
| Seed phrase lost | Funds may be locked forever. Move what you can while device works. |
| Manufacturer hacked | Move to different brand immediately |

## Pro tips

1. **Backup wallet**: Buy 2 of same model. If primary dies, backup is ready.
2. **Inheritance**: Tell ONE trusted person where backup is (not the seed itself).
3. **Update firmware**: Quarterly check, install latest.
4. **Disconnect from MetaMask** when not using (reduces attack surface).
5. **Use separate device** for hot/cold wallets (different physical devices).
6. **Annual full recovery drill**: Wipe device, restore from backup, verify works.

## TL;DR

- Hardware wallet for ANY amount > $500
- Buy direct from manufacturer
- Setup carefully (see ceremony doc)
- Verify EVERY tx on device screen
- Steel backup, 2 locations
- Test recovery annually

**This is the single highest-ROI security action you can take in crypto.**
