// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title AIAgentRegistry v1.1 — Security-Hardened
 *
 * Fixes vs v1.0:
 *  - C-02: adjustReputation now gated to whitelisted oracles (was open to anyone)
 *  - L-03: max metadata URI length to prevent storage bloat
 *  - L-05: address(0) checks
 *  - M-02: SafeCast on uint128 arithmetic
 *  - H-02: Daily window documented as sliding window (acceptable)
 */
contract AIAgentRegistry is Ownable2Step {
    struct SpendingPolicy {
        uint128 maxPerTx;
        uint128 maxPerDay;
        uint64  deathSwitchSec;
        bool    requireIntent;
    }

    struct Agent {
        address owner;
        address wallet;
        string  name;
        string  metadataURI;
        SpendingPolicy policy;
        uint64  registeredAt;
        uint64  lastPing;
        uint32  reputation;
        uint128 spentToday;
        uint64  todayStarted;
        bool    active;
    }

    uint256 public constant MAX_METADATA_LEN = 512;
    uint256 public constant MAX_NAME_LEN = 64;

    mapping(bytes32 => Agent) public agents;
    mapping(address => bytes32[]) public agentsByOwner;
    bytes32[] public allAgents;

    // C-02: only whitelisted oracles can adjust reputation
    mapping(address => bool) public reputationOracles;

    event AgentRegistered(bytes32 indexed agentId, address indexed owner, string name, address wallet);
    event AgentPinged(bytes32 indexed agentId, uint64 timestamp);
    event PolicyUpdated(bytes32 indexed agentId);
    event SpendRecorded(bytes32 indexed agentId, uint256 amount, address recipient);
    event ReputationChanged(bytes32 indexed agentId, int32 delta, uint32 newScore, address oracle);
    event AgentDeactivated(bytes32 indexed agentId, string reason);
    event ReputationOracleSet(address indexed oracle, bool allowed);

    error AgentNotFound();
    error NotOwner();
    error AgentInactive();
    error PolicyViolation(string reason);
    error DeathSwitchTriggered();
    error MetadataTooLong();
    error NameTooLong();
    error ZeroAddress();
    error NotReputationOracle();

    constructor(address initialOwner) Ownable(initialOwner) {
        if (initialOwner == address(0)) revert ZeroAddress();
    }

    modifier onlyAgentOwner(bytes32 agentId) {
        if (agents[agentId].owner != msg.sender) revert NotOwner();
        _;
    }

    // ------------------------------------------------------------------
    // Registration
    // ------------------------------------------------------------------

    function registerAgent(
        string calldata name,
        address wallet,
        string calldata metadataURI,
        SpendingPolicy calldata policy
    ) external returns (bytes32 agentId) {
        if (wallet == address(0)) revert ZeroAddress();
        if (bytes(name).length > MAX_NAME_LEN) revert NameTooLong();
        if (bytes(metadataURI).length > MAX_METADATA_LEN) revert MetadataTooLong();
        if (policy.maxPerTx == 0 || policy.maxPerDay == 0) revert PolicyViolation("zero limit");
        if (policy.maxPerTx > policy.maxPerDay) revert PolicyViolation("per_tx > per_day");
        if (policy.deathSwitchSec < 1 hours) revert PolicyViolation("deathSwitch < 1h");

        agentId = keccak256(abi.encode(msg.sender, name));
        require(agents[agentId].registeredAt == 0, "exists");

        agents[agentId] = Agent({
            owner: msg.sender,
            wallet: wallet,
            name: name,
            metadataURI: metadataURI,
            policy: policy,
            registeredAt: uint64(block.timestamp),
            lastPing: uint64(block.timestamp),
            reputation: 5000,
            spentToday: 0,
            todayStarted: uint64(block.timestamp),
            active: true
        });

        agentsByOwner[msg.sender].push(agentId);
        allAgents.push(agentId);

        emit AgentRegistered(agentId, msg.sender, name, wallet);
    }

    function ping(bytes32 agentId) external {
        Agent storage a = agents[agentId];
        if (a.registeredAt == 0) revert AgentNotFound();
        require(msg.sender == a.owner || msg.sender == a.wallet, "unauthorized");
        a.lastPing = uint64(block.timestamp);
        emit AgentPinged(agentId, uint64(block.timestamp));
    }

    function isAlive(bytes32 agentId) public view returns (bool) {
        Agent memory a = agents[agentId];
        if (!a.active) return false;
        return (block.timestamp - a.lastPing) <= a.policy.deathSwitchSec;
    }

    function deactivate(bytes32 agentId, string calldata reason) external onlyAgentOwner(agentId) {
        agents[agentId].active = false;
        emit AgentDeactivated(agentId, reason);
    }

    function updatePolicy(bytes32 agentId, SpendingPolicy calldata newPolicy)
        external
        onlyAgentOwner(agentId)
    {
        if (newPolicy.maxPerTx == 0 || newPolicy.maxPerDay == 0) revert PolicyViolation("zero limit");
        if (newPolicy.maxPerTx > newPolicy.maxPerDay) revert PolicyViolation("per_tx > per_day");
        agents[agentId].policy = newPolicy;
        emit PolicyUpdated(agentId);
    }

    function checkAndRecordSpend(bytes32 agentId, uint256 amount, address recipient)
        external
        returns (bool)
    {
        Agent storage a = agents[agentId];
        if (a.registeredAt == 0) revert AgentNotFound();
        if (!a.active) revert AgentInactive();
        if (msg.sender != a.wallet) revert NotOwner();
        if (!isAlive(agentId)) revert DeathSwitchTriggered();

        if (amount > a.policy.maxPerTx) revert PolicyViolation("max_per_tx");
        if (amount > type(uint128).max) revert PolicyViolation("amount overflow"); // M-02

        // Sliding 24h window (documented as known approximation, H-02)
        if (block.timestamp - a.todayStarted >= 1 days) {
            a.spentToday = 0;
            a.todayStarted = uint64(block.timestamp);
        }
        uint256 newSpent = uint256(a.spentToday) + amount;
        if (newSpent > a.policy.maxPerDay) {
            revert PolicyViolation("max_per_day");
        }
        if (newSpent > type(uint128).max) revert PolicyViolation("spent overflow");

        a.spentToday = uint128(newSpent);
        a.lastPing = uint64(block.timestamp);

        emit SpendRecorded(agentId, amount, recipient);
        return true;
    }

    // ------------------------------------------------------------------
    // Reputation — C-02 fix: oracle-gated
    // ------------------------------------------------------------------

    function setReputationOracle(address oracle, bool allowed) external onlyOwner {
        if (oracle == address(0)) revert ZeroAddress();
        reputationOracles[oracle] = allowed;
        emit ReputationOracleSet(oracle, allowed);
    }

    function adjustReputation(bytes32 agentId, int32 delta) external {
        if (!reputationOracles[msg.sender]) revert NotReputationOracle();  // C-02 fix

        Agent storage a = agents[agentId];
        if (a.registeredAt == 0) revert AgentNotFound();

        int64 newScore = int64(uint64(a.reputation)) + delta;
        if (newScore < 0) newScore = 0;
        if (newScore > 10000) newScore = 10000;
        a.reputation = uint32(uint64(newScore));

        emit ReputationChanged(agentId, delta, a.reputation, msg.sender);
    }

    // ------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------

    function agentCount() external view returns (uint256) {
        return allAgents.length;
    }

    function getAgentsByOwner(address owner) external view returns (bytes32[] memory) {
        return agentsByOwner[owner];
    }

    /// @notice Paginated to avoid OOG on large owners (L-04)
    function getAgentsByOwnerPaged(address owner, uint256 offset, uint256 limit)
        external view returns (bytes32[] memory page)
    {
        bytes32[] storage all = agentsByOwner[owner];
        if (offset >= all.length) return new bytes32[](0);
        uint256 end = offset + limit;
        if (end > all.length) end = all.length;
        page = new bytes32[](end - offset);
        for (uint256 i = 0; i < page.length; i++) {
            page[i] = all[offset + i];
        }
    }
}
