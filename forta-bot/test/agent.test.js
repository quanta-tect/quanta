/**
 * Forta Bot Unit Tests
 * Tests the detectors and state management in isolation.
 */

const { Finding, FindingSeverity, FindingType } = require("forta-agent");
const ethers = require("ethers");
const { DEPLOYMENTS, THRESHOLDS, EVENT_ABIS } = require("../src/config");
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
} = require("../src/detectors");
const { state, RollingWindow, AddressCounter, recordAlert, maybeElevateAlerts, isElevated } = require("../src/state");

// Mock txEvent factory
function createMockTxEvent(overrides = {}) {
  const chainId = overrides.chainId || 84532;
  const deployment = DEPLOYMENTS[chainId];
  
  return {
    network: chainId,
    hash: overrides.hash || "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
    addresses: overrides.addresses || {},
    filterLog: jest.fn((abi, address) => {
      // Return mocked events based on what test sets up
      return overrides.events?.[abi] || [];
    }),
  };
}

describe("RollingWindow", () => {
  let rw;
  beforeEach(() => {
    rw = new RollingWindow(1000); // 1 second window
  });

  test("adds and counts items", () => {
    rw.add("100");
    rw.add("200");
    expect(rw.count()).toBe(2);
  });

  test("sums items", () => {
    rw.add("100");
    rw.add("200");
    expect(rw.sum()).toBe(300n);
  });

  test("averages items", () => {
    rw.add("100");
    rw.add("200");
    expect(rw.average()).toBe(150n);
  });

  test("evicts old items", async () => {
    rw.add("100");
    await new Promise(r => setTimeout(r, 1100));
    rw.add("200");
    expect(rw.count()).toBe(1);
    expect(rw.sum()).toBe(200n);
  });
});

describe("AddressCounter", () => {
  let ac;
  beforeEach(() => {
    ac = new AddressCounter(1000);
  });

  test("counts per address", () => {
    ac.bump("0x1111");
    ac.bump("0x1111");
    ac.bump("0x2222");
    expect(ac.count("0x1111")).toBe(2);
    expect(ac.count("0x2222")).toBe(1);
    expect(ac.count("0x3333")).toBe(0);
  });

  test("evicts old counts per address", async () => {
    ac.bump("0x1111");
    await new Promise(r => setTimeout(r, 1100));
    ac.bump("0x1111");
    expect(ac.count("0x1111")).toBe(1);
  });
});

describe("State utilities", () => {
  beforeEach(() => {
    // Reset state
    state.alertsByCategory.clear();
    state.elevatedAlert = false;
    state.elevatedUntil = 0;
  });

  test("recordAlert increments counter", () => {
    recordAlert("TEST");
    recordAlert("TEST");
    expect(state.alertsByCategory.get("TEST")).toBe(2);
  });

  test("maybeElevateAlerts sets elevated mode", () => {
    maybeElevateAlerts();
    expect(isElevated()).toBe(true);
  });

  test("elevated mode expires after 1 hour", () => {
    state.elevatedAlert = true;
    state.elevatedUntil = Date.now() - 1000; // 1 second ago
    expect(isElevated()).toBe(false);
    expect(state.elevatedAlert).toBe(false);
  });
});

describe("Detector: detectPauseEvents", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {
        "event Paused(address account)": [],
      },
    });
  });

  test("returns empty if no pause events", () => {
    const findings = detectPauseEvents(mockTxEvent, deployment);
    expect(findings).toEqual([]);
  });

  test("detects pause on monitored contract", () => {
    const pauseEvent = {
      address: deployment.token,
      args: { account: "0xAdmin123" },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([pauseEvent]);

    const findings = detectPauseEvents(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("🚨 ZEUSYXA Contract Paused");
    expect(findings[0].severity).toBe(FindingSeverity.Critical);
    expect(findings[0].metadata.pauser).toBe("0xAdmin123");
  });

  test("ignores pause on non-monitored contract", () => {
    const pauseEvent = {
      address: "0x9999999999999999999999999999999999999999",
      args: { account: "0xAdmin123" },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([pauseEvent]);

    const findings = detectPauseEvents(mockTxEvent, deployment);
    expect(findings).toEqual([]);
  });
});

describe("Detector: detectUnpause", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {
        "event Unpaused(address account)": [],
      },
    });
  });

  test("detects unpause on monitored contract", () => {
    const unpauseEvent = {
      address: deployment.token,
      args: { account: "0xAdmin123" },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([unpauseEvent]);

    const findings = detectUnpause(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("✅ ZEUSYXA Contract Unpaused");
    expect(findings[0].severity).toBe(FindingSeverity.High);
  });
});

describe("Detector: detectLargeBridgeMint", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {
        "event BridgeMinted(address indexed to, uint256 amount)": [],
      },
    });
    // Reset mints24h
    state.mints24h.items = [];
  });

  test("returns empty if no token deployed", () => {
    const findings = detectLargeBridgeMint(mockTxEvent, { ...deployment, token: null });
    expect(findings).toEqual([]);
  });

  test("detects huge mint above threshold", () => {
    const hugeAmount = ethers.utils.parseEther("200000"); // 200K > 100K threshold
    const mintEvent = {
      address: deployment.token,
      args: { to: "0xRecipient123", amount: hugeAmount },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([mintEvent]);

    const findings = detectLargeBridgeMint(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("⚠️  Unusually Large Bridge Mint");
    expect(findings[0].metadata.isHuge).toBe("true");
  });

  test("detects spike above rolling average", () => {
    // Add some history - need enough samples to get an average
    for (let i = 0; i < 10; i++) {
      state.mints24h.add(ethers.utils.parseEther("1000").toString()); // 1K avg
    }
    
    const spikeAmount = ethers.utils.parseEther("10000"); // 10K = 10x avg
    const mintEvent = {
      address: deployment.token,
      args: { to: "0xRecipient123", amount: spikeAmount },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([mintEvent]);

    const findings = detectLargeBridgeMint(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].metadata.isSpike).toBe("true");
  });
});

describe("Detector: detectAdminActions", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {},
    });
    // Reset elevated state
    state.elevatedAlert = false;
    state.elevatedUntil = 0;
  });

  test("detects bridge change proposed", () => {
    const event = {
      address: deployment.token,
      args: { newBridge: "0xNewBridge123", activatesAt: Math.floor(Date.now() / 1000) + 86400 },
    };
    mockTxEvent.filterLog.mockImplementation((abi) => {
      if (abi === "event BridgeChangeProposed(address indexed newBridge, uint256 activatesAt)") return [event];
      return [];
    });

    const findings = detectAdminActions(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("🔐 Admin Action: Bridge Change Proposed");
    expect(findings[0].severity).toBe(FindingSeverity.High);
  });

  test("detects ownership transfer started (critical)", () => {
    const event = {
      address: deployment.token,
      args: { previousOwner: "0xOldOwner", newOwner: "0xNewOwner" },
    };
    mockTxEvent.filterLog.mockImplementation((abi) => {
      if (abi === "event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)") return [event];
      return [];
    });

    const findings = detectAdminActions(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("🔐 Admin Action: Ownership Transfer STARTED");
    expect(findings[0].severity).toBe(FindingSeverity.Critical);
  });
});

describe("Detector: detectLargeBurn", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {
        "event Transfer(address indexed from, address indexed to, uint256 value)": [],
      },
    });
    state.burns1h.items = [];
  });

  test("detects large burn to zero address", () => {
    const burnAmount = ethers.utils.parseEther("20000"); // 20K > 10K threshold
    const burnEvent = {
      address: deployment.token,
      args: { from: "0xBurner123", to: ethers.constants.AddressZero, value: burnAmount },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([burnEvent]);

    const findings = detectLargeBurn(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("🔥 Large ZYX Burn");
    expect(findings[0].metadata.burner).toBe("0xBurner123");
  });

  test("ignores regular transfers", () => {
    const transferEvent = {
      address: deployment.token,
      args: { from: "0xFrom123", to: "0xTo456", value: ethers.utils.parseEther("50000") },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([transferEvent]);

    const findings = detectLargeBurn(mockTxEvent, deployment);
    expect(findings).toEqual([]);
  });
});

describe("Detector: detectChannelAnomalies", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {
        "event ChannelOpened(bytes32 indexed channelId, address indexed payer, address indexed payee, uint256 deposit)": [],
        "event ChannelForceClosed(bytes32 indexed channelId, uint256 refund)": [],
      },
    });
    state.channelOpensPerAddress.byAddress.clear();
  });

  test("detects large channel open", () => {
    const deposit = ethers.utils.parseEther("200000"); // 200K > 100K threshold
    const openEvent = {
      address: deployment.channel,
      args: { channelId: "0xChannel123", payer: "0xPayer123", payee: "0xPayee456", deposit },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([openEvent]);

    const findings = detectChannelAnomalies(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("💰 Large Payment Channel Opened");
  });

  test("detects rapid channel opens from same address", () => {
    // Need to bump 11 times so the 12th triggers the alert (> 10 threshold)
    for (let i = 0; i < 11; i++) {
      state.channelOpensPerAddress.bump("0xSpammer123");
    }
    
    // Use a large deposit to also trigger the LARGE_CHANNEL_DEPOSIT finding
    const openEvent = {
      address: deployment.channel,
      args: { channelId: "0xChannelNew", payer: "0xSpammer123", payee: "0xPayee456", deposit: ethers.utils.parseEther("200000") },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([openEvent]);

    const findings = detectChannelAnomalies(mockTxEvent, deployment);
    expect(findings).toHaveLength(2); // Large deposit + spam
    const spamFinding = findings.find(f => f.alertId === "ZEUSYXA-CHANNEL-SPAM");
    expect(spamFinding).toBeDefined();
    expect(spamFinding.metadata.count).toBe("12");
  });

  test("detects large force close", () => {
    const refund = ethers.utils.parseEther("20000"); // 20K > 10K threshold
    const closeEvent = {
      address: deployment.channel,
      args: { channelId: "0xChannel123", refund },
    };
    mockTxEvent.filterLog.mockImplementation((abi) => {
      if (abi === "event ChannelForceClosed(bytes32 indexed channelId, uint256 refund)") return [closeEvent];
      return [];
    });

    const findings = detectChannelAnomalies(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("⚡ Large Channel Force-Close");
  });
});

describe("Detector: detectModelPriceManipulation", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {
        "event ModelPriceUpdated(uint256 indexed modelId, uint256 newPrice)": [],
      },
    });
    state.modelPrices.clear();
  });

  test("detects 10x price increase", () => {
    const oldPrice = ethers.utils.parseEther("100");
    state.modelPrices.set("1", oldPrice.toString());
    
    const newPrice = ethers.utils.parseEther("2000"); // 20x old price
    const priceEvent = {
      address: deployment.market,
      args: { modelId: 1, newPrice },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([priceEvent]);

    const findings = detectModelPriceManipulation(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("📊 Model Price Manipulation");
  });

  test("detects 10x price decrease", () => {
    const oldPrice = ethers.utils.parseEther("2000");
    state.modelPrices.set("1", oldPrice.toString());
    
    const newPrice = ethers.utils.parseEther("100"); // 20x drop
    const priceEvent = {
      address: deployment.market,
      args: { modelId: 1, newPrice },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([priceEvent]);

    const findings = detectModelPriceManipulation(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
  });

  test("no alert for first price set", () => {
    const newPrice = ethers.utils.parseEther("100");
    const priceEvent = {
      address: deployment.market,
      args: { modelId: 1, newPrice },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([priceEvent]);

    const findings = detectModelPriceManipulation(mockTxEvent, deployment);
    expect(findings).toEqual([]);
  });
});

describe("Detector: detectReputationAbuse", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {
        "event ReputationChanged(bytes32 indexed agentId, int32 delta, uint32 newScore, address oracle)": [],
      },
    });
  });

  test("detects large reputation drop", () => {
    const repEvent = {
      address: deployment.registry,
      args: { 
        agentId: "0xAgent123", 
        delta: -4000, // -40% < -30% threshold
        newScore: 6000,
        oracle: "0xOracle123" 
      },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([repEvent]);

    const findings = detectReputationAbuse(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("📉 Large Reputation Drop");
    expect(findings[0].metadata.delta).toBe("-4000");
  });

  test("ignores small reputation changes", () => {
    const repEvent = {
      address: deployment.registry,
      args: { 
        agentId: "0xAgent123", 
        delta: -1000, // -10% > -30% threshold
        newScore: 9000,
        oracle: "0xOracle123" 
      },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([repEvent]);

    const findings = detectReputationAbuse(mockTxEvent, deployment);
    expect(findings).toEqual([]);
  });
});

describe("Detector: detectWhaleTransfers", () => {
  let mockTxEvent;
  const deployment = DEPLOYMENTS[84532];

  beforeEach(() => {
    mockTxEvent = createMockTxEvent({
      chainId: 84532,
      events: {
        "event Transfer(address indexed from, address indexed to, uint256 value)": [],
      },
    });
  });

  test("detects whale transfer", () => {
    const amount = ethers.utils.parseEther("2000000"); // 2M > 1M threshold
    const transferEvent = {
      address: deployment.token,
      args: { from: "0xWhale123", to: "0xRecipient456", value: amount },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([transferEvent]);

    const findings = detectWhaleTransfers(mockTxEvent, deployment);
    expect(findings).toHaveLength(1);
    expect(findings[0].name).toBe("🐋 Whale ZYX Transfer");
    expect(findings[0].severity).toBe(FindingSeverity.Info);
  });

  test("ignores mints (from zero address)", () => {
    const amount = ethers.utils.parseEther("2000000");
    const mintEvent = {
      address: deployment.token,
      args: { from: ethers.constants.AddressZero, to: "0xRecipient456", value: amount },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([mintEvent]);

    const findings = detectWhaleTransfers(mockTxEvent, deployment);
    expect(findings).toEqual([]);
  });

  test("ignores burns (to zero address)", () => {
    const amount = ethers.utils.parseEther("2000000");
    const burnEvent = {
      address: deployment.token,
      args: { from: "0xWhale123", to: ethers.constants.AddressZero, value: amount },
    };
    mockTxEvent.filterLog.mockReturnValueOnce([burnEvent]);

    const findings = detectWhaleTransfers(mockTxEvent, deployment);
    expect(findings).toEqual([]);
  });
});