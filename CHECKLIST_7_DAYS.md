# ✅ QUANTA 7-Day Launch Checklist (print + tick)

## 🛠️ Pre-Day 1 (tonight, 30 min)
- [ ] Install Node.js v20+, Python 3.10+, Git
- [ ] Create GitHub account
- [ ] Install MetaMask, create NEW wallet for deploys
- [ ] Save seed phrase to `~/.quanta-deploy-seed.txt` (chmod 600) + paper copy
- [ ] Create dedicated Gmail for project

---

## 📅 DAY 1 — Branding (3-4h)
- [x] Twitter @QuantaCoin reserved (you have this!)
- [ ] Confirm project name (check Twitter/GitHub availability)
- [ ] Generate logo on Recraft.ai or DALL-E (free)
- [ ] Save logo.png 512×512, banner 1500×500, favicon.ico
- [ ] Post 3 warm-up tweets (not launch yet)
- [x] GitHub repo "quanta" public (you pushed already!)
- [ ] Add .gitignore (excludes .env, node_modules, pycache)
- [ ] Add repo topics: blockchain, quantum-resistant, ai-agents...
- [ ] Star your own repo
- [ ] (Optional) Buy domain on Spaceship/Cloudflare ($1-10)

---

## 📅 DAY 2 — Smart Contracts Local (3-4h)
- [ ] Install Foundry: `curl -L https://foundry.paradigm.xyz | bash && foundryup`
- [ ] `cd contracts && forge install OpenZeppelin/openzeppelin-contracts`
- [ ] `forge install foundry-rs/forge-std`
- [ ] `forge build` (success)
- [ ] `forge test --match-path "test-v1.1/**" -vv` (all 13 pass)
- [ ] `forge test --match-path "test-invariant/**" --fuzz-runs 10000` (passes)
- [ ] Start anvil: `anvil` (in terminal 1)
- [ ] Deploy local: `forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974... --broadcast`
- [ ] Read QuantaToken.sol (src-v1.1/), understand each function
- [ ] Adjust parameters if desired (MAX_SUPPLY, taxBps)
- [ ] Re-run tests after changes

---

## 📅 DAY 3 — Deploy to Base Sepolia (3-4h)
- [ ] Add Base Sepolia network to MetaMask (chainId 84532)
- [ ] Get testnet ETH from:
  - [ ] coinbase.com/faucets/base-ethereum-sepolia-faucet
  - [ ] alchemy.com/faucets/base-sepolia
  - [ ] (backup) ethereum-ecosystem.com PoW faucet
- [ ] Sign up Basescan.org → get API key
- [ ] Sign up Alchemy.com → create Base Sepolia app → get RPC URL
- [ ] Create `.env` file with PRIVATE_KEY, TREASURY_ADDRESS, RPC URL, BASESCAN_API_KEY
- [ ] **VERIFY**: .env is in .gitignore!
- [ ] Run: `source .env && forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --verify --etherscan-api-key $BASESCAN_API_KEY -vvv`
- [ ] Copy 4 contract addresses → save to `DEPLOYMENTS.md`
- [ ] Verify on Basescan: each address shows ✅ "Source Code Verified"
- [ ] Add QTA token to MetaMask, see 300M balance

---

## 📅 DAY 4 — Community (3-4h)
- [ ] Create Discord server "QUANTA"
- [ ] Upload icon, create 10+ channels (announcements, general, dev, vietnamese, memes...)
- [ ] Install MEE6 bot (free) for auto-roles
- [ ] Set up reaction roles: 🛠️=Dev, 🎨=Creator, 🌏=Vietnamese
- [ ] Create GitHub → Discord webhook for #github-feed
- [ ] Create Telegram Channel @QuantaOfficial (1-way)
- [ ] Create Telegram Group @QuantaCommunity (2-way)
- [ ] Install Combot for anti-spam
- [ ] Update `sdk/src/types.ts` with deployed contract addresses
- [ ] Run `npm install && npm run demo:agent` — works against real testnet
- [ ] Update README.md with deployments + community links
- [ ] git commit + push

---

## 📅 DAY 5 — Landing + Mirror (3h)
- [ ] Create `gh-pages` branch, push landing/index.html
- [ ] GitHub Pages settings → enable from gh-pages branch
- [ ] Test: `https://YOUR_USER.github.io/quanta` loads
- [ ] Update landing with real contract addresses + Basescan links
- [ ] (Optional) Point CNAME at custom domain
- [ ] Mirror.xyz: connect wallet, write blog post ~1500 words
- [ ] Title: "Why we built QUANTA"
- [ ] Sections: problems, approach, what's live, roadmap, CTA
- [ ] Publish (mints NFT + saves to Arweave)
- [ ] Update Twitter bio with all links

---

## 📅 DAY 6 — Demo Video (3-4h)
- [ ] Test `npm run demo:agent` on real testnet, capture nice logs
- [ ] Install OBS Studio (free)
- [ ] Record 60-sec screencast:
  - [ ] 0-5s: Hook "I taught AI to earn its own money"
  - [ ] 5-15s: Show register agent + spending policy
  - [ ] 15-35s: Speed-up of demo running
  - [ ] 35-50s: Show Basescan transactions
  - [ ] 50-60s: CTA + logo
- [ ] Edit in CapCut or DaVinci (free)
- [ ] Add captions (most people watch muted)
- [ ] Add background music (royalty-free from YouTube Audio Library)
- [ ] Export 1080p MP4 + 9:16 vertical version
- [ ] Upload YouTube with SEO title + description + tags
- [ ] Save vertical version for TikTok/Reels day 7
- [ ] Update `launch-thread.md` tweet 1 with video URL
- [ ] Schedule thread for Tue/Wed 9-11 AM EST

---

## 📅 DAY 7 — LAUNCH 🚀 (4-6h)

### T-60 min
- [ ] Test ALL links in thread one more time
- [ ] Test landing page on mobile
- [ ] Discord channels ready, welcome message pinned
- [ ] Snooze all other notifications
- [ ] Prepare 15 canned replies to common questions
- [ ] Coffee/tea ready ☕

### T-0 — POST
- [ ] Post launch thread on Twitter
- [ ] Pin tweet
- [ ] Like + RT own thread
- [ ] Update Twitter bio with thread link

### T+0 to T+30 min — Cross-post
- [ ] Hacker News: "Show HN: Quanta – Quantum-safe blockchain for AI agents"
- [ ] r/cryptocurrency (no shill words)
- [ ] r/ethereum (research category)
- [ ] r/MachineLearning (PoUW angle)
- [ ] LinkedIn (business angle)
- [ ] Farcaster /crypto, /ai, /base channels
- [ ] Dev.to / Medium / Hacker Noon (cross-post Mirror)

### T+0 to T+6h — ENGAGE
- [ ] Reply to EVERY comment in <5 min
- [ ] Like + RT every meaningful RT
- [ ] Welcome each new Discord member with DM
- [ ] Share milestones in thread:
  - [ ] 100 GitHub stars
  - [ ] 100 Discord members
  - [ ] First international user
  - [ ] First dev PR
- [ ] Quote-tweet 2-3 influencer mentions
- [ ] Post YouTube + TikTok vertical versions

### End of Day
- [ ] Post "Day 1 recap" with numbers
- [ ] Thank you message in Discord
- [ ] Plan tomorrow's tweet (keep momentum!)
- [ ] **SLEEP** — marathon starts tomorrow

---

## 📊 Success Metrics (track daily)

| Metric | Day 1 | Day 3 | Day 5 | Day 7 (Launch) |
|--------|-------|-------|-------|----------------|
| Twitter followers | _ | _ | _ | _ |
| Discord members | _ | _ | _ | _ |
| GitHub stars | _ | _ | _ | _ |
| Testnet tx | 0 | _ | _ | _ |
| Wallets created | 1 | _ | _ | _ |

**Realistic targets**:
- 50-200 followers
- 20-100 Discord
- 30-150 stars
- 5-20 external wallets

**Stretch targets** (viral hit):
- 1K-5K followers
- 200-500 Discord
- 500-2K stars
- 100+ external wallets

---

## 💸 Budget Tracker

| Day | Spent | Cumulative |
|-----|-------|-----------|
| Day 1 | $___ | $___ |
| Day 2 | $___ | $___ |
| Day 3 | $___ | $___ |
| Day 4 | $___ | $___ |
| Day 5 | $___ | $___ |
| Day 6 | $___ | $___ |
| Day 7 | $___ | $___ |
| **Total** | | **$0-13** |

---

## 🆘 Emergency contacts (save these)

- Foundry issues: github.com/foundry-rs/foundry/issues
- Base support: discord.gg/buildonbase
- OpenZeppelin: forum.openzeppelin.com
- Solidity Stack Exchange: ethereum.stackexchange.com
- Your community: discord.gg/yourquanta

---

## 🎯 The only rule

**Ship something every single day.** Even if it's small.

Day 8 onwards: keep shipping. The first 100 days separate dreamers from builders.

Good luck 🚀
