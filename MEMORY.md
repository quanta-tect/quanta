# MEMORY.md — QUANTA Decision Log

Append-only. Add new entries at the top.
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
