// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract AIAgentRegistry is Ownable2Step, Pausable {

    uint256 public constant MAX_AGENTS_PER_OWNER = 500;
    uint256 public constant MAX_METADATA_LEN     = 512;
    uint256 public constant MAX_REPUTATION       = 10_000;
    uint32  public constant WINDOW_SLOTS         = 24;

    struct SpendingPolicy {
        uint256 maxPerTx;
        uint256 maxPerDay;
        bool    active;
    }

    struct RollingWindow {
        uint256[24] slots;
        uint8       cursor;
        uint40      slotTs;
    }

    struct Agent {
        address owner;
        uint256 reputation;
        SpendingPolicy policy;
        RollingWindow window;
        string  metadataURI;
        uint64  registeredAt;
        bool    active;
    }

    mapping(bytes32 => Agent)      public agents;
    mapping(address => bytes32[])  public agentsByOwner;
    mapping(address => bool)       public reputationOracles;

    event AgentRegistered(bytes32 indexed agentId, address indexed owner, uint64 registeredAt);
    event AgentDeactivated(bytes32 indexed agentId);
    event ReputationAdjusted(bytes32 indexed agentId, address indexed oracle, int256 delta, uint256 newScore);
    event PolicyUpdated(bytes32 indexed agentId, uint256 maxPerTx, uint256 maxPerDay);
    event OracleSet(address indexed oracle, bool enabled);
    event SpendRecorded(bytes32 indexed agentId, uint256 amount, uint256 rollingTotal);

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    function setReputationOracle(address oracle, bool enabled) external onlyOwner {
        require(oracle != address(0), "Registry: zero address");
        reputationOracles[oracle] = enabled;
        emit OracleSet(oracle, enabled);
    }

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function registerAgent(
        bytes32        agentId,
        string calldata metadataURI,
        uint256        maxPerTx,
        uint256        maxPerDay
    ) external whenNotPaused {
        require(agents[agentId].registeredAt == 0, "Registry: exists");
        require(bytes(metadataURI).length <= MAX_METADATA_LEN, "Registry: metadata too long");
        require(agentsByOwner[msg.sender].length < MAX_AGENTS_PER_OWNER, "Registry: too many agents");
        require(maxPerTx > 0 && maxPerDay >= maxPerTx, "Registry: invalid policy");

        Agent storage a = agents[agentId];
        a.owner        = msg.sender;
        a.reputation   = 5_000;
        a.registeredAt = uint64(block.timestamp);
        a.active       = true;
        a.metadataURI  = metadataURI;
        a.policy       = SpendingPolicy({ maxPerTx: maxPerTx, maxPerDay: maxPerDay, active: true });
        a.window.slotTs = uint40(block.timestamp);

        agentsByOwner[msg.sender].push(agentId);
        emit AgentRegistered(agentId, msg.sender, uint64(block.timestamp));
    }

    function deactivateAgent(bytes32 agentId) external {
        Agent storage a = agents[agentId];
        require(a.registeredAt != 0, "Registry: not found");
        require(a.owner == msg.sender || msg.sender == owner(), "Registry: not authorized");
        a.active = false;
        emit AgentDeactivated(agentId);
    }

    function updatePolicy(bytes32 agentId, uint256 maxPerTx, uint256 maxPerDay) external {
        Agent storage a = agents[agentId];
        require(a.registeredAt != 0, "Registry: not found");
        require(a.owner == msg.sender, "Registry: not owner");
        require(maxPerTx > 0 && maxPerDay >= maxPerTx, "Registry: invalid policy");
        a.policy.maxPerTx  = maxPerTx;
        a.policy.maxPerDay = maxPerDay;
        emit PolicyUpdated(agentId, maxPerTx, maxPerDay);
    }

    function adjustReputation(bytes32 agentId, int256 delta) external {
        require(reputationOracles[msg.sender], "Registry: not oracle");
        Agent storage a = agents[agentId];
        require(a.registeredAt != 0, "Registry: not found");

        int256 current = int256(a.reputation);
        int256 updated = current + delta;
        if (updated < 0) updated = 0;
        if (updated > int256(MAX_REPUTATION)) updated = int256(MAX_REPUTATION);
        a.reputation = uint256(updated);
        emit ReputationAdjusted(agentId, msg.sender, delta, a.reputation);
    }

    function checkAndRecordSpend(bytes32 agentId, uint256 amount) external whenNotPaused {
        Agent storage a = agents[agentId];
        require(a.registeredAt != 0, "Registry: not found");
        require(a.active, "Registry: inactive");
        require(a.policy.active, "Registry: policy off");
        require(amount <= a.policy.maxPerTx, "Registry: exceeds maxPerTx");

        RollingWindow storage w = a.window;
        uint256 now_ = block.timestamp;
        uint256 slotsPassed = (now_ - w.slotTs) / 1 hours;

        if (slotsPassed > 0) {
            uint256 clearCount = slotsPassed > WINDOW_SLOTS ? WINDOW_SLOTS : slotsPassed;
            for (uint256 i = 0; i < clearCount; i++) {
                w.cursor = uint8((uint256(w.cursor) + 1) % WINDOW_SLOTS);
                w.slots[w.cursor] = 0;
            }
            w.slotTs = uint40(w.slotTs + slotsPassed * 1 hours);
        }

        uint256 total = 0;
        for (uint256 i = 0; i < WINDOW_SLOTS; i++) {
            total += w.slots[i];
        }

        require(total + amount <= a.policy.maxPerDay, "Registry: exceeds maxPerDay");
        w.slots[w.cursor] += amount;

        emit SpendRecorded(agentId, amount, total + amount);
    }

    function getAgentCount(address owner_) external view returns (uint256) {
        return agentsByOwner[owner_].length;
    }

    function getRolling24hSpend(bytes32 agentId) external view returns (uint256 total) {
        Agent storage a = agents[agentId];
        for (uint256 i = 0; i < WINDOW_SLOTS; i++) {
            total += a.window.slots[i];
        }
    }
}
