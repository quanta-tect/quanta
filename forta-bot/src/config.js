/**
 * QUANTA Forta Bot Configuration
 *
 * UPDATE THESE addresses after deploying contracts on each chain.
 * Bot will monitor across all configured chains automatically.
 */

const CHAINS = {
  BASE_MAINNET: 8453,
  BASE_SEPOLIA: 84532,
  ETH_MAINNET: 1,
  ETH_SEPOLIA: 11155111,
};

// Map chainId → contract addresses
const DEPLOYMENTS = {
  [CHAINS.BASE_SEPOLIA]: {
    token:    "0x0000000000000000000000000000000000000000", // ← UPDATE
    registry: "0x0000000000000000000000000000000000000000", // ← UPDATE
    channel:  "0x0000000000000000000000000000000000000000", // ← UPDATE
    market:   "0x0000000000000000000000000000000000000000", // ← UPDATE
  },
  [CHAINS.BASE_MAINNET]: {
    token:    "0x0000000000000000000000000000000000000000",
    registry: "0x0000000000000000000000000000000000000000",
    channel:  "0x0000000000000000000000000000000000000000",
    market:   "0x0000000000000000000000000000000000000000",
  },
};

// Anomaly thresholds (tune based on historical data)
const THRESHOLDS = {
  // Token transfers
  WHALE_TRANSFER: "1000000",        // 1M QTA
  LARGE_BURN: "10000",              // 10K QTA
  HUGE_MINT: "100000",              // 100K QTA via bridge
  MINT_SPIKE_MULTIPLIER: 5,         // current > 5× rolling 24h avg

  // Payment channels
  LARGE_CHANNEL_DEPOSIT: "100000",  // 100K QTA
  RAPID_CHANNEL_OPENS: 10,          // 10 channels/min from same address
  FORCE_CLOSE_LARGE: "10000",       // force close > 10K refund

  // Marketplace
  MODEL_PRICE_JUMP: 10,             // 10× price change in short time
  RAPID_REGISTRATIONS: 20,          // 20 models/hour from same address

  // Agent
  REPUTATION_BIG_DROP: -3000,       // -30% reputation in one call
  RAPID_AGENT_SPENDS: 100,          // 100 spends/min

  // Admin actions (always alert)
  PAUSE_EVENT: true,
  BRIDGE_PROPOSAL: true,
  TAX_RATE_CHANGE: true,
  COLLECTOR_CHANGE: true,
  ORACLE_CHANGE: true,
  OWNERSHIP_TRANSFER: true,
};

// Event signatures we monitor
const EVENT_ABIS = {
  Paused: "event Paused(address account)",
  Unpaused: "event Unpaused(address account)",
  Transfer: "event Transfer(address indexed from, address indexed to, uint256 value)",
  BridgeMinted: "event BridgeMinted(address indexed to, uint256 amount)",
  BridgeBurned: "event BridgeBurned(address indexed from, uint256 amount)",
  BridgeChangeProposed: "event BridgeChangeProposed(address indexed newBridge, uint256 activatesAt)",
  BridgeChangeExecuted: "event BridgeChangeExecuted(address indexed bridge)",
  AITaxRateUpdated: "event AITaxRateUpdated(uint16 newBps)",
  AITaxCollectorSet: "event AITaxCollectorSet(address indexed collector, bool allowed)",
  AITaxCollected: "event AITaxCollected(address indexed collector, address indexed from, uint256 amount)",
  ReputationOracleSet: "event ReputationOracleSet(address indexed oracle, bool allowed)",
  ReputationChanged: "event ReputationChanged(bytes32 indexed agentId, int32 delta, uint32 newScore, address oracle)",
  ChannelOpened: "event ChannelOpened(bytes32 indexed channelId, address indexed payer, address indexed payee, uint256 deposit)",
  ChannelForceClosed: "event ChannelForceClosed(bytes32 indexed channelId, uint256 refund)",
  ChannelFinalized: "event ChannelFinalized(bytes32 indexed channelId, uint256 paidToPayee, uint256 refund)",
  ModelRegistered: "event ModelRegistered(uint256 indexed modelId, address indexed creator, uint256 pricePerCall)",
  ModelPriceUpdated: "event ModelPriceUpdated(uint256 indexed modelId, uint256 newPrice)",
  InferencePaid: "event InferencePaid(uint256 indexed modelId, address indexed user, uint256 price, uint256 burned)",
  OwnershipTransferStarted: "event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)",
  OwnershipTransferred: "event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)",
};

module.exports = { CHAINS, DEPLOYMENTS, THRESHOLDS, EVENT_ABIS };
