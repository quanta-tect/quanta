# HANDOFF CONTEXT - Phien 2026-06-21 (Buoi 3 - Danh Gia Lai)

> Arena.ai + Hermes + OpenHuman tiep tuc cong viec QUANTA L1.
> Copy file nay paste vao tin nhan dau tien cho Arena phien moi.

---

## CACH NOI VOI ARENA PHIEN MOI

Arena oi, minh lam viec tiep voi nhau ve du an QUANTA.
Hay doc file HANDOFF-FOR-ARENA.md trong workspace cua ban.
Huong dan minh bang cach: ban show code → minh COPY-PASTE vao terminal Linux.
Dung python3 de ghi file dai (khong dung cat EOF vi de loi terminal).
QUAN TRONG: dung chr() trong Python de tranh chat auto-linkify paths.

---

## I. THONG TIN DU AN

**Ten:** QUANTA - Quantum-safe AI-native Blockchain
**GitHub:** https://github.com/quanta-tect/quanta
**May user:** Linux (acer-Aspire-A715-76)
**Cau truc:** Layer 2 (Solidity/Base) + Layer 1 (Rust/Substrate) + Agent System

---

## II. NHUNG GI DA XONG (tinh den 2026-06-21 - Phien 3)

### Layer 2 - Da deploy + verified tren Base Sepolia
- QuantaToken (QTA), AIAgentRegistry, AIPaymentChannel, AIModelMarketplace
- TypeScript SDK demo thanh cong
- Security audit + Forta bot + War games
- Security hardening v1.0 → v1.2 (Ownable2Step, Pausable, timelock, rolling window)

### Layer 1 - 35 tests all pass (native)
[Package] | [Tests] | [Status]
---------|-------|--------
quanta-l1-crypto (Dilithium3) | 9 | PASS
pallet-pq-dilithium | 7 | PASS
pallet-pq-balances | 6 | PASS
pallet-pq-staking (PoUW) | 11 | PASS
quanta-l1-runtime | 2 | PASS
**TOTAL** | **35** | **ALL PASS**

### BREAKTHROUGH: Dilithium3 pure Rust!
- Da thay pqcrypto-dilithium (C code) bang dilithium-rs v0.2.0 (pure Rust)
- WASM-ready neu khong bi block boi transitive deps khac
- 0 unsafe blocks, 9 tests pass

### Node binary (native)
- quanta-l1-node binary build OK (1.7MB ELF)
- Van o dang minimal main.rs (7 dong)
- **CHUA co day du service** (chain_spec, cli, command, rpc, manual-seal)

### Agent System
- Hermes Agent da cai
- OpenHuman da cai, ket noi GitHub

---

## III. TRANG THAI MOI (Phien 3 - Danh Gia Lai)

### Da danh gia lai toan bo du an
- Doc het contracts (src, src-v1.1, src-v1.2), SDK, L1 Rust code, tests
- Xac dinh 4 van de nghiem trong can fix ngay
- Cap nhat HANDOFF-FOR-ARENA.md (file nay)

### Tim thay 4 VAN DE NGHIEM TRONG:

#### VAN DE 1: foundry.toml bi merge conflict (P0 - BLOCK forge test)
**File:** contracts/foundry.toml dong 31-44
**Trieu chung:** `=======` va `>>>>>>> 710acaa` markers trong TOML
**Fix:** Xoa dong 31-44 (bo conflict markers), giu lai phan dung o tren

#### VAN DE 2: Contract src vs src-v1.2 khac biet lon (P0 - security risk)
**src/** = v1.0 (co loi bao maudit: collectAITax burn from arbitrary address, no access control, no timelock)
**src-v1.2/** = v1.2 fixed (Ownable2Step, Pausable, bridge timelock, rolling window, oracle allowlist)
**foundry.toml default:** src = "src-v1.2" (dung nhung test chi co 43 dong, chua day du)
**Fix:** Can test src-v1.2 day du hoac chuyen src/ thanh symlink/copy cua src-v1.2/

#### VAN DE 3: SDK ABI mismatch voi contract (P0 - SDK khong chay duoc)
**channel.ts:** openChannel() goi 5 params (payee, nonce, deposit, challengePeriod, forceCloseAfter)
**src/AIPaymentChannel.sol:** openChannel() chi nhan 3 params (payee, nonce, deposit)
**src-v1.2/AIPaymentChannel.sol:** can kiem tra lai signature
**Fix:** Dong bo SDK voi contract ABI that te

#### VAN DE 4: getrandom 0.3.4 khong co wasm-bindgen feature (P1 - block WASM)
**runtime/Cargo.toml:** target wasm32 depends getrandom 0.3 voi "wasm-bindgen" feature
**getrandom 0.3.4:** KHONG co wasm-bindgen feature (chi co trong 0.2.x)
**Fix options:** (A) Stub getrandom 0.3, (B) Native-only execution, (C) Upgrade getrandom

---

## IV. BI BLOCK - WASM build

**Van de:** runtime WASM build fail vi transitive deps

**Root cause chain (4 issues):**
1. ~~substrate-prometheus-endpoint pulls hyper→mio~~ (FIXED via stub)
2. ~~getrandom 0.2.17 no wasm32 backend~~ (FIXED via target-specific + js feature)
3. **getrandom 0.3.4 (tu sp-keystore) KHONG co wasm32-unknown-unknown backend** (BLOCKED)
4. **foundry.toml merge conflict** (NEWLY DISCOVERED - block forge test)

**getrandom 0.3.4 khong co:**
- Feature "js" (chi co trong 0.2.x)
- Feature "wasm-bindgen" (optional dep nhung khong expose thanh feature)
- Native backend only

**Workaround options:**
- A: Stub getrandom 0.3 (partial da tao, can complete API)
- B: Native execution thay WASM (RECOMMENDED cho demo nhanh)
- C: Downgrade sp-keystore (breaking changes risk)

---

## V. VAN DE CON LAI

1. **foundry.toml merge conflict** - block forge test (P0)
2. **Contract src vs src-v1.2 mismatch** - security risk (P0)
3. **SDK ABI mismatch** - SDK khong chay duoc voi contract that (P0)
4. **WASM build** - block boi getrandom 0.3.4 (P1)
5. **Node service chua code** - can them chain_spec.rs, cli.rs, command.rs, service.rs (manual-seal), rpc.rs (P1)
6. **Testnet chua chay** - can build native + chay --dev --tmp (P1)
7. **Test coverage thap** - src-v1.2 chi co 43 dong test (P2)
8. **5 Dependabot vulnerabilities** - tren GitHub security tab (P2)
9. **Multisig chua setup** - contract ownership dang la single EOA (P2)

---

## VI. VIEC CAN LAM TIEP THEO (uu tien)

### P0 - Fix ngay (block moi thu khac):
1. **Sua foundry.toml** - xoa conflict markers dong 31-44
2. **Dong bo contracts** - chuyen src-v1.2 thanh src chinh hoac test src-v1.2 day du
3. **Fix SDK ABI** - dong bo channel.ts voi contract that te
4. **Verify forge test chay** sau khi fix foundry.toml

### P1 - Important (de chay L1):
5. **Code node service** (~500 lines) cho manual-seal mode
   - chain_spec.rs (genesis config)
   - cli.rs (CLI args)
   - command.rs (subcommands)
   - service.rs (manual-seal consensus)
   - rpc.rs (RPC endpoints)
6. **Build native:** `cargo build --release -p quanta-l1-node`
7. **Chay testnet:** `./target/release/quanta-node --dev --tmp`
8. **Test submit extrinsic** (transfer, register_key, stake) qua RPC

### P2 - Nice to have:
9. Fix WASM build (stub getrandom 0.3 hoac native-only)
10. Viet day du test cho src-v1.2 contracts
11. Setup multisig cho contract ownership
12. CI/CD pipeline (GitHub Actions)

---

## VII. CACH LAM VIEC

Dung python3 (script) de ghi file - an toan tuyet doi
Voi file ngan: echo '...' > file
KHONG dung cat EOF vi chat hay auto-linkify thanh `[X](http://X)`
QUAN TRONG: Dung chr() trong Python cho cac ky tu dac biet
- chr(91) = `[`, chr(93) = `]`
- chr(60) = `<`, chr(62) = `>`
- chr(34) = `"`, chr(92) = `\`

---

## VIII. LESSONS LEARNED (QUAN TRONG - DOC KY!)

### 1. Chat auto-linkify / HTML-escape
- `[lib.rs](http://lib.rs)` thay vi `lib.rs`
- `<T>` thanh `&lt;T&gt;`
- **Fix:** Python chr() hoac base64 encoding

### 2. Cargo [patch] syntax
- `[patch.crates-io]` chi patch crates.io deps
- `[patch."git-url"]` patch GIT deps (CANT dung crates.io section cho git deps)
- Path-based: `dep = [ path = "./stubs/..." ]`

### 3. Polkadot-sdk WASM blockers
- substrate-prometheus-endpoint pulls hyper (de cho http server)
- getrandom 0.3+ khong co wasm32-unknown-unknown backend (breaking change tu 0.2)
- sp-keystore → getrandom 0.3 → fails wasm32

### 4. Stub pattern (proven)
- Tao local crate trong workspace members
- Public API giong crate goc (compile only)
- Implementation la no-op (no real functionality)
- Patch qua git URL section
- Cargo.lock se replace git = path

### 5. Cargo version constraint conflict
- Cargo khong the giai quyet nhieu version cua cung crate (0.2/0.3/0.4) neu co feature conflicts
- Can stub rieng cho moi version neu can

### 6. Merge conflict trong foundry.toml
- Git merge conflict markers (`<<<<<`, `=====`, `>>>>`) trong TOML file → parse error
- **Luon check `git diff` truoc khi commit**

### 7. Contract version management
- Giu src/ la version cu, src-v1.2/ la version moi → dau roi, kho maintain
- **Recommendation:** Chi giu 1 version (latest) trong src/, archive version cu trong git history

---

## IX. THANH SO KY THUAT

[Tham so] | [Gia tri]
---------|---------
Dilithium | Dilithium3 (ML-DSA-65) - NIST Level 3
Public key | 1,952 bytes
Signature | 3,309 bytes
Secret key | 4,032 bytes
Block time | 6s (planned)
Token | QTA (1B supply, 18 decimals)
AccountId | DilithiumPublicKey (1952 bytes)
Consensus | Manual Seal (cho dev), Aura (TODO)
Crate moi | dilithium-rs v0.2.0 (Pure Rust WASM-ready)
Stub moi | substrate-prometheus-endpoint stub (path-based patch)

---

## X. CAU TRUC L1 (sau phien 3)
/home/acer/quanta/l1/
├── Cargo.toml (workspace, 7 members + 2 stub members)
├── Cargo.lock (stub da replace git source)
├── HANDOFF-FOR-ARENA.md (file nay)
├── crypto/ (Dilithium3 pure Rust - 9 tests PASS)
│ ├── Cargo.toml (target-specific getrandom)
│ └── src/[lib.rs], dilithium.rs
├── runtime/
│ ├── Cargo.toml (minimal features, target block cho getrandom)
│ ├── build.rs (WasmBuilder)
│ └── src/lib.rs (construct_runtime + impl_runtime_apis)
├── pallets/
│ ├── pallet-pq-dilithium/ (7 tests PASS)
│ ├── pallet-pq-balances/ (6 tests PASS)
│ └── pallet-pq-staking/ (11 tests PASS, AlreadyStaked guard)
├── node/ (MINIMAL - can code them)
│ └── src/main.rs (7 dong)
└── stubs/ (NEW trong phien 2)
├── substrate-prometheus-endpoint/ (Cargo.toml + src/lib.rs + src/sourced.rs)
└── getrandom/ (Cargo.toml + src/lib.rs - PARTIAL stub)


---

## XI. LINK QUAN TRONG

- Repo: https://github.com/quanta-tect/quanta
- Workspace zip: https://files.catbox.moe/cwjm1k.zip
- Handoff file: https://files.catbox.moe/o1y2od.md
- dilithium-rs: https://crates.io/crates/dilithium-rs
- polkadot-sdk: https://github.com/paritytech/polkadot-sdk
- getrandom docs: https://docs.rs/getrandom/

---

## XII. KEY COMMANDS

```bash
# Build native runtime (PASS)
cd /home/acer/quanta/l1
cargo check -p quanta-l1-runtime

# Build WASM (BLOCKED by getrandom 0.3.4)
cargo build -p quanta-l1-runtime --release --target wasm32-unknown-unknown

# Build native node (minimal)
cargo build --release -p quanta-l1-node

# Run dev testnet (sau khi code xong node service)
./target/release/quanta-node --dev --tmp

# Find chain pull
cargo tree --target wasm32-unknown-unknown -p quanta-l1-runtime -i X

# Forge test (BLOCKED by foundry.toml merge conflict)
cd /home/acer/quanta/contracts
forge test -vvv
```
