/**
 * Forta Detection Bot for QUANTA
 * ==============================
 *
 * Monitors QUANTA contracts in real-time and alerts on anomalies.
 * Forta = free decentralized monitoring infrastructure.
 *
 * Setup: https://docs.forta.network/en/latest/quickstart/
 *
 * Detections in this bot:
 *  1. Unusually large mint via bridge (> daily average × 5)
 *  2. Burn spike (potential exploit pattern)
 *  3. Pause event fired (always alert)
 *  4. Bridge change proposal (sensitive op)
 *  5. Tax rate change (sensitive op)
 *  6. Reputation oracle change (sensitive op)
 *  7. Suspicious payment channel patterns
 */

const { Finding, FindingSeverity, FindingType, getEthersProvider } = require("forta-agent");
const ethers = require("ethers");

// === Configuration ===
const QUANTA_TOKEN = "0x___YOUR_DEPLOYED_TOKEN___";
const QUANTA_CHANNEL = "0x___YOUR_DEPLOYED_CHANNEL___";
const QUANTA_MARKET = "0x___YOUR_DEPLOYED_MARKET___";
const QUANTA_REGISTRY = "0x___YOUR_DEPLOYED_REGISTRY___";

// Anomaly thresholds (tune based on historical data)
const LARGE_MINT_THRESHOLD = ethers.parseEther("100000"); // 100K QTA
const BURN_SPIKE_THRESHOLD = ethers.parseEther("10000");
const SUSPICIOUS_CHANNEL_AMOUNT = ethers.parseEther("1000000");

// Track rolling state
const recentMints = [];
const recentBurns = [];

// === Event signatures ===
const EVENT_SIGS = {
  Paused: "Paused(address)",
  Unpaused: "Unpaused(address)",
  BridgeMinted: "BridgeMinted(address,uint256)",
  BridgeBurned: "BridgeBurned(address,uint256)",
  BridgeChangeProposed: "BridgeChangeProposed(address,uint256)",
  AITaxRateUpdated: "AITaxRateUpdated(uint16)",
  AITaxCollectorSet: "AITaxCollectorSet(address,bool)",
  ReputationOracleSet: "ReputationOracleSet(address,bool)",
  ChannelOpened: "ChannelOpened(bytes32,address,address,uint256)",
  ChannelForceClosed: "ChannelForceClosed(bytes32,uint256)",
  OwnershipTransferStarted: "OwnershipTransferStarted(address,address)",
};

const EVENT_TOPICS = Object.fromEntries(
  Object.entries(EVENT_SIGS).map(([name, sig]) => [
    name,
    ethers.id(sig),
  ])
);

// === Main handler ===
async function handleTransaction(txEvent) {
  const findings = [];

  // ---------------------------------------------------------------
  // 🔴 CRITICAL: Pause event fired
  // ---------------------------------------------------------------
  const pauseEvents = txEvent.filterLog([
    "event Paused(address account)",
  ]);

  for (const event of pauseEvents) {
    findings.push(
      Finding.fromObject({
        name: "🚨 QUANTA Contract Paused",
        description: `${event.address} was paused by ${event.args.account}. This is a major event — verify it's intentional.`,
        alertId: "QUANTA-PAUSE-1",
        severity: FindingSeverity.Critical,
        type: FindingType.Suspicious,
        metadata: {
          contract: event.address,
          pauser: event.args.account,
          txHash: txEvent.hash,
        },
      })
    );
  }

  // ---------------------------------------------------------------
  // 🟠 HIGH: Large bridge mint
  // ---------------------------------------------------------------
  const mintEvents = txEvent.filterLog([
    "event BridgeMinted(address indexed to, uint256 amount)",
  ], QUANTA_TOKEN);

  for (const event of mintEvents) {
    const amount = BigInt(event.args.amount);
    recentMints.push({ amount, timestamp: Date.now() });

    // Compute rolling 24h average
    const dayAgo = Date.now() - 86400000;
    const recent = recentMints.filter(m => m.timestamp > dayAgo);
    const avg = recent.length > 0
      ? recent.reduce((s, m) => s + m.amount, 0n) / BigInt(recent.length)
      : 0n;

    if (amount > LARGE_MINT_THRESHOLD ||
        (avg > 0n && amount > avg * 5n)) {
      findings.push(
        Finding.fromObject({
          name: "⚠️ Unusually Large Bridge Mint",
          description: `${ethers.formatEther(amount)} QTA minted via bridge to ${event.args.to}. ` +
                       `Daily avg: ${ethers.formatEther(avg)} QTA. ` +
                       `Verify legitimacy.`,
          alertId: "QUANTA-BRIDGE-LARGE-MINT",
          severity: FindingSeverity.High,
          type: FindingType.Suspicious,
          metadata: {
            amount: amount.toString(),
            recipient: event.args.to,
            avg24h: avg.toString(),
            txHash: txEvent.hash,
          },
        })
      );
    }
  }

  // ---------------------------------------------------------------
  // 🟠 HIGH: Sensitive admin actions
  // ---------------------------------------------------------------
  const adminEvents = txEvent.filterLog([
    "event BridgeChangeProposed(address indexed newBridge, uint256 activatesAt)",
    "event AITaxRateUpdated(uint16 newBps)",
    "event AITaxCollectorSet(address indexed collector, bool allowed)",
    "event ReputationOracleSet(address indexed oracle, bool allowed)",
    "event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)",
  ]);

  for (const event of adminEvents) {
    findings.push(
      Finding.fromObject({
        name: `🔐 Sensitive Admin Action: ${event.name}`,
        description: `Admin action detected on ${event.address}. Args: ${JSON.stringify(event.args)}`,
        alertId: `QUANTA-ADMIN-${event.name.toUpperCase()}`,
        severity: FindingSeverity.High,
        type: FindingType.Info,
        metadata: {
          contract: event.address,
          event: event.name,
          args: JSON.stringify(event.args),
          txHash: txEvent.hash,
        },
      })
    );
  }

  // ---------------------------------------------------------------
  // 🟡 MEDIUM: Burn spike (potential exploit)
  // ---------------------------------------------------------------
  const burnEvents = txEvent.filterLog([
    "event Transfer(address indexed from, address indexed to, uint256 value)",
  ], QUANTA_TOKEN).filter(e => e.args.to === ethers.ZeroAddress);

  for (const event of burnEvents) {
    const amount = BigInt(event.args.value);
    if (amount > BURN_SPIKE_THRESHOLD) {
      findings.push(
        Finding.fromObject({
          name: "🔥 Large Burn Detected",
          description: `${ethers.formatEther(amount)} QTA burned by ${event.args.from}. ` +
                       `Investigate if legitimate (large tx fee burn) or exploit.`,
          alertId: "QUANTA-LARGE-BURN",
          severity: FindingSeverity.Medium,
          type: FindingType.Info,
          metadata: {
            burner: event.args.from,
            amount: amount.toString(),
            txHash: txEvent.hash,
          },
        })
      );
    }
  }

  // ---------------------------------------------------------------
  // 🟡 MEDIUM: Force-close on payment channel
  // ---------------------------------------------------------------
  const forceCloseEvents = txEvent.filterLog([
    "event ChannelForceClosed(bytes32 indexed channelId, uint256 refund)",
  ], QUANTA_CHANNEL);

  for (const event of forceCloseEvents) {
    findings.push(
      Finding.fromObject({
        name: "⚡ Payment Channel Force-Closed",
        description: `Channel ${event.args.channelId} force-closed with refund ${ethers.formatEther(event.args.refund)} QTA. ` +
                     `Payee should claim if they have unsubmitted tickets.`,
        alertId: "QUANTA-CHANNEL-FORCE-CLOSE",
        severity: FindingSeverity.Medium,
        type: FindingType.Info,
        metadata: {
          channelId: event.args.channelId,
          refund: event.args.refund.toString(),
          txHash: txEvent.hash,
        },
      })
    );
  }

  // ---------------------------------------------------------------
  // 🟡 MEDIUM: Suspiciously large channel
  // ---------------------------------------------------------------
  const channelOpenEvents = txEvent.filterLog([
    "event ChannelOpened(bytes32 indexed channelId, address indexed payer, address indexed payee, uint256 deposit)",
  ], QUANTA_CHANNEL);

  for (const event of channelOpenEvents) {
    if (BigInt(event.args.deposit) > SUSPICIOUS_CHANNEL_AMOUNT) {
      findings.push(
        Finding.fromObject({
          name: "💰 Large Payment Channel Opened",
          description: `${ethers.formatEther(event.args.deposit)} QTA channel opened ` +
                       `from ${event.args.payer} to ${event.args.payee}.`,
          alertId: "QUANTA-CHANNEL-LARGE",
          severity: FindingSeverity.Low,
          type: FindingType.Info,
          metadata: {
            channelId: event.args.channelId,
            payer: event.args.payer,
            payee: event.args.payee,
            deposit: event.args.deposit.toString(),
            txHash: txEvent.hash,
          },
        })
      );
    }
  }

  return findings;
}

module.exports = {
  handleTransaction,
};

// Local testing:
// forta-agent run --tx 0x___TX_HASH___
