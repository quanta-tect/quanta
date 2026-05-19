# 🚀 QUANTA — 7-Day Launch Guide (Budget: $0-15)

> **Goal by end of week**: Real token on Base Sepolia testnet, growing Twitter following, active Discord, viral demo video, ready for mainnet launch.
>
> **Total cost**: $0-15 (only if you want a `.xyz` domain ~$1-3/year, everything else 100% free).
>
> **Requirements**: A computer (Mac/Linux/Windows + WSL), internet, 2-4 hours per day.

---

## 🧰 Pre-Day 1 prep (tonight, 30 min)

### A. Install basic tools

```bash
# 1. Node.js (for SDK + frontend)
# Mac: brew install node
# Linux/WSL:
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node --version  # must be >= v20
npm --version

# 2. Git
# Mac: already installed or: brew install git
# Linux: sudo apt install git
git --version

# 3. Python (for prototype)
python3 --version  # must be >= 3.10
```

### B. Create 3 free accounts

| Account | Sign up at | Purpose | Cost |
|---------|-----------|---------|------|
| **GitHub** | github.com | Host code, social proof | Free |
| **MetaMask** | metamask.io | Wallet to deploy contracts | Free |
| **New Gmail** | gmail.com | Dedicated for project (separate from personal) | Free |

> 💡 **MetaMask tip**: Create a SEPARATE wallet for dev/deploy. **Never use your personal wallet**. Save the seed phrase to `~/.quanta-deploy-seed.txt` (chmod 600) + 1 paper copy.

---

## 📅 DAY 1 — Brand identity setup (3-4h, $0-3)

### 🎯 End-of-day goal
- ✅ Project name + logo + color scheme confirmed
- ✅ Public GitHub repo
- ✅ Twitter/X handle reserved (you have this already!)
- ✅ (Optional) Cheap domain

### Step 1.1 — Confirm name + branding (30 min)

You already have **QUANTA**. Verify availability:

```bash
# Open browser, check:
# - twitter.com/QuantaCoin     (search to see if anyone uses it)
# - github.com/quanta-coin
# - quanta.xyz / quantacoin.xyz
```

**If QUANTA is taken**, backup names (most are free as of 2026-05):
- **QBIT** — Quantum Bit
- **QSAFE** — Quantum Safe
- **AETHR** — Aether Network
- **NOVA** or **NOVAQ**
- **PARQ** — Post-quantum AI Resilient Quanta

> ⚠️ **Important**: Don't spend more than 30 minutes on this. Name isn't make-or-break.

### Step 1.2 — Create logo (free, 30 min)

3 free options:

1. **Recraft.ai** (free tier) — prompt: *"Minimalist logo, atom symbol ⚛ in purple-cyan gradient, modern crypto style, vector"*
2. **Hatchful by Shopify** (hatchful.shopify.com) — free template logos
3. **DALL-E free trial** on bing.com/create (15 free per day)

Save logo in these formats:
- `logo.png` (512×512, transparent bg)
- `logo-banner.png` (1500×500 for Twitter banner)
- `favicon.ico` (32×32)

### Step 1.3 — Set up Twitter/X (you already have it!)

Update your profile:

```
Username: @QuantaCoin (or your chosen name)
Display name: QUANTA ⚛
Bio: Quantum-safe • AI-native blockchain. Currency that works for humans AND AI agents. Devnet: [link]. Code: github.com/...
Location: Singapore (or anywhere - just branding)
Website: GitHub URL or landing page
Avatar: logo.png
Banner: logo-banner.png
```

**Pro tip**: Your first tweet should NOT be the launch thread. Post 3-5 "warm up" tweets over 2-3 days first:
- Tweet 1: "Building something at the intersection of quantum + AI. Stay tuned 👀"
- Tweet 2: Quote a recent quantum computing breakthrough article
- Tweet 3: Quote an AI agent article

→ Twitter's algorithm needs to see "active" account before pushing the launch thread.

### Step 1.4 — GitHub repo (you already pushed!)

Update your repo settings on GitHub.com:

- **About**: "Quantum-safe AI-native blockchain — whitepaper, prototype, contracts, SDK"
- **Topics**: `blockchain`, `cryptocurrency`, `quantum-resistant`, `post-quantum-cryptography`, `ai-agents`, `web3`, `solidity`, `dilithium`, `proof-of-useful-work`
- ⭐ Star your own repo (everyone does this)
- 📝 Add a Description (1 sentence)
- 🌐 Add Website URL (later when landing page is live)

Verify `.gitignore` is correct:

```bash
cat .gitignore
# Should include:
# __pycache__/
# *.pyc
# node_modules/
# .env
# .env.local
# .DS_Store
# contracts/out/
# contracts/cache/
# contracts/lib/
# sdk/dist/
# *.log
# .quanta-deploy-seed.txt
```

### Step 1.5 — Domain (optional, $1-15/year)

**100% FREE**: Use GitHub Pages → `https://YOUR_USERNAME.github.io/quanta`

**Pay $1-3 (recommended)**:
- **Spaceship.com**: `.xyz` usually $1-3/year
- **Cloudflare Registrar**: at-cost pricing (~$8-10 for .com, no markup)
- **Porkbun**: cheap renewals

> ❌ **Avoid**: GoDaddy (high renewals), Wix (lock-in), "free" domains like .tk/.ml (blocked everywhere, not professional).

If you buy: point DNS to GitHub Pages (4 A records: `185.199.108-111.153`).

### ✅ End of Day 1 you have:
- Code on public GitHub
- Twitter with logo + bio + 2-3 warm-up tweets
- Logo + banner
- (Optional) Domain pointing to GitHub Pages

---

## 📅 DAY 2 — Smart contract local testing (3-4h, $0)

### 🎯 Goal
- ✅ Foundry installed, smart contracts compile + tests pass
- ✅ Understand the code you'll deploy
- ✅ Adjust important variables (treasury address, tax rate)

### Step 2.1 — Install Foundry (5 min)

```bash
# One command:
curl -L https://foundry.paradigm.xyz | bash

# After it completes, restart terminal or:
source ~/.bashrc  # or ~/.zshrc

# Install Foundry tools
foundryup

# Verify
forge --version  # Must show version
cast --version
anvil --version
```

### Step 2.2 — Install dependencies (10 min)

```bash
cd /path/to/quanta/contracts

# Install OpenZeppelin contracts (free, open source)
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Install forge-std (testing helpers)
forge install foundry-rs/forge-std --no-commit

# Build
forge build
# → Should show "Compiling X files with..." without errors
```

> ⚠️ **If you get errors**: Usually Solidity version mismatch. Open `foundry.toml`, ensure `solc = "0.8.24"`.

### Step 2.3 — Run security regression tests (10 min)

```bash
# Test the v1.1 contracts (with security fixes)
forge test --match-path "test-v1.1/**" -vv

# Should see:
# Running 13 tests for test-v1.1/SecurityFixes.t.sol:SecurityFixesTest
# [PASS] test_C02_OracleCanAdjustReputation()
# [PASS] test_C02_RandomCannotAdjustReputation()
# [PASS] test_C03_ForceCloseBlockedAfterClaim()
# [PASS] test_C03_ForceCloseWorksWhenNoClaim()
# [PASS] test_C04_SignatureBoundToChain()
# [PASS] test_C06_CannotBurnFromArbitraryAddress()
# [PASS] test_C06_CollectorCanBurnFromSelf()
# [PASS] test_H01_BridgeChangeRequiresTimelock()
# [PASS] test_H04_PauseStopsTransfers()
# [PASS] test_H05_RegistrationFeeRequired()
# [PASS] test_H06_MinDepositEnforced()
# [PASS] test_I05_TaxRateCannotExceedCap()
# [PASS] test_L05_ZeroAddressRejected()
# [PASS] test_M06_SlippageProtection()
```

If any test fails: copy the error, ask me (or ChatGPT/Claude). 99% of the time it's a minor fix.

### Step 2.4 — Run fuzz tests (15 min)

```bash
# Run Foundry's built-in fuzz tests
forge test --match-path "test-invariant/FoundryInvariants.t.sol" --fuzz-runs 10000 -vv

# This will try 10,000 random inputs against each invariant
# Output: should show all invariants passing
```

### Step 2.5 — Test locally with Anvil (30 min)

Anvil = local Ethereum testnet running on your machine. 100% free, no internet needed.

```bash
# Terminal 1: run local chain
anvil

# Will print 10 accounts with private keys. Copy Account #0's private key:
# Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

```bash
# Terminal 2: deploy to local chain
cd /path/to/quanta/contracts

export TREASURY_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266  # Anvil Account #0
export DEPLOYER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

forge script script/Deploy.s.sol \
  --rpc-url http://localhost:8545 \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast

# You'll see 4 contract addresses. Copy them.
```

### Step 2.6 — Read + understand contracts (1h)

Open `contracts/src-v1.1/QuantaToken.sol`, read carefully:

**Parameters you might want to adjust**:
- `MAX_SUPPLY = 1_000_000_000 * 1e18` — total supply cap
- `GENESIS_SUPPLY = 300_000_000 * 1e18` — initial mint
- `aiUsageTaxBps = 30` — 0.3% AI tax (change as desired)

**DO NOT modify**:
- Signature verification logic
- OpenZeppelin imports
- Function visibility

After any changes, re-run `forge test` to ensure nothing broke.

### ✅ End of Day 2 you have:
- Foundry working
- All 13 security tests pass
- Fuzz tests pass
- Successfully deployed to Anvil locally
- Understanding of the code

---

## 📅 DAY 3 — Deploy to Base Sepolia testnet (3-4h, $0)

### 🎯 Goal
- ✅ 4 contracts deployed on Base Sepolia (real public testnet)
- ✅ Contracts verified on Basescan
- ✅ MetaMask sees QTA token

### Step 3.1 — Set up MetaMask for Base Sepolia (15 min)

1. Open MetaMask → Settings → Networks → "Add Network"
2. Add Base Sepolia:
   - Network name: `Base Sepolia`
   - RPC URL: `https://sepolia.base.org`
   - Chain ID: `84532`
   - Symbol: `ETH`
   - Block Explorer: `https://sepolia.basescan.org`
3. Copy wallet address → save it

### Step 3.2 — Get free testnet ETH (15-30 min)

You need ~0.01 ETH on Base Sepolia to deploy 4 contracts. **All sources are free.**

**Option 1 — Coinbase Faucet (fastest, recommended)**:
- https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet
- Login with Coinbase account (free), paste address, get 0.05 ETH

**Option 2 — Alchemy Faucet**:
- https://www.alchemy.com/faucets/base-sepolia
- Sign up for Alchemy free, get 0.1 ETH/day

**Option 3 — PoW Faucet (no signup needed)**:
- https://www.ethereum-ecosystem.com/faucets/base-sepolia
- Leave tab open 10-30 min "mining", claim ETH

**Option 4 — QuickNode**:
- https://faucet.quicknode.com/base/sepolia

> 💡 **Tip**: Request from 2-3 faucets to have enough. Each faucet has ~24h cooldown.

### Step 3.3 — Get Basescan API key free (5 min)

For auto-verifying contract code.

1. Sign up free: https://basescan.org/register
2. Go to "My API Keys" → "Add" → copy API key

### Step 3.4 — Get RPC endpoint (5 min)

Default Base RPC has rate limits. Get free dedicated RPC:

**Option A — Alchemy** (recommended):
1. https://www.alchemy.com → Sign up free
2. "Create app" → Base Sepolia
3. Copy HTTPS URL: `https://base-sepolia.g.alchemy.com/v2/YOUR_KEY`

**Option B — Public RPC**: use `https://sepolia.base.org` (slower but OK for one-time deploy)

### Step 3.5 — Deploy! (15 min)

```bash
cd /path/to/quanta/contracts

# Create .env file (DO NOT commit to git)
cat > .env <<EOF
DEPLOYER_PRIVATE_KEY=0xYOUR_METAMASK_PRIVATE_KEY_HERE
TREASURY_ADDRESS=0xYOUR_METAMASK_ADDRESS_HERE
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY
BASESCAN_API_KEY=YOUR_BASESCAN_KEY
EOF

# Load env
source .env

# Deploy + verify in one command
# IMPORTANT: We deploy from src-v1.1/ (the secure version)!
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  -vvv

# Takes 2-5 minutes. Final output will print 4 contract addresses.
```

> 🚨 **EXTREMELY IMPORTANT**: Private key in `.env` = real money if you ever fund this wallet with real ETH. NEVER commit `.env` to git. NEVER share screenshots with private key visible.

### Step 3.6 — Verify on Basescan (10 min)

1. Open https://sepolia.basescan.org
2. Paste your `QuantaToken` contract address
3. Look for green "Source Code Verified" badge ✅
4. Click "Read Contract" tab → click `totalSupply` → should show `300000000000000000000000000` (= 300M × 1e18)

### Step 3.7 — Add token to MetaMask (5 min)

1. MetaMask → bottom → "Import tokens"
2. Paste `QuantaToken` contract address
3. Symbol auto-fills: `QTA`, decimals: `18`
4. You'll see: **300,000,000 QTA** in your wallet 🎉

### Step 3.8 — Save deployment addresses

Create `DEPLOYMENTS.md`:

```markdown
# QUANTA Deployments

## Base Sepolia (Testnet)
- **QuantaToken**: `0x...` ([Basescan](https://sepolia.basescan.org/address/0x...))
- **AIAgentRegistry**: `0x...`
- **AIPaymentChannel**: `0x...`
- **AIModelMarketplace**: `0x...`
- Deployed: 2026-MM-DD
- Deployer: `0x...`
- Tx hashes:
  - QuantaToken: `0x...`
  - AIAgentRegistry: `0x...`
  - AIPaymentChannel: `0x...`
  - AIModelMarketplace: `0x...`
```

Commit + push:

```bash
git add DEPLOYMENTS.md
git commit -m "feat: deploy v1.1 contracts to Base Sepolia"
git push
```

### ✅ End of Day 3 you have:
- 4 contracts live on public testnet
- QTA token in your MetaMask
- Anyone can verify the code
- **This is huge social proof**

---

## 📅 DAY 4 — Community setup (Discord + Telegram + SDK) (3-4h, $0)

### 🎯 Goal
- ✅ Discord server with 5+ channels properly configured
- ✅ Telegram group/channel
- ✅ SDK updated with deployed contract addresses
- ✅ Repo README updated

### Step 4.1 — Discord server (1h)

1. https://discord.com/app → "+" → "Create My Own" → "For me and friends"
2. Server name: `QUANTA`
3. Upload icon (logo.png)

**Recommended channel structure**:

```
📢 OFFICIAL
├── #announcements   (admin-only posts)
├── #updates         (dev updates)
└── #rules-and-faq

💬 COMMUNITY
├── #general
├── #english
├── #vietnamese      (for VN community)
└── #memes-and-art

🛠️ DEV
├── #dev-chat
├── #contracts-on-base
├── #sdk-help
└── #github-feed     (webhook from GitHub)

🤖 AI AGENTS
├── #agent-showcase
└── #pouw-validators

🔔 BOTS
└── #bot-commands
```

**Bots to install (all free)**:
- **MEE6** (mee6.xyz) — auto-roles, level system, moderation. Free tier sufficient.
- **Carl-bot** (carl.gg) — reaction roles, automod
- **Statbot** (free) — analytics

**Reaction roles** (recommended):
```
React 🛠️ to get @Developer role
React 🎨 to get @Creator role
React 📣 to get @Marketer role
React 🌏 to get @Vietnamese role
```

→ Creates "belonging" feeling + easy tagging of right audience later.

### Step 4.2 — GitHub webhook for Discord (10 min)

So every commit auto-posts to `#github-feed`:

1. Discord channel `#github-feed` → Settings → Integrations → Webhooks → "New Webhook" → copy URL
2. GitHub repo → Settings → Webhooks → "Add webhook"
3. Payload URL: paste Discord URL + add `/github` at the end
4. Content type: `application/json`
5. Events: choose "Push", "Releases", "Issues", "Pull Requests"

→ Every commit, members see real-time → "wow, this project is actively being built"

### Step 4.3 — Telegram (15 min)

Crypto community in VN/Asia is huge on Telegram.

1. Download Telegram, sign up
2. Create **Channel** (announcements, one-way):
   - Name: `QUANTA Official`
   - Public link: `t.me/QuantaOfficial`
3. Create **Group** (two-way chat):
   - Name: `QUANTA Community`
   - Public link: `t.me/QuantaCommunity`

**Bots to install (all free)**:
- **Combot** (combot.org) — anti-spam, captcha
- **Rose Bot** — moderation

> 💡 **Spam-proof**: Enable captcha verification for new members. You WILL get scam/spam on day 1, 100%.

### Step 4.4 — Update SDK with contract addresses (30 min)

```bash
cd /path/to/quanta/sdk

# Open src/types.ts
```

Update `QUANTA_CONTRACTS` with addresses from Day 3:

```typescript
export const QUANTA_CONTRACTS: Record<string, QuantaContracts> = {
  "base-sepolia": {
    token: "0x_paste_QuantaToken_address_here",
    registry: "0x_paste_AIAgentRegistry_address_here",
    channel: "0x_paste_AIPaymentChannel_address_here",
    marketplace: "0x_paste_AIModelMarketplace_address_here",
  },
  // ...
};
```

Test SDK:

```bash
npm install
npm run demo:agent

# In examples/autonomous-agent.ts, make sure:
# - PRIVATE_KEY is in .env (same key from Day 3)
# - chain: "base-sepolia"
```

### Step 4.5 — Update main README (30 min)

Open `quanta/README.md`, add section at top:

```markdown
## 🌐 Live Deployments

### Base Sepolia (Testnet)
- **QuantaToken**: `0x...` ([Basescan](https://sepolia.basescan.org/address/0x...))
- **AIAgentRegistry**: `0x...`
- **AIPaymentChannel**: `0x...`
- **AIModelMarketplace**: `0x...`

### Add to MetaMask
- Network: Base Sepolia
- Token contract: `0x...`
- Symbol: QTA, Decimals: 18

## 💬 Community
- 🐦 Twitter: [@QuantaCoin](https://twitter.com/QuantaCoin)
- 💬 Discord: [discord.gg/quanta](https://discord.gg/...)
- 📢 Telegram: [t.me/QuantaOfficial](https://t.me/QuantaOfficial)
- 💻 GitHub: you're here
```

Commit + push:

```bash
git add .
git commit -m "feat: deploy on Base Sepolia + community links"
git push
```

### ✅ End of Day 4 you have:
- Discord with 10 channels, GitHub feed auto-posting
- Telegram channel + group
- SDK updated with real contracts
- Professional README

---

## 📅 DAY 5 — Landing page + Mirror blog (3h, $0)

### 🎯 Goal
- ✅ Landing page live on GitHub Pages
- ✅ Long-form blog post on Mirror.xyz
- ✅ Twitter banner updated with link

### Step 5.1 — Deploy landing page to GitHub Pages (30 min)

```bash
cd /path/to/quanta

# Create gh-pages branch
git checkout --orphan gh-pages

# Only keep landing file
git rm -rf .
cp landing/index.html .
git add index.html
git commit -m "Deploy landing"
git push origin gh-pages

# Switch back to main
git checkout main
```

**Enable GitHub Pages**:
1. GitHub repo → Settings → Pages
2. Source: Deploy from branch → `gh-pages` / `(root)`
3. Save → wait 1-2 min
4. Visit: `https://YOUR_USERNAME.github.io/quanta`

**If you have a domain**: point CNAME at DNS provider to `YOUR_USERNAME.github.io`, add a `CNAME` file in gh-pages branch containing your domain.

### Step 5.2 — Update landing with contract addresses (30 min)

Open `landing/index.html`, find `#tech` section and add "Live on Base Sepolia" card:

```html
<div class="feature" style="grid-column: span 2;">
  <div class="feature-icon">🟢</div>
  <h3>Live on Base Sepolia</h3>
  <p>
    QTA token + smart contracts deployed on testnet.
    <br><br>
    <a href="https://sepolia.basescan.org/token/YOUR_TOKEN_ADDRESS" 
       style="color: #4fd1c5;">QTA Token →</a><br>
    <a href="https://sepolia.basescan.org/address/YOUR_REGISTRY" 
       style="color: #4fd1c5;">Agent Registry →</a><br>
    <a href="https://sepolia.basescan.org/address/YOUR_MARKETPLACE" 
       style="color: #4fd1c5;">AI Marketplace →</a>
  </p>
</div>
```

### Step 5.3 — Mirror.xyz blog post (1.5h)

Mirror.xyz is the blog platform crypto Twitter reads most.

1. Visit https://mirror.xyz
2. Connect wallet (MetaMask)
3. Click "Write" → editor appears

**Title suggestion**: `Why we built QUANTA: post-quantum money for the AI agent economy`

**Article outline** (~1500-2000 words):

```markdown
# Why we built QUANTA

## The two icebergs ahead
- 2030: AI agents make 1B+ transactions/day. Stripe doesn't serve them. Banks don't know they exist.
- 2032-2040: Quantum computers break ECDSA. $1T+ in crypto wallets become vulnerable.
- No L1 today addresses BOTH.

## What we tried first (and why it failed)
- Wrapping Bitcoin in lattice signatures → hacky, doesn't fix new wallets
- Adding AI features to Ethereum → gas too expensive for micropayments
- Building on Cosmos with quantum module → no AI native primitives

## The QUANTA approach
- (Insert your architecture diagram from whitepaper)
- 3 layers: Quantum-safe crypto → PoUW consensus → AI-native execution

## Proof-of-Useful-Work, explained
- Bitcoin: SHA-256 = wasted electricity
- QUANTA: Validators run LLM inference for paying users → earn block reward + tx fees
- Every watt = useful output

## What's live today
- 4 smart contracts on Base Sepolia
- Python prototype with quantum-safe sigs (Merkle Signature Scheme)
- TypeScript SDK
- (Link to GitHub)

## The 12-month roadmap
- Q1-Q2 2026: Mainnet contracts on Base + Ethereum
- Q3 2026: Rust L1 testnet
- Q4 2026: Mainnet L1

## How you can help
- Devs: PRs welcome on GitHub
- Researchers: Joint paper on PoUW
- Users: register an AI agent, try the marketplace
- Memes: yes, srsly

## The pitch
"The best time to migrate to post-quantum was yesterday. The second best time is QUANTA."

[Links to GitHub, Discord, Twitter]
```

4. Click "Publish" → Mirror mints NFT of the post (free) + saves to Arweave (permanent storage).

### Step 5.4 — SEO basics for GitHub repo (15 min)

Make sure `README.md` at TOP of repo has:

- **H1 title**: `# QUANTA — Quantum-resistant AI-native Blockchain`
- **Badges**: license, stars, twitter follow
- **Hero image**: screenshot of landing page
- **Quick links** at the top: Whitepaper · Demo · Discord · Twitter

Add Twitter follow badge:
```markdown
[![Twitter Follow](https://img.shields.io/twitter/follow/QuantaCoin?style=social)](https://twitter.com/QuantaCoin)
```

### ✅ End of Day 5 you have:
- Landing page live at a professional URL
- Long-form post on Mirror (can be retweeted multiple times)
- Professional GitHub repo

---

## 📅 DAY 6 — Viral demo video (3-4h, $0)

### 🎯 Goal
- ✅ 60-second "AI agent earning money" demo video
- ✅ Uploaded to YouTube + Twitter
- ✅ Ready for launch tomorrow

### Step 6.1 — Prepare tech demo (1h)

On your machine:

```bash
cd /path/to/quanta/sdk

# Ensure .env has private key + deployed contract addresses
# Run demo
npm run demo:agent
```

Demo should print beautiful logs like:
```
🤖 Agent registered: 0xabc...
💸 Opening payment channel...
📤 Call #1: paid 0.0001 QTA
📤 Call #2: paid 0.0002 QTA
...
✓ 50 micropayments off-chain
✓ Profit: 1.5 QTA → returned to owner
```

### Step 6.2 — Record video (1.5h)

**100% free tools**:
- **OBS Studio** (obsproject.com) — pro screen recorder
- **DaVinci Resolve** (blackmagicdesign.com) — pro editing (free)
- **CapCut** (capcut.com) — easier editing, has web version
- **Audacity** — voiceover recording

**60-second video structure**:

```
[0-5s]  Hook: "I taught an AI to earn its own money"
        (Scene: terminal open, balance = 0)

[5-15s] Setup: "It registers as an agent on QUANTA, gets a wallet,
                spending policy max $5/day"
        (Code registering agent + agent address appears on Basescan)

[15-35s] Action: "Watch it accept a task, pay AI APIs, earn from users"
         (Speed-up demo running, balance counting up)

[35-50s] Result: "$50 earned in 24h. Zero human touch.
                  Every payment quantum-safe."
         (Show Basescan with transactions, point out Dilithium-style signature)

[50-60s] CTA: "Try it yourself. Link in bio.
               QUANTA — currency for AI agents."
         (Logo + Twitter handle)
```

### Step 6.3 — Upload (30 min)

**YouTube**:
- Title: `I built an AI agent that earns money on its own (using a quantum-safe blockchain)`
- Description:
  ```
  This AI agent is fully autonomous. It accepts tasks, pays other AIs for compute, 
  collects revenue, and books profit — all on-chain, no human in the loop.
  
  Built on QUANTA: a quantum-safe blockchain for the AI agent economy.
  
  📄 Whitepaper: [link]
  💻 Code (MIT): [github]
  🌐 Try it: [landing]
  💬 Discord: [link]
  
  #AI #blockchain #cryptocurrency #quantum #autonomous #agents
  ```
- Tags: `AI agents, autonomous AI, blockchain, quantum, crypto, base, ethereum, dilithium`

**Twitter/X**:
- Upload video natively (don't link YouTube — Twitter throttles external links)
- Caption:
  ```
  I taught an AI to earn its own money. 
  
  No human approval. No bank account. No KYC.
  Just: register on @QuantaCoin → get wallet → accept tasks → profit.
  
  Quantum-safe signatures. $0.0001 fees. Live on Base testnet.
  
  This is what AI agents will use in 2030. We're 4 years early.
  
  Code 👇
  ```

**TikTok/Reels** (optional): cut a 15-30s vertical version. Hashtags: `#AI #crypto #futureoftech`

### Step 6.4 — Prepare for launch tomorrow (30 min)

- ✅ Open `content/twitter/launch-thread.md`
- ✅ Update Tweet 1 with video URL
- ✅ Save each tweet as a draft on Twitter (web version supports scheduling for free)
- ✅ Schedule for post: **Tuesday or Wednesday, 9-11 AM EST** (peak crypto Twitter hours)
- ✅ DM 5-10 friends in crypto: "Hey, I'm launching soon, can you RT for me on day X?"

### ✅ End of Day 6 you have:
- Viral-ready demo video
- YouTube uploaded
- Tweet thread scheduled

---

## 📅 DAY 7 — LAUNCH DAY 🚀 (4-6h, $0)

### 🎯 Goal
- ✅ Launch thread goes live
- ✅ Cross-post to 3+ platforms
- ✅ Engage maximally for 6h after launch
- ✅ Hit 100+ followers, 10+ Discord members, 50+ GitHub stars

### Step 7.1 — T-1 hour prep (1h)

**Before posting**:
- [ ] Test all links in thread
- [ ] Test landing page on mobile
- [ ] Discord bots online, channels ready
- [ ] Pin "Welcome thread" in Discord
- [ ] Snooze all other notifications — full focus next 6h
- [ ] Make coffee / tea ☕

**Prepare "engagement weapons"**:

Pre-write 10-15 replies for questions that WILL come:

| Question | Reply template |
|----------|----------------|
| "When token sale?" | "No token sale yet — first we ship product, then community votes. Follow @QuantaCoin for updates." |
| "Whitepaper?" | "Yes — [Mirror link]. Full architecture + tokenomics + roadmap." |
| "How different from Bitcoin Dilithium proposal?" | "BTC proposal is retrofit. QUANTA is built from scratch with AI-native primitives too. See whitepaper section 2.4." |
| "Is this a scam?" | "100% open source MIT, no token sale, no presale. Code on GitHub, contracts on Basescan. Decide for yourself." |
| "Audited?" | "Smart contracts use OpenZeppelin libs (audited). Full audit before mainnet — community can sponsor or we'll fund from grants." |
| "Why does AI need blockchain?" | "Stripe min $0.30/tx. Banks don't onboard non-humans. Crypto is the only path for agent-to-agent commerce. See thread." |

### Step 7.2 — POST! (5 min)

At peak time: post the launch thread.

```bash
# Post thread → 12 tweets
# Pin first tweet
# Update Twitter bio with landing page link
```

### Step 7.3 — Cross-post (1h)

Post simultaneously (or 30 min apart):

**1. Hacker News** (news.ycombinator.com):
- Title: `Show HN: Quanta – Quantum-safe blockchain for AI agents`
- Text: 1 paragraph + GitHub link
- **Important**: Reply quickly to comments. HN community is highly technical, avoid marketing-speak.

**2. r/cryptocurrency** (reddit):
- Title: `[OC] We built the first quantum-safe blockchain with native AI agent support`
- Flair: "DISCUSSION" or "TECHNOLOGY"
- ⚠️ Mods remove if they smell shill. Avoid words: "moon", "buy", "10x", "presale".

**3. r/ethereum** (research category):
- Title: `Smart contract suite for quantum-safe AI agent economy (open source)`
- Focus: technical, never mention price

**4. r/MachineLearning**:
- Title: `[D] Proof-of-Useful-Work consensus where validators perform LLM inference`
- Focus: PoUW angle, less blockchain-speak

**5. LinkedIn**:
- Long post, business angle: "Bridging the gap between AI agents and traditional finance"
- Tag: NIST PQC related accounts

**6. Farcaster** (warpcast.com):
- Channels: /crypto, /ai, /base
- Crypto-native, more forgiving than Reddit

**7. Hacker Noon, Dev.to, Medium**:
- Cross-post Mirror blog (canonical URL to Mirror)

### Step 7.4 — Engage for next 6 hours (4h)

**Golden rule**: Reply within 5 minutes to EVERY comment in first 6 hours.

- Like + reply to every RT
- Pin best reply in thread
- Quote tweet 2-3 influencers who engage
- DM-welcome each new Discord member
- Share real-time milestones:
  - "🎉 100 stars on GitHub!"
  - "🎉 First Discord member from Vietnam, Brazil, Japan..."
  - "🎉 1000 impressions in 1 hour"

**Tracking (put on screen)**:

```
Hour 1:  [____] Twitter views, [_] follows, [_] discord
Hour 3:  [____] Twitter views, [_] follows, [_] discord
Hour 6:  [____] Twitter views, [_] follows, [_] discord
Day 1:   [____] Twitter views, [_] follows, [_] discord
```

### Step 7.5 — End of day (30 min)

- Tweet "Day 1 recap" with numbers
- Thank you message in Discord
- Plan tomorrow's tweet (don't let momentum die)
- **GET ENOUGH SLEEP** — next week is the marathon

### ✅ End of Day 7 you have:

**Conservative goals** (realistic for day 1 if you have no prior audience):
- 50-200 new Twitter followers
- 20-100 Discord members
- 30-150 GitHub stars
- 5-20 testnet wallet interactions

**Optimistic** (if you hit viral):
- 1K-5K followers
- 200-500 Discord
- 500-2K GitHub stars
- Mention on Bankless, Defiant, CoinDesk

→ Either number is **OK**. Every successful crypto founder had "first 100 fans" before "first 100K".

---

## 💰 Total cost for 7 days

| Item | Cost | Required? |
|------|------|-----------|
| GitHub | $0 | ✅ |
| MetaMask | $0 | ✅ |
| Base Sepolia ETH (faucet) | $0 | ✅ |
| Alchemy/Basescan APIs | $0 | ✅ |
| Twitter/Discord/Telegram | $0 | ✅ |
| Mirror.xyz | $0 (gas ~$0.10) | Optional |
| Logo (Recraft/Hatchful) | $0 | ✅ |
| OBS/CapCut video | $0 | ✅ |
| **Domain .xyz (Spaceship)** | $1-3 | Optional |
| **Domain .com (Cloudflare)** | $8-10 | Optional |
| **TOTAL** | **$0-13** | |

---

## 🚦 Checkpoint after 7 days

Answer these questions — if MOST are **YES**, you're ready for Phase 2:

- [ ] At least 100 Twitter followers?
- [ ] At least 20 Discord members, 5+ chatting regularly?
- [ ] At least 1 dev (not you) cloned the repo and opened an issue/PR?
- [ ] At least 3 wallets (not you) interacted with the contract?
- [ ] At least 1 mention from another account (not friends)?

**If YES**: You have "early traction". Next steps:
- Audit smart contracts → deploy mainnet
- Apply for Base Builder Grant ($5-50K free)
- Apply for Ethereum Foundation Small Grant
- Start pitching incubators (Outlier Ventures, Alliance DAO — free programs)

**If mostly NO**:
- DON'T give up. 90% of crypto projects die on day 1.
- Analyze: Is the hook right? Is the message clear? Is the demo impressive?
- Iterate: write new thread (different angle), new demo, new hashtags
- Allow 4-6 weeks for real signal

---

## 🆘 Rescue — when you're stuck

| Problem | Solution |
|---------|----------|
| Foundry won't install | Use Remix IDE (remix.ethereum.org) — web-based, no install |
| No testnet ETH | Spam 5 different faucets, or DM Web3 friends for 0.01 ETH Sepolia |
| Contract deploy failed | Check chain ID is `84532`, enough ETH, no typos in RPC URL |
| No one replies to tweet | Normal. Tweet more. Tag big accounts (relevantly, don't spam) |
| Discord empty | Invite 10 personal friends first to create "presence" |
| Accused of scam | Reply pro: link MIT GitHub, link verified Basescan, "no token sale" |
| Burnout | Take 1 day off. Project isn't going anywhere. Your health matters more |

---

## 📚 Useful free resources

### Learn more
- **Foundry book**: book.getfoundry.sh
- **Solidity by example**: solidity-by-example.org
- **Base docs**: docs.base.org
- **OpenZeppelin docs**: docs.openzeppelin.com

### Free crypto marketing
- **Crypto Twitter list**: twitter.com/i/lists/...
- **Bankless podcast** (see who they interview)
- **CoinGecko launchpad** (apply free for listing)
- **DexTools** (auto-list when liquidity pool exists)

### Learning communities
- **r/ethdev**, **r/solidity** (technical)
- **r/cryptocurrency** (general)
- **/dev** channel in Base/Optimism Discord (very helpful)

### Grant programs (apply now if you have signal)
- **Base Builder Grants**: paragraph.xyz/@grants
- **Ethereum Foundation Small Grants**: esp.ethereum.foundation
- **Optimism RetroPGF**: rounds every 3 months
- **Gitcoin Grants**: gitcoin.co (quarterly)

---

## 🎯 Final word

These 7 days aren't about "succeeding". They're about **proving you can ship**.

Successful crypto founders aren't the ones with the best ideas.
They're the ones who **ship consistently, listen, iterate, and don't quit when no one cares on day 1**.

Bitcoin whitepaper was read by 100 people in month 1. Ethereum was laughed at in year 1. Solana went down many times.

The only difference: they **didn't stop**.

You have the weapons (code, docs, content). Now just **shoot**.

Good luck 🚀
