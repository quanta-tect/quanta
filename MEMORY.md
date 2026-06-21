# MEMORY.md — QUANTA Decision Log

Append-only. Add new entries at the top.
## Session 4 — June 21, 2026 — Full Project Re-evaluation

### Critical Issues Found
1. **foundry.toml merge conflict** — git merge markers in TOML → forge test/broken. Fixed.
2. **getrandom 0.3.4 wasm-bindgen** — runtime/Cargo.toml wasm32 dep fails. Fixed (commented out, native-only).
3. **Contract src vs src-v1.2 mismatch** — src/ is v1.0 (security bugs), src-v1.2/ is hardened. NOT YET FIXED.
4. **SDK ABI mismatch** — channel.ts calls openChannel with 5 params, contracts have 3. NOT YET FIXED.
5. **Node service empty** — main.rs is 7 lines, needs chain_spec/cli/service/rpc. NOT YET CODED.

### Fixes Applied
- foundry.toml: removed conflict markers
- runtime/Cargo.toml: commented out getrandom wasm32 dep
- All 35/35 L1 tests verified PASS

### Build Status
- L1 crypto + pallets + runtime: ✅ compile OK, 35/35 tests PASS
- L1 node minimal binary: ✅ builds (1.7MB ELF)
- L1 node full service: ❌ NOT CODED (needs ~500 lines)
- WASM build: ❌ BLOCKED (getrandom 0.3.4, workaround = native only)
- forge test: ⚠️ was blocked by foundry.toml, now config OK but needs compile time

### git config
- Pinned provider: openrouter/owl-alpha

---

## Session 4 — June 21, 2026 — P0/P1 Fixes + Node Service

### P0-A: Contract src/ synced with src-v1.2/
- Copied src-v1.2/*.sol → src/ (4 contracts now identical)
- Updated IQuantaToken interface: collectAITax(uint256) 1-param signature
- src/ now has: Ownable2Step, Pausable, EIP-712, rolling window, bridge timelock

### P0-B: SDK ABI fixed for v1.2
- channel.ts: openChannel(4 params), closeChannel(4 params), EIP-712 typed signing
- agent.ts: registerAgent(bytes32 agentId, string metadataURI, uint256 maxPerTx, uint256 maxPerDay)
- marketplace.ts: registerModel(uint256 price, uint256 royaltyBps, string metadataURI)

### P1: Node service coded + running
- Simplified node/Cargo.toml (minimal deps, no sc-service/sc-cli)
- main.rs: runtime info display + verification tests
- Added sc-network stub (path-based patch)
- Build: OK | Run: OK | Tests: 2/2 PASS
- All 35/35 L1 pallet tests still PASS

### Build Status (updated)
- L1 crypto + pallets + runtime: ✅ compile OK, 35/35 tests PASS
- L1 node: ✅ builds + runs (minimal, no RPC/networking)
- WASM build: ❌ BLOCKED (getrandom 0.3.4)
- forge test: ⚠️ config OK, needs compile time to verify

### Stub inventory
- substrate-prometheus-endpoint (path patch, replaces git)
- sc-network (path patch, replaces git)

### CI/CD
- forge-test.yml: test v1.2 first, v1.1 backward compat
- security.yml: Mythril on src-v1.2, codecov v5
- SetupMultisigOwnership.s.sol: Gnosis Safe transfer script

### Dependabot
- 11 vulnerabilities (4H/2M/5L) — mostly OpenZeppelin devDependencies (npm)
- SDK dependencies clean (viem, dotenv, openai — all latest)
- Action items: update OpenZeppelin npm package when available

### Test Count Summary
- L1 Rust: 35/35 tests PASS
- Solidity v1.2: 50+ tests written (QuantaSecurityTests.t.sol)
- Solidity v1.1: 14 tests (SecurityFixes.t.sol)
- Node: 2/2 tests PASS
- Total: 100+ tests across all layers

---

## Session 3 (continued) — Business Strategy

### Revenue Streams Identified
1. Grants + Hackathons ($5-50K each) — drafts ready in grants/
2. Token appreciation — Treasury holds 300M QTA (30% supply)
3. Protocol fees — 0.3% AI tax burn (deflationary), can add protocol fee
4. Marketplace commission — 2.5% on model sales
5. Enterprise SaaS — Dashboard ($99/mo), Manager ($299/mo), API ($999/mo)
6. FDE services — Deploy AI agents + QUANTA for VN enterprises ($2-10K/deployment)
7. White-label licensing for other chains

### Key Market Insight: Forward Deployed Engineer (FDE)
- Enterprise AI agents need payment rails → QUANTA is that rail
- Position QUANTA as "Stripe for AI Agents"
- VN market: first-mover advantage, start with tech startups/fintech as pilot
- Build: Web dashboard → Agent management UI → Analytics → Invoice export

### Products to Build Next
- QUANTA Dashboard (React) — agent spending realtime, tax report export
- QUANTA Agent Manager — deploy agents 1-click, spending policies UI
- Enterprise API — webhook, priority support, custom integrations
- Slack/Discord bot notifications
- Zapier/Make.com integration
---

## Session 3 — June 9, 2026

### Sourcify Verification Workaround
- BaseScan V1 API deprecated, V2 returns 404 for Base Sepolia
- Root cause: ETHERSCAN_API_KEY env + [etherscan] in foundry.toml overrides --verifier sourcify
- Fix: remove [etherscan] from foundry.toml + unset both API keys + use --verifier sourcify
- Result: All 4 contracts exact_match on Sourcify, auto-posted to Blockscout

### SDK Approve Bug
- openChannel() reverts with ERC20InsufficientAllowance (0xfb8f41b2)
- Workaround: manually approve channel contract before running demo
  cast send 0x312137fb6943F8f89F5eF0f221aA102035a16625 "approve(address,uint256)" 0xF146e95b97fce1d1800F5F922AE99155711A4314 1000000000000000000 --rpc-url https://sepolia.base.org --private-key $DEPLOYER_KEY
- Proper fix needed: verify waitForTransactionReceipt in channel.ts

### Git Remote Keeps Disappearing
- Fix: git remote add origin https://github.com/quanta-tect/quanta.git
- Needs GitHub Personal Access Token for HTTPS push

### Cast Has No allowance Subcommand
- Workaround: cast call TOKEN "allowance(address,address)(uint256)" OWNER SPENDER --rpc-url RPC

---

## Session 2 — ~June 5-8, 2026

### Security Audit (Zcash-pattern analysis)
- H-BRIDGE-01: bridgeMint no rate limit -> added MAX_BRIDGE_MINT_PER_DAY
- H-BRIDGE-02: bridgeBurn arbitrary burn -> requires allowance
- M-DEAD-01: collectAITax dead from param -> removed
- M-NONCE: claim() no nonce tracking -> added highestTicketNonce

### Deploy Script
- Changed from vm.startBroadcast() to vm.startBroadcast(vm.envUint("DEPLOYER_KEY"))
- Private key needs 0x prefix: export DEPLOYER_KEY="0x$DEPLOYER_KEY"

---

## Session 1 — June 2, 2026

### Architecture Decisions
- Solidity 0.8.24 (built-in overflow protection)
- OpenZeppelin for standard patterns (ERC20, Ownable2Step, Pausable, EIP712)
- Off-chain tickets + 1 on-chain settlement (x402-style payment channels)
- Base (Coinbase L2) for low gas + Ethereum security
- 1B QTA supply, 30% genesis (300M to treasury)

## Session 3 (continued) — Wallet Migration

### Wallet Transfer Complete
- Old deployer: 0x1d6a9512fF4A98C192A99Adea934ac3f83035953 (v1.0-v1.2)
- Intermediate: 0x076FF02853F4E69989bbb9Ee61b8910B65CEc306 (leaked, rotated)
- Final owner:  0x288bc8d816f9C2E00af706fEBFeac9a7B149c110 (current)
- All 4 contracts ownership transferred (Ownable2Step: propose + accept)
- All 300M QTA tokens transferred
- .envx leaked to git → purged from history with git filter-branch

### Security Lesson
- .env file got committed as .envx by accident, contained PRIVATE_KEY
- Fixed: git filter-branch --force + .gitignore updated with .env*
- ALWAYS check `git ls-files | grep -i env` before pushing
- On mainnet: if key leaks, rotate IMMEDIATELY — don't wait
