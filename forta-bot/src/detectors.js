/**
 * Detector functions — each returns array of Findings for one tx.
 * Composable: agent.js just calls each detector and concatenates results.
 */

const { Finding, FindingSeverity, FindingType } = require("forta-agent");
const ethers = require("ethers");
const { DEPLOYMENTS, THRESHOLDS, EVENT_ABIS } = require("./config");
const { state, recordAlert, maybeElevateAlerts, isElevated } = require("./state");

function getDeployment(chainId) {
  return DEPLOYMENTS[chainId];
}

// Elevate severity if we're already in alert mode
function maybeElevate(sev) {
  if (!isElevated()) return sev;
  const ranks = ["Info", "Low", "Medium", "High", "Critical"];
  const i = ranks.indexOf(sev);
  return ranks[Math.min(ranks.length - 1, i + 1)];
}

// ═══════════════════════════════════════════════════════════════
// 🔴 CRITICAL DETECTORS
// ═══════════════════════════════════════════════════════════════

function detectPauseEvents(txEvent, deployment) {
  const findings = [];
  const events = txEvent.filterLog(EVENT_ABIS.Paused);

  for (const e of events) {
    // Verify it's one of our contracts
    const contracts = Object.values(deployment).map(a => a.toLowerCase());
    if (!contracts.includes(e.address.toLowerCase())) continue;

    maybeElevateAlerts();
    recordAlert("PAUSE");

    findings.push(Finding.fromObject({
      name: "🚨 QUANTA Contract Paused",
      description:
        `Contract ${e.address} was paused by ${e.args.account}. ` +
        `This is typically done in response to a critical issue. ` +
        `On-call should verify intent IMMEDIATELY.`,
      alertId: "QUANTA-PAUSE",
      severity: FindingSeverity.Critical,
      type: FindingType.Suspicious,
      protocol: "QUANTA",
      metadata: {
        contract: e.address,
        pauser: e.args.account,
        txHash: txEvent.hash,
        chainId: txEvent.network.toString(),
      },
    }));
  }
  return findings;
}

function detectUnpause(txEvent, deployment) {
  const findings = [];
  const events = txEvent.filterLog(EVENT_ABIS.Unpaused);
  for (const e of events) {
    const contracts = Object.values(deployment).map(a => a.toLowerCase());
    if (!contracts.includes(e.address.toLowerCase())) continue;

    findings.push(Finding.fromObject({
      name: "✅ QUANTA Contract Unpaused",
      description: `Contract ${e.address} unpaused by ${e.args.account}.`,
      alertId: "QUANTA-UNPAUSE",
      severity: FindingSeverity.High,
      type: FindingType.Info,
      protocol: "QUANTA",
      metadata: { contract: e.address, unpauser: e.args.account, txHash: txEvent.hash },
    }));
  }
  return findings;
}

// ═══════════════════════════════════════════════════════════════
// 🟠 HIGH DETECTORS
// ═══════════════════════════════════════════════════════════════

function detectLargeBridgeMint(txEvent, deployment) {
  const findings = [];
  if (!deployment.token) return findings;

  const events = txEvent.filterLog(EVENT_ABIS.BridgeMinted, deployment.token);

  for (const e of events) {
    const amount = ethers.BigNumber.from(e.args.amount);
    state.mints24h.add(amount.toString());

    const threshold = ethers.utils.parseEther(THRESHOLDS.HUGE_MINT);
    const avg = state.mints24h.average();
    const isHuge = amount.gt(threshold);
    const isSpike = avg > 0n && amount.toBigInt() > avg * BigInt(THRESHOLDS.MINT_SPIKE_MULTIPLIER);

    if (isHuge || isSpike) {
      recordAlert("BRIDGE_LARGE_MINT");
      findings.push(Finding.fromObject({
        name: "⚠️  Unusually Large Bridge Mint",
        description:
          `${ethers.utils.formatEther(amount)} QTA minted via bridge to ${e.args.to}. ` +
          `24h rolling avg: ${ethers.utils.formatEther(avg.toString())} QTA. ` +
          `${isSpike ? `⚠️ ${THRESHOLDS.MINT_SPIKE_MULTIPLIER}× spike detected. ` : ""}` +
          `${isHuge ? "⚠️ Above absolute threshold. " : ""}` +
          `Verify legitimacy with bridge operations team.`,
        alertId: "QUANTA-BRIDGE-LARGE-MINT",
        severity: maybeElevate(FindingSeverity.High),
        type: FindingType.Suspicious,
        protocol: "QUANTA",
        metadata: {
          amount: amount.toString(),
          recipient: e.args.to,
          avg24h: avg.toString(),
          isHuge: isHuge.toString(),
          isSpike: isSpike.toString(),
          txHash: txEvent.hash,
        },
      }));
    }
  }
  return findings;
}

function detectAdminActions(txEvent, deployment) {
  const findings = [];
  if (!deployment.token) return findings;

  const adminEventDefs = [
    { abi: EVENT_ABIS.BridgeChangeProposed, name: "Bridge Change Proposed", severity: FindingSeverity.High,
      formatter: e => `New bridge: ${e.args.newBridge}, activates at ${new Date(Number(e.args.activatesAt) * 1000).toISOString()}` },
    { abi: EVENT_ABIS.BridgeChangeExecuted, name: "Bridge Change Executed", severity: FindingSeverity.High,
      formatter: e => `Bridge now: ${e.args.bridge}` },
    { abi: EVENT_ABIS.AITaxRateUpdated, name: "AI Tax Rate Changed", severity: FindingSeverity.High,
      formatter: e => `New rate: ${e.args.newBps} bps (${Number(e.args.newBps) / 100}%)` },
    { abi: EVENT_ABIS.AITaxCollectorSet, name: "Tax Collector Permission Changed", severity: FindingSeverity.High,
      formatter: e => `Collector ${e.args.collector} ${e.args.allowed ? "AUTHORIZED" : "REVOKED"}` },
    { abi: EVENT_ABIS.ReputationOracleSet, name: "Reputation Oracle Changed", severity: FindingSeverity.High,
      formatter: e => `Oracle ${e.args.oracle} ${e.args.allowed ? "AUTHORIZED" : "REVOKED"}` },
    { abi: EVENT_ABIS.OwnershipTransferStarted, name: "Ownership Transfer STARTED", severity: FindingSeverity.Critical,
      formatter: e => `From ${e.args.previousOwner} → ${e.args.newOwner}` },
    { abi: EVENT_ABIS.OwnershipTransferred, name: "Ownership Transfer COMPLETED", severity: FindingSeverity.Critical,
      formatter: e => `New owner: ${e.args.newOwner}` },
  ];

  for (const def of adminEventDefs) {
    const events = txEvent.filterLog(def.abi);
    for (const e of events) {
      const contracts = Object.values(deployment).map(a => a.toLowerCase());
      if (!contracts.includes(e.address.toLowerCase())) continue;

      recordAlert("ADMIN");
      findings.push(Finding.fromObject({
        name: `🔐 Admin Action: ${def.name}`,
        description: `${def.formatter(e)}. Contract: ${e.address}.`,
        alertId: `QUANTA-ADMIN-${def.name.replace(/\s+/g, "-").toUpperCase()}`,
        severity: maybeElevate(def.severity),
        type: FindingType.Info,
        protocol: "QUANTA",
        metadata: {
          contract: e.address,
          eventName: def.name,
          args: JSON.stringify(e.args, (k, v) => typeof v === "bigint" ? v.toString() : v),
          txHash: txEvent.hash,
        },
      }));
    }
  }
  return findings;
}

// ═══════════════════════════════════════════════════════════════
// 🟡 MEDIUM DETECTORS
// ═══════════════════════════════════════════════════════════════

function detectLargeBurn(txEvent, deployment) {
  const findings = [];
  if (!deployment.token) return findings;

  // Detect Transfer to zero address (= burn)
  const transfers = txEvent.filterLog(EVENT_ABIS.Transfer, deployment.token);
  const burns = transfers.filter(t =>
    t.args.to === ethers.constants.AddressZero
  );

  for (const e of burns) {
    const amount = ethers.BigNumber.from(e.args.value);
    state.burns1h.add(amount.toString());

    const threshold = ethers.utils.parseEther(THRESHOLDS.LARGE_BURN);
    if (amount.gt(threshold)) {
      recordAlert("LARGE_BURN");
      findings.push(Finding.fromObject({
        name: "🔥 Large QTA Burn",
        description:
          `${ethers.utils.formatEther(amount)} QTA burned by ${e.args.from}. ` +
          `Last hour total burns: ${ethers.utils.formatEther(state.burns1h.sum().toString())} QTA. ` +
          `Verify if legitimate (large tx fee) or exploit.`,
        alertId: "QUANTA-LARGE-BURN",
        severity: maybeElevate(FindingSeverity.Medium),
        type: FindingType.Info,
        protocol: "QUANTA",
        metadata: {
          burner: e.args.from,
          amount: amount.toString(),
          hourlyTotal: state.burns1h.sum().toString(),
          txHash: txEvent.hash,
        },
      }));
    }
  }
  return findings;
}

function detectChannelAnomalies(txEvent, deployment) {
  const findings = [];
  if (!deployment.channel) return findings;

  // Large channel opens
  const opens = txEvent.filterLog(EVENT_ABIS.ChannelOpened, deployment.channel);
  for (const e of opens) {
    state.channelOpensPerAddress.bump(e.args.payer);
    const deposit = ethers.BigNumber.from(e.args.deposit);
    const threshold = ethers.utils.parseEther(THRESHOLDS.LARGE_CHANNEL_DEPOSIT);

    if (deposit.gt(threshold)) {
      findings.push(Finding.fromObject({
        name: "💰 Large Payment Channel Opened",
        description:
          `${ethers.utils.formatEther(deposit)} QTA channel from ${e.args.payer} to ${e.args.payee}.`,
        alertId: "QUANTA-CHANNEL-LARGE",
        severity: maybeElevate(FindingSeverity.Low),
        type: FindingType.Info,
        protocol: "QUANTA",
        metadata: {
          channelId: e.args.channelId,
          payer: e.args.payer,
          payee: e.args.payee,
          deposit: deposit.toString(),
          txHash: txEvent.hash,
        },
      }));
    }

    // Rapid channel opens (potential griefing)
    const recentCount = state.channelOpensPerAddress.count(e.args.payer);
    if (recentCount > THRESHOLDS.RAPID_CHANNEL_OPENS) {
      findings.push(Finding.fromObject({
        name: "⚡ Rapid Channel Opens from Single Address",
        description:
          `Address ${e.args.payer} opened ${recentCount} channels in last minute. ` +
          `Possible griefing or abuse.`,
        alertId: "QUANTA-CHANNEL-SPAM",
        severity: maybeElevate(FindingSeverity.Medium),
        type: FindingType.Suspicious,
        protocol: "QUANTA",
        metadata: { payer: e.args.payer, count: recentCount.toString(), txHash: txEvent.hash },
      }));
    }
  }

  // Large force-closes
  const forceCloses = txEvent.filterLog(EVENT_ABIS.ChannelForceClosed, deployment.channel);
  for (const e of forceCloses) {
    const refund = ethers.BigNumber.from(e.args.refund);
    const threshold = ethers.utils.parseEther(THRESHOLDS.FORCE_CLOSE_LARGE);
    if (refund.gt(threshold)) {
      findings.push(Finding.fromObject({
        name: "⚡ Large Channel Force-Close",
        description:
          `Channel ${e.args.channelId} force-closed with refund ${ethers.utils.formatEther(refund)} QTA. ` +
          `Payee with unsubmitted tickets should claim before next force-close attempt.`,
        alertId: "QUANTA-CHANNEL-FORCE-LARGE",
        severity: maybeElevate(FindingSeverity.Medium),
        type: FindingType.Info,
        protocol: "QUANTA",
        metadata: { channelId: e.args.channelId, refund: refund.toString(), txHash: txEvent.hash },
      }));
    }
  }
  return findings;
}

function detectModelPriceManipulation(txEvent, deployment) {
  const findings = [];
  if (!deployment.market) return findings;

  const events = txEvent.filterLog(EVENT_ABIS.ModelPriceUpdated, deployment.market);
  for (const e of events) {
    const newPrice = ethers.BigNumber.from(e.args.newPrice);
    const modelId = e.args.modelId.toString();

    const oldPrice = state.modelPrices.get(modelId);
    state.modelPrices.set(modelId, newPrice.toString());

    if (oldPrice) {
      const old = ethers.BigNumber.from(oldPrice);
      // Detect 10x change
      if (newPrice.gt(old.mul(THRESHOLDS.MODEL_PRICE_JUMP)) ||
          old.gt(newPrice.mul(THRESHOLDS.MODEL_PRICE_JUMP))) {
        findings.push(Finding.fromObject({
          name: "📊 Model Price Manipulation",
          description:
            `Model ${modelId} price changed from ${ethers.utils.formatEther(old)} ` +
            `to ${ethers.utils.formatEther(newPrice)} QTA (>10× jump). ` +
            `Possible MEV / frontrunning attempt.`,
          alertId: "QUANTA-PRICE-JUMP",
          severity: maybeElevate(FindingSeverity.Medium),
          type: FindingType.Suspicious,
          protocol: "QUANTA",
          metadata: {
            modelId, oldPrice: old.toString(), newPrice: newPrice.toString(), txHash: txEvent.hash,
          },
        }));
      }
    }
  }
  return findings;
}

function detectReputationAbuse(txEvent, deployment) {
  const findings = [];
  if (!deployment.registry) return findings;

  const events = txEvent.filterLog(EVENT_ABIS.ReputationChanged, deployment.registry);
  for (const e of events) {
    const delta = Number(e.args.delta);
    if (delta <= THRESHOLDS.REPUTATION_BIG_DROP) {
      findings.push(Finding.fromObject({
        name: "📉 Large Reputation Drop",
        description:
          `Agent ${e.args.agentId} reputation dropped by ${-delta} ` +
          `(now ${e.args.newScore}) by oracle ${e.args.oracle}. ` +
          `Verify oracle's claim is legitimate.`,
        alertId: "QUANTA-REPUTATION-DROP",
        severity: maybeElevate(FindingSeverity.Medium),
        type: FindingType.Suspicious,
        protocol: "QUANTA",
        metadata: {
          agentId: e.args.agentId,
          delta: delta.toString(),
          newScore: e.args.newScore.toString(),
          oracle: e.args.oracle,
          txHash: txEvent.hash,
        },
      }));
    }
  }
  return findings;
}

// ═══════════════════════════════════════════════════════════════
// 🔵 WHALE / INFO DETECTORS
// ═══════════════════════════════════════════════════════════════

function detectWhaleTransfers(txEvent, deployment) {
  const findings = [];
  if (!deployment.token) return findings;

  const transfers = txEvent.filterLog(EVENT_ABIS.Transfer, deployment.token);
  const threshold = ethers.utils.parseEther(THRESHOLDS.WHALE_TRANSFER);

  for (const e of transfers) {
    const amount = ethers.BigNumber.from(e.args.value);
    if (e.args.from === ethers.constants.AddressZero) continue; // mint, handled elsewhere
    if (e.args.to === ethers.constants.AddressZero) continue;   // burn, handled elsewhere

    if (amount.gt(threshold)) {
      findings.push(Finding.fromObject({
        name: "🐋 Whale QTA Transfer",
        description:
          `${ethers.utils.formatEther(amount)} QTA: ${e.args.from} → ${e.args.to}`,
        alertId: "QUANTA-WHALE",
        severity: FindingSeverity.Info,
        type: FindingType.Info,
        protocol: "QUANTA",
        metadata: {
          from: e.args.from, to: e.args.to, amount: amount.toString(), txHash: txEvent.hash,
        },
      }));
    }
  }
  return findings;
}

module.exports = {
  detectPauseEvents,
  detectUnpause,
  detectLargeBridgeMint,
  detectAdminActions,
  detectLargeBurn,
  detectChannelAnomalies,
  detectModelPriceManipulation,
  detectReputationAbuse,
  detectWhaleTransfers,
};
