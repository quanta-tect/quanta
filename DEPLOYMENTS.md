# QUANTA Deployments

## 🟢 Base Sepolia (Testnet) — LIVE v1.2

**Deployed**: June 8, 2026
**Network**: Base Sepolia (chainId 84532)
**Block Explorer**: https://sepolia.basescan.org/

### Contract Addresses

| Contract | Address | Verified |
|---|---|---|
| **QuantaToken (QTA)** | [`0x627088b570F6873c0D8f05607b12682b4D2f5fC8`](https://sepolia.basescan.org/address/0x627088b570F6873c0D8f05607b12682b4D2f5fC8#code) | ⏳ Pending |
| **AIAgentRegistry** | [`0x4d25dD8bB2ccb67bdBd3Af4e7ff0016b919cFd2A`](https://sepolia.basescan.org/address/0x4d25dD8bB2ccb67bdBd3Af4e7ff0016b919cFd2A#code) | ⏳ Pending |
| **AIPaymentChannel** | [`0xdA1C842Beb6872Cf3322447b70787773c1a64D32`](https://sepolia.basescan.org/address/0xdA1C842Beb6872Cf3322447b70787773c1a64D32#code) | ⏳ Pending |
| **AIModelMarketplace** | [`0x5c4d27207D6b22AE7Ea91C1097f50c168d2a59b5`](https://sepolia.basescan.org/address/0x5c4d27207D6b22AE7Ea91C1097f50c168d2a59b5#code) | ⏳ Pending |

### Treasury (holds 300M QTA)
`0x1d6a9512fF4A98C192A99Adea934ac3f83035953`

---

## 📊 Token Statistics

| Metric | Value |
|---|---|
| **Token Name** | Quanta |
| **Symbol** | QTA |
| **Decimals** | 18 |
| **Total Supply** | 1,000,000,000 QTA (1B) |
| **Genesis Supply** | 300,000,000 QTA (30%) |
| **Treasury** | 300,000,000 QTA |

---

## 🔒 v1.2 Security Hardening (June 8, 2026)

- H-BRIDGE-01: bridgeMint rate-limited to 1M QTA/day
- H-BRIDGE-02: bridgeBurn requires token allowance
- M-DEAD-01: Removed dead `from` param from collectAITax
- M-NONCE: Ticket nonce tracking in payment channels

---

## 🦊 Add QTA to MetaMask

1. Open MetaMask → Base Sepolia network
2. Import tokens → Paste: `0x627088b570F6873c0D8f05607b12682b4D2f5fC8`
3. Symbol: QTA, Decimals: 18
