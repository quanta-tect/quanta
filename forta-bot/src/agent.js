/**
 * QUANTA Forta Bot — Main Agent
 *
 * Forta runs this against every transaction on configured chains.
 * Returns Findings → Forta network broadcasts to subscribers.
 *
 * Subscribers: Discord webhooks, PagerDuty, email, Telegram, custom integrations.
 *
 * Local testing:
 *   npm run tx 0xYOUR_TX_HASH    # test against a specific tx
 *   npm run block 12345678        # test against a block
 *   npm run range 12000-13000     # test range
 */

const { DEPLOYMENTS } = require("./config");
const {
  detectPauseEvents,
  detectUnpause,
  detectLargeBridgeMint,
  detectAdminActions,
  detectLargeBurn,
  detectChannelAnomalies,
  detectModelPriceManipulation,
  detectReputationAbuse,
  detectWhaleTransfers,
} = require("./detectors");
const { state } = require("./state");

const ALL_DETECTORS = [
  detectPauseEvents,
  detectUnpause,
  detectLargeBridgeMint,
  detectAdminActions,
  detectLargeBurn,
  detectChannelAnomalies,
  detectModelPriceManipulation,
  detectReputationAbuse,
  detectWhaleTransfers,
];

async function handleTransaction(txEvent) {
  const chainId = txEvent.network;
  const deployment = DEPLOYMENTS[chainId];

  // Skip if we don't monitor this chain
  if (!deployment) return [];

  // Skip if no QUANTA contracts touched (perf optimization)
  const monitoredAddresses = Object.values(deployment).map(a => a.toLowerCase());
  const touched = Object.keys(txEvent.addresses || {});
  const matches = touched.some(a => monitoredAddresses.includes(a.toLowerCase()));
  if (!matches) return [];

  // Run all detectors
  const allFindings = [];
  for (const detector of ALL_DETECTORS) {
    try {
      const findings = detector(txEvent, deployment);
      allFindings.push(...findings);
    } catch (err) {
      // Don't let one detector break others
      console.error(`Detector ${detector.name} failed:`, err.message);
    }
  }

  return allFindings;
}

async function handleBlock(blockEvent) {
  const findings = [];

  // Heartbeat: every 1000 blocks log stats
  if (blockEvent.blockNumber % 1000 === 0) {
    const stats = {
      mints24h_count: state.mints24h.count(),
      burns1h_count: state.burns1h.count(),
      total_alerts: Array.from(state.alertsByCategory.entries())
        .map(([k, v]) => `${k}:${v}`).join(", "),
    };
    console.log(`[QUANTA Bot] Block ${blockEvent.blockNumber}`, stats);
  }

  return findings;
}

module.exports = {
  handleTransaction,
  handleBlock,
};
