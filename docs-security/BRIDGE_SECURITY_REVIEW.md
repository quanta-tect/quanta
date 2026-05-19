# 🌉 QUANTA Bridge — Security Architecture Review

> **TL;DR**: Building a custom bridge is the #1 way to lose $100M+ in crypto. We outline why, what attacks to expect, and recommend using audited infrastructure (LayerZero/Hyperlane/Axelar) for v1, with QUANTA-specific extensions for quantum-safety in v2.

---

## 📊 The bridge hack hall of shame ($3B+ stolen)

| Year | Bridge | Loss | Root cause |
|------|--------|------|-----------|
| 2022 | Ronin | $625M | 5/9 multisig signers compromised (private key theft) |
| 2022 | Wormhole | $326M | Signature verification bypass (`signers_len = 0`) |
| 2022 | Nomad | $190M | Initialization bug (root = 0x00 allowed any proof) |
| 2022 | Harmony | $100M | 2/5 multisig keys stolen |
| 2023 | Multichain | $126M | Founder controlled keys + arrest |
| 2023 | Orbit Chain | $82M | Multisig signer compromise |
| 2024 | Heco/HTX | $97M | Owner key compromise |
| 2025 | Bybit (via bridge) | $1.5B | Frontend supply chain attack |

**Pattern**: 80% of losses are **operational** (key management), 20% are **smart contract bugs**. Both must be addressed.

---

## 🏗️ QUANTA Bridge Design (Phased)

### v1 — Use existing bridges (recommended for first 12 months)

| Layer | Choice | Why |
|-------|--------|-----|
| ETH ↔ Base | Native Base bridge (OP Stack) | Audited, $5B+ TVL track record |
| Base ↔ Arbitrum | Hyperlane or LayerZero | Permissionless, battle-tested |
| Base ↔ Solana | Wormhole (post-fix) | Largest non-EVM bridge |
| To future QUANTA L1 | Custom (audited) | Required since L1 is novel |

**For v1**, QUANTA token is just ERC-20 wrapped — bridges work out of the box.

### v2 — QUANTA L1 ↔ EVM bridge (custom, post-audit)

```
┌────────────────────────────────────────────────────────────────┐
│                  QUANTA L1 (Dilithium signatures)              │
│  ┌─────────────────┐                                            │
│  │ BridgeVault.qta │  Lock QTA when bridging to EVM            │
│  └────────┬────────┘                                            │
└───────────│────────────────────────────────────────────────────┘
            │ Zero-knowledge state proofs
            │ + multi-validator attestations
            │ + 24h challenge period
            ▼
┌────────────────────────────────────────────────────────────────┐
│                          EVM Chain (Base)                       │
│  ┌─────────────────┐    ┌──────────────────────┐               │
│  │  QuantaBridge   │───▶│  QuantaToken (ERC20) │               │
│  │  (Verifier)     │    │  bridgeMint()        │               │
│  └─────────────────┘    └──────────────────────┘               │
└────────────────────────────────────────────────────────────────┘
```

---

## 🎯 Top 15 Bridge Attack Vectors (mitigation checklist)

### 1. ⚠️ CRITICAL: Validator key compromise

**Attack**: Steal N-of-M signing keys (Ronin: 5/9)

**Mitigations**:
- [ ] Minimum 7/11 multisig (not 5/9, not 3/5)
- [ ] Signers MUST be geographically distributed (no 2 in same country)
- [ ] Signers MUST be from different organizations (no co-employees)
- [ ] Hardware wallets MANDATORY (Ledger Stax or Trezor Safe 5)
- [ ] Key ceremony recorded + audited
- [ ] Annual key rotation
- [ ] Public signer identities (accountability)
- [ ] Bond/slashing for signers (skin in game)

### 2. ⚠️ CRITICAL: Signature verification bypass (Wormhole)

**Attack**: `verifySignatures(sigs)` returns true when `sigs.length == 0`

**Mitigations**:
- [ ] `require(sigs.length >= QUORUM, "insufficient signers")`
- [ ] Use OpenZeppelin's `ECDSA.recover` (battle-tested)
- [ ] Reject signature `s` in upper half of secp256k1 (malleability)
- [ ] Verify each signature is from DIFFERENT signer (no duplicates)
- [ ] EIP-712 typed data (chain-bound, prevents cross-chain replay)
- [ ] Formal verification of verifier contract (Halmos / Certora)

### 3. ⚠️ CRITICAL: Replay attacks across chains

**Attack**: Valid mint message on Chain A replayed on Chain B

**Mitigations**:
- [ ] Domain separator includes `chainId` and `verifyingContract`
- [ ] Nonces tracked per source-chain + destination-chain pair
- [ ] Replay tracking in `mapping(bytes32 => bool) usedNonces`
- [ ] Time-bound messages (expire after 24h)

### 4. ⚠️ CRITICAL: Initialization vulnerabilities (Nomad)

**Attack**: Default uninitialized values allow any proof

**Mitigations**:
- [ ] `initializer` modifier on init functions (OpenZeppelin)
- [ ] Constructor sets root to non-zero value
- [ ] Test: assert root != bytes32(0) after init
- [ ] Disable any "skip verification" debug paths in production builds

### 5. 🔴 HIGH: Reentrancy in bridgeOut → callback

**Attack**: Malicious token's transfer hook re-enters bridge

**Mitigations**:
- [ ] `nonReentrant` on every external function
- [ ] CEI order strictly enforced
- [ ] Pull pattern for token transfers
- [ ] Whitelist of bridgeable tokens

### 6. 🔴 HIGH: Inflation via misminted tokens

**Attack**: Bug allows minting more than locked on source chain

**Mitigations**:
- [ ] Track `lockedOnSourceChain` mirror; assert `mintedOnDest <= locked`
- [ ] Rate limit: max X tokens minted per hour
- [ ] Auto-pause on anomaly (>2σ deviation from historical pattern)
- [ ] Reconciliation cron-job (off-chain) that pages on mismatch

### 7. 🔴 HIGH: Frontrunning withdrawal proofs

**Attack**: Watch mempool for proof submission, MEV extract

**Mitigations**:
- [ ] Commit-reveal scheme for withdrawals
- [ ] Or: encrypted mempool (Flashbots Protect)
- [ ] Or: proof binding to recipient address (can't be re-routed)

### 8. 🔴 HIGH: Censorship / liveness

**Attack**: Validators refuse to relay legitimate withdrawals

**Mitigations**:
- [ ] Permissionless relayer set (anyone can submit valid proof)
- [ ] Multiple independent relayers
- [ ] Emergency withdrawal directly from vault contract (after Nx delay)
- [ ] Public attestation API (proves no censorship)

### 9. 🟡 MEDIUM: Gas griefing on destination

**Attack**: Force expensive computation on dest chain when minting

**Mitigations**:
- [ ] Gas refund to relayer
- [ ] Minimum gas reserve check before external calls
- [ ] Cap loop iterations

### 10. 🟡 MEDIUM: Fee manipulation

**Attack**: Front-run fee updates to extract value

**Mitigations**:
- [ ] Fees changes via timelock (48h)
- [ ] User specifies max acceptable fee in tx (slippage)

### 11. 🟡 MEDIUM: Storage collision in proxy

**Attack**: Upgrade introduces storage layout change → corruption

**Mitigations**:
- [ ] Use UUPS proxy with storage gap
- [ ] Storage layout test in CI (`forge inspect storage-layout`)
- [ ] No upgradability OR upgrades behind 7-day timelock + multisig

### 12. 🟡 MEDIUM: Oracle manipulation

**Attack**: Manipulate price oracle to game bridge fees

**Mitigations**:
- [ ] Chainlink or Uniswap V3 TWAP (not spot price)
- [ ] Sanity bounds (reject prices >10x deviation)

### 13. 🔵 LOW: Dust DoS

**Attack**: Tiny bridge transactions clog relayer queue

**Mitigations**:
- [ ] `MIN_BRIDGE_AMOUNT` (e.g., 10 QTA)
- [ ] Bridging fee covers gas

### 14. 🔵 LOW: Token whitelisting

**Attack**: Bridge accepts arbitrary ERC-20s → fake tokens drain real liquidity

**Mitigations**:
- [ ] Whitelist (governance-controlled) of bridgeable tokens
- [ ] Default: only QTA + canonical wrapped versions

### 15. 🟣 OPERATIONAL: Frontend supply chain (Bybit-style)

**Attack**: Compromise the website → users sign malicious tx

**Mitigations**:
- [ ] Subresource integrity (SRI) on all scripts
- [ ] Reproducible builds, signed releases
- [ ] IPFS-hosted frontend with pinned hash
- [ ] Hardware wallet "blind signing" warnings
- [ ] Transaction simulation in wallet (Stelo, Pocket Universe)

---

## 🛡️ Defense-in-depth: Layered security

```
Layer 1: Cryptographic        → Dilithium sigs, Merkle proofs
Layer 2: Economic             → Bond/slashing, insurance fund
Layer 3: Operational          → Multisig, geographic distribution
Layer 4: Monitoring           → Real-time anomaly detection
Layer 5: Recovery             → Pause + emergency exit + insurance payout
Layer 6: Insurance            → Nexus Mutual, Sherlock
```

---

## 🔐 Cryptographic Design (when building custom)

### Quantum-safe attestations

For QUANTA L1 → EVM bridge, attestations should use **Dilithium signatures** for forward-secrecy:

```solidity
contract QuantaBridgeVerifier {
    // Precompile address for Dilithium verification
    // (Custom precompile to be added to Base/Ethereum, or use SNARK proof of verification)
    address constant DILITHIUM_PRECOMPILE = address(0x0a);

    function verifyAttestation(
        bytes32 messageHash,
        bytes calldata dilithiumSig,
        bytes calldata validatorPubKey
    ) external view returns (bool) {
        (bool ok, bytes memory result) = DILITHIUM_PRECOMPILE.staticcall(
            abi.encode(messageHash, dilithiumSig, validatorPubKey)
        );
        return ok && abi.decode(result, (bool));
    }
}
```

**Reality check**: No EVM chain has Dilithium precompile yet. Alternatives:
1. **zkSNARK of Dilithium verification** (works today, ~500K gas per proof)
2. **Hybrid**: ECDSA + Dilithium (verify both; ECDSA on-chain, Dilithium off-chain proof)
3. **Wait for L1 upgrade**: EIP for PQ precompiles being discussed for 2027+

### Recommended: ZK-bridge with hybrid sigs

```
QUANTA L1                            EVM Chain
─────────                            ─────────
1. User locks QTA
2. Validators sign attestation
   (both Ed25519 + Dilithium)
3. SNARK prover compresses:
   - Block headers proof
   - Multi-sig validity
   - State inclusion
                          ───────▶  4. Verify SNARK (~500K gas)
                                    5. Mint wrapped QTA
```

---

## 💰 Economic Security

### Slashing parameters

| Offense | Slash % | Min stake |
|---------|---------|-----------|
| Double-signing | 100% | 10,000 QTA |
| Signing invalid proof | 100% | 10,000 QTA |
| Censorship (proven) | 20% | 10,000 QTA |
| Liveness fault (24h offline) | 5% | 10,000 QTA |

### Insurance fund

- 5% of bridge fees → insurance pool
- Cap: $50M (sized for largest historical exploit)
- Governed by community vote on payouts

### Rate limits (anti-drain)

```solidity
// Per-validator rate limit
uint256 public constant MAX_MINT_PER_HOUR_PER_VALIDATOR = 100_000 ether;

// Global rate limit
uint256 public constant MAX_MINT_PER_HOUR_GLOBAL = 1_000_000 ether;

// Auto-pause if exceeded
modifier rateLimit(uint256 amount) {
    if (block.timestamp / 1 hours != lastHour) {
        lastHour = block.timestamp / 1 hours;
        hourlyMinted = 0;
    }
    require(hourlyMinted + amount <= MAX_MINT_PER_HOUR_GLOBAL, "rate limit");
    if (hourlyMinted + amount > AUTO_PAUSE_THRESHOLD) {
        _pause();
    }
    hourlyMinted += amount;
    _;
}
```

---

## 📋 Pre-Launch Bridge Checklist

### Code
- [ ] No custom signature verification — use OpenZeppelin
- [ ] EIP-712 typed data signing
- [ ] All admin functions behind 48h timelock
- [ ] Rate limits on all mint paths
- [ ] Pause functionality + multiple pausers
- [ ] Emergency withdrawal after long delay (90 days)
- [ ] Storage layout test
- [ ] >95% test coverage
- [ ] Echidna invariants for solvency
- [ ] Halmos formal verification of verifier

### Operational
- [ ] 7/11 multisig minimum
- [ ] Hardware wallets verified for all signers
- [ ] Signers from ≥5 organizations
- [ ] Signers from ≥4 continents
- [ ] Key ceremony recorded
- [ ] Annual rotation schedule
- [ ] On-call rotation 24/7
- [ ] Incident response runbook (see INCIDENT_RESPONSE.md)
- [ ] War game exercises quarterly

### Audit
- [ ] Audit by ≥2 firms (Trail of Bits + Halborn + Spearbit ideal)
- [ ] Code4rena public contest ($500K min)
- [ ] Immunefi bug bounty ($1M+ for criticals)
- [ ] 30-day public review period

### Monitoring
- [ ] Tenderly alerts on every bridge tx
- [ ] Forta detection bots
- [ ] Block-by-block solvency reconciliation
- [ ] PagerDuty integration
- [ ] Public status page

### Insurance
- [ ] Nexus Mutual cover purchased
- [ ] Sherlock or Sherlock-like protocol coverage
- [ ] Treasury reserve = 10% of TVL

---

## 🚨 Incident Response (first 60 minutes)

If anomaly detected (e.g., unexpected mint):

```
T+00:00  Forta/Tenderly alert fires → PagerDuty
T+00:02  On-call engineer acknowledges
T+00:05  Call pause() on bridge (1/N multisig action)
T+00:15  Verify exploit on Tenderly forks
T+00:30  Public statement on Twitter + Discord (no details yet)
T+01:00  Full root cause analysis published
T+02:00  Decide: roll forward fix OR migrate users
T+24:00  Post-mortem published
T+72:00  Insurance claims process opened
```

---

## 📚 References

- **Trail of Bits Bridge Security Checklist**: github.com/crytic/building-secure-contracts
- **Vitalik on bridges**: vitalik.eth.limo/general/2022/01/07/sidechain.html ("never use bridges except for short-term")
- **Wormhole post-mortem**: certik.com/resources/blog/wormhole-bridge-exploit
- **Ronin post-mortem**: roninnetwork.medium.com/community-alert-ronin-validators-compromised
- **Nomad post-mortem**: nomad.xyz/blog/...

---

## ⚖️ Final recommendation

**For QUANTA v1 (next 12 months):**
1. ✅ Use **Hyperlane** for permissionless EVM↔EVM (free, audited)
2. ✅ Use **native Base bridge** for ETH↔Base
3. ❌ DO NOT build custom bridge yet
4. ✅ Focus on building product value; bridges come later

**For QUANTA v2 (after L1 launch):**
1. ✅ Build custom bridge L1↔EVM (required since L1 is novel)
2. ✅ ZK proof of Dilithium signatures (avoid waiting for EVM precompile)
3. ✅ Hybrid with audited partner (LayerZero co-design)
4. ✅ Phased TVL caps: $100K → $1M → $10M → $100M over 12 months

**Bridges that scale safely take YEARS to build properly. Don't rush it.**
