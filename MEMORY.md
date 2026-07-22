# MEMORY.md — ZEUSYXA Decision Log

Append-only. Add new entries at the top.

## Session 8 — July 19, 2026 — Rebrand: Quanta → Zeusyxa

### Major Changes
- **Project rebranded**: Quanta → Zeusyxa
- **Token renamed**: QuantaToken (QTA) → ZeusyxaToken (ZYX)
- **GitHub org**: quanta-tect → zeusyxa-tech
- **Repo**: quanta → Zeusxya
- **SDK**: @quanta/sdk → @zeusyxa/sdk

### Why Rebrand?
- "Quanta" was too common on GitHub (3+ blockchain projects)
- "Zeusyxa" is unique, memorable (Zeus + yxa)
- Better branding for "Stripe for AI Agents" positioning

### Competitor Alert
- Discovered Sigil Protocol (sigil.codes) — direct competitor
- Similar: "wallets with rules for AI agents"
- Zeusyxa advantages: post-quantum Dilithium, L1 node, x402, marketplace

### Fixes Applied
- Renamed contracts: ZeusyxaToken, IZeusyxaToken
- Renamed V2: ZeusyxaTokenV2, ZeusyxaVestingWallet, etc.
- Updated SDK: @zeusyxa/sdk
- Updated docs, grants, content
- Fixed marketplace governance + EIP-712 caching
- Synced DEPLOYMENTS.md with V2 + multisig addresses

### Remaining
- Rename repo from "Zeusxya" → "Zeusyxa" (GitHub Settings)
- Fix CI failure on commit 92ffd43
- Rename remaining Quanta test files
- Publish @zeusyxa/sdk to npm
- Submit grant proposals

## Session 7 — June 27, 2026 — Post-review security fixes + reclaim mechanism

## Session 6 — June 21, 2026 — Post-review fixes + infrastructure

## Session 5 — June 14, 2026 — Security review + test expansion

### Major Changes
1. Security review completed: 2 Medium + 2 Low issues identified
2. Test count: 87 → 150+ tests across Solidity/Rust/Node
3. Multisig ownership setup script implemented
4. Node service with 7 RPC methods added

### Key Decisions
- **Security tooling**: Forta bot + incident response runbook + security docs
- **Multisig**: Team + Treasury multisig on Base Sepolia
- **Node**: Substrate-like dev node in Rust for L1 research
- **Grant strategy**: Base, Optimism, Arbitrum, Gitcoin submissions

### File References
- `docs-security/` — complete security documentation
- `forta-bot/` — real-time monitoring bot
- `node/` — Rust dev node with JSON-RPC
- `multisig-setup/` — Gnosis Safe ownership transfer script

### Test Counts
- Solidity: 87/87 PASS
- Rust node: 16/16 PASS

## Session 4 — May 30, 2026 — SDK v1.0 + Dashboard demo

### Major Changes
1. TypeScript SDK published structure: `src/client.ts`, `src/channel.ts`, `src/marketplace.ts`
2. AgentPay dashboard: React + Vite + Tailwind
3. Real wallet test on Base Sepolia: full flow working

### Key Decisions
- **SDK uses viem** (not ethers.js) — aligns with Base ecosystem
- **Dashboard**: mock mode + real mode toggle for demos
- **Payment channel**: requires prior approve() before openChannel

### Technical Details
- SDK types: BigInt throughout (no decimal loss)
- EIP-712: chainId + verifyingContract in domain
- Dashboard: localStorage for mock mode persistence

## Session 3 — May 15, 2026 — V1.2 contracts + Marketplace governance

### Major Changes
1. AIAgentRegistry v1.2: KYC + tax reporting added
2. AIModelMarketplace: governance + royalty distribution
3. AIPaymentChannel: EIP-712 caching fix

### Key Decisions
- **Tax reporting**: on-chain metadata for jurisdictions
- **Royalty distribution**: automatic per-use splits
- **EIP-712 caching**: chainId included to prevent cross-chain replay

### Deployments
- AIAgentRegistry v1.2: 0x10aE...a5EEB
- AIPaymentChannel v1.2: 0xF146...A4314
- AIModelMarketplace v1.2: 0xFf58...dfd49

## Session 2 — April 28, 2026 — V1.1 contracts + SDK structure

### Major Changes
1. QuantaToken v1.1: burn + AI usage tax + bridge interface
2. SDK structure defined: client, channel, marketplace modules
3. Foundry test suite: 50+ tests

### Key Decisions
- **AI usage tax**: 0.1% on agent transactions (adjustable)
- **Bridge interface**:准备了QuantaBridgeHyperlane
- **Test strategy**: foundry + echidna for invariants

## Session 1 — April 10, 2026 — Project kickoff

### Major Changes
1. Project initialized: QUANTA Protocol
2. V1 contracts: QuantaToken, AIAgentRegistry, AIPaymentChannel
3. Base Sepolia deployment: 0xBfeC...0dA9a

### Key Decisions
- **Chain**: Base (Coinbase L2) for low fees + Coinbase ecosystem
- **Security model**: "Wallets with rules" — not unrestricted
- **Naming**: QuantaToken (QTA) — quantum-safe brand

### Business Strategy
- **Channels**: Direct outreach @Quanta_Protocol, Twitter/X, GitHub
- **Pricing**: $2-10K per enterprise AI agent deployment
- **Partnerships**: Base Builders, Coinbase Cloud
- **North Star**: Become the Stripe for AI Agents — payment rails + identity + compliance

### Technical Architecture
- Base Sepolia testnet → Base mainnet → Zeusyxa L1
- Multi-chain: EVM first, then L1 with Dilithium
- SDK-first: developers integrate in <10 lines of code
