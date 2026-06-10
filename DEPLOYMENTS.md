# QUANTA Deployments

## 🟢 Base Sepolia (Testnet) — LIVE v1.2 (KYC + Tax Reporting)

**Deployed**: June 8, 2026 (v1.2 final)
**Network**: Base Sepolia (chainId 84532)
**Block Explorer**: https://sepolia.basescan.org/

### Contract Addresses

| Contract | Address | Verified |
|---|---|---|
| **QuantaToken (QTA)** | [`0x312137fb6943F8f89F5eF0f221aA102035a16625`](https://sepolia.basescan.org/address/0x312137fb6943F8f89F5eF0f221aA102035a16625#code) | ⏳ Pending |
| **AIAgentRegistry** | [`0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB`](https://sepolia.basescan.org/address/0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB#code) | ⏳ Pending |
| **AIPaymentChannel** | [`0xF146e95b97fce1d1800F5F922AE99155711A4314`](https://sepolia.basescan.org/address/0xF146e95b97fce1d1800F5F922AE99155711A4314#code) | ⏳ Pending |
| **AIModelMarketplace** | [`0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49`](https://sepolia.basescan.org/address/0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49#code) | ⏳ Pending |

### Treasury (holds 300M QTA)
0x076FF02853F4E69989bbb9Ee61b8910B65CEc306
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

## 🔒 v1.2 Security Hardening (June 8, 2026 (v1.2 final))

- H-BRIDGE-01: bridgeMint rate-limited to 1M QTA/day
- H-BRIDGE-02: bridgeBurn requires token allowance
- M-DEAD-01: Removed dead `from` param from collectAITax
- M-NONCE: Ticket nonce tracking in payment channels

---

## 🦊 Add QTA to MetaMask

1. Open MetaMask → Base Sepolia network
2. Import tokens → Paste: `0x312137fb6943F8f89F5eF0f221aA102035a16625`
3. Symbol: QTA, Decimals: 18
