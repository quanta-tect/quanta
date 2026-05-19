# 🤖 QUANTA Forta Detection Bot

Real-time security monitoring for QUANTA contracts via [Forta Network](https://forta.network).

## What it detects

| Detector | Severity | Triggers on |
|----------|----------|-------------|
| `detectPauseEvents` | 🔴 Critical | Any `Paused` event |
| `detectAdminActions` | 🟠 High/🔴 Critical | Bridge change, tax change, ownership transfer |
| `detectLargeBridgeMint` | 🟠 High | Mint > 100K QTA or > 5× rolling avg |
| `detectLargeBurn` | 🟡 Medium | Burn > 10K QTA |
| `detectChannelAnomalies` | 🟡 Medium | Large opens, force-closes, rapid spam |
| `detectModelPriceManipulation` | 🟡 Medium | 10× price change in short time |
| `detectReputationAbuse` | 🟡 Medium | -30% reputation drop |
| `detectWhaleTransfers` | 🔵 Info | Transfers > 1M QTA |
| `detectUnpause` | 🟠 High | Unpause event (verify legitimate) |

**Smart elevation**: After a `Paused` event, all severities are bumped one level for 1 hour (heightened alertness).

## Setup (5 min)

```bash
# 1. Install Forta CLI
npm install -g forta-agent

# 2. Install deps
cd forta-bot
npm install

# 3. Update contract addresses in src/config.js
nano src/config.js  # Fill in DEPLOYMENTS for your chains

# 4. Initialize Forta keys
forta-agent init                # creates ~/.forta/forta.config.json

# 5. Test locally against a real tx
npm run tx 0xYOUR_TEST_TX_HASH
```

## Subscribe to alerts

### Free options
- **Forta Explorer**: explorer.forta.network — see all alerts
- **Discord webhook**: 
  ```
  In Discord channel: Settings → Integrations → Webhooks → Copy URL
  Then: forta-agent push --webhook YOUR_WEBHOOK
  ```
- **Telegram bot**: via [@FortaNetworkBot](https://t.me/FortaNetworkBot)
- **Email**: forta.network → settings → email subscriptions

### Pro options (paid)
- **PagerDuty integration** (~$25/user/month) — for on-call rotation
- **OpsGenie** — similar
- **Custom**: REST webhook to your own infra

## Deploy to Forta Network

```bash
# 1. Get FORT tokens (testnet: free from faucet)
# Mainnet: ~100 FORT to deploy (~$30 at current prices)

# 2. Push to Forta scan node
npm run publish

# Output: alertId for your bot, e.g., QUANTA-BOT-v1.0.0

# 3. Verify deployment
forta-agent info
```

After deploy, **scan nodes worldwide will run your bot** and broadcast findings. Decentralized monitoring with no single point of failure.

## Cost

- **Free** for first 90 days of new bots
- **Then**: ~50 FORT/month (~$15) for unlimited scanning across configured chains

## Local development

```bash
# Watch a specific tx
npm run tx 0x1234...

# Watch a block range (last 1000 blocks)
LATEST=$(cast block-number --rpc-url https://mainnet.base.org)
npm run range $((LATEST-1000))-$LATEST

# Watch real-time (live mode)
npm start
```

## Customization

Add your own detector in `src/detectors.js`:

```js
function detectMyCustomThing(txEvent, deployment) {
  const findings = [];
  // ... your logic
  return findings;
}

module.exports.detectMyCustomThing = detectMyCustomThing;
```

Then register in `src/agent.js`:
```js
const ALL_DETECTORS = [..., detectMyCustomThing];
```

## Tuning thresholds

Edit `src/config.js` → `THRESHOLDS` object. Start with conservative values; tune after 1 week of data.

## Test fixtures

```bash
# After deploying contracts, create test transactions:
# 1. Big transfer (whale alert)
cast send $TOKEN "transfer(address,uint256)" $RECIPIENT 1000000ether
npm run tx <txhash>  # should fire QUANTA-WHALE

# 2. Pause (critical alert)
cast send $TOKEN "pause()"  # if you have owner key
npm run tx <txhash>  # should fire QUANTA-PAUSE (Critical)
```

## Architecture

```
┌─────────────────────────────────────────────┐
│  Forta Scan Nodes (decentralized)            │
│  - Subscribe to chains we configure          │
│  - Run agent.js on every tx                  │
│  - Submit findings to Forta network          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  Forta Network — broadcasts findings         │
└──────┬─────────────┬───────────────┬────────┘
       │             │               │
   Discord      Telegram        PagerDuty
   (free)        (free)         (paid, $)
```

## License

MIT
