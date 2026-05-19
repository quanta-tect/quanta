# Security Policy

## 🛡️ Reporting a vulnerability

**DO NOT open a public issue for security bugs.**

### How to report

| Severity | Method | Response time |
|----------|--------|---------------|
| Critical (funds at risk) | Email `security@quanta.foundation` (PGP key below) | 24 hours |
| High | Email `security@quanta.foundation` | 72 hours |
| Medium / Low | GitHub Security Advisory | 1 week |

### Bug bounty program

When mainnet is live, bounties via [Immunefi](https://immunefi.com):

| Severity | Reward |
|----------|--------|
| 🔴 Critical (loss of funds, infinite mint) | Up to **$500,000** |
| 🟠 High (locked funds, governance bypass) | Up to **$100,000** |
| 🟡 Medium | Up to **$10,000** |
| 🔵 Low | Up to **$1,000** |

Currently (pre-mainnet): goodwill rewards based on Foundation discretion.

## 📜 Audit history

| Date | Auditor | Scope | Report |
|------|---------|-------|--------|
| 2026-05-16 | Internal pre-review | All contracts v1.0 | [SECURITY_AUDIT.md](./SECURITY_AUDIT.md) |
| TBD | Trail of Bits (planned) | v1.1 before mainnet | — |
| TBD | Halborn (planned) | Bridge + L1 | — |

## 🚨 Known limitations (transparent disclosure)

1. **Quantum-safety on EVM is partial**: Current Solidity contracts use ECDSA (inherited from Ethereum). Full Dilithium signatures only on future L1.
2. **Owner is currently EOA on testnet**: Mainnet deployment WILL use Gnosis Safe multisig 3/5 + 48h timelock.
3. **No formal verification yet**: Planned for v2.
4. **Cross-chain bridges are MVP**: Production will use audited bridges (LayerZero/Hyperlane), not custom code.

## 🔐 Operational security guidelines

### For users
- Use hardware wallet (Ledger / Trezor) for stake > $1000
- Never share seed phrase, PRIVATE_KEY environment variable, or signed messages
- Verify contract addresses against `DEPLOYMENTS.md` (signed by foundation keys)
- For AI agents: use FRESH wallet per agent, set conservative spending policies

### For developers integrating QUANTA SDK
```ts
// ❌ NEVER
const wallet = new Wallet(process.env.PRIVATE_KEY || "0xfallback...");

// ✅ ALWAYS
if (!process.env.PRIVATE_KEY) throw new Error("PRIVATE_KEY required");
const wallet = new Wallet(process.env.PRIVATE_KEY);

// ✅ BETTER: use a KMS / hardware signer
const wallet = await AwsKmsSigner.create(process.env.AWS_KMS_KEY_ID);

// ✅ BEST: use account abstraction with session keys
const wallet = await SessionKey.fromMainKey(mainKey, { 
  maxSpend: parseEther("1"), validUntil: Date.now() + 3600_000 
});
```

## 📚 PGP key (security@quanta.foundation)

```
-----BEGIN PGP PUBLIC KEY BLOCK-----
[Will be generated and published on foundation website]
-----END PGP PUBLIC KEY BLOCK-----
```

Fingerprint: `TBD — generate on day 1`

## ⚖️ Responsible disclosure

We follow [responsible disclosure](https://en.wikipedia.org/wiki/Responsible_disclosure):
1. Report privately, allow time to fix
2. We commit to: acknowledge in 24h, patch ASAP, credit researcher publicly
3. CVE assigned for confirmed vulnerabilities
4. Hall of Fame at [quanta.foundation/security/hall-of-fame](#)

---

**Last updated**: 2026-05-16
