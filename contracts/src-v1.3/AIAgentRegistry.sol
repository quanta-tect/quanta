// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title AIAgentRegistry (v1.3)
 * @notice Registry for AI agents with spending policies, reputation, and 24h rolling window
 * @dev Rebranded from v1.2: QUANTA → ZEUSYXA
 *      Fixed: MAX_AGENTS_PER_OWNER made public view (was internal constant)
 *      Added: getAgentCount returns uint256 (was external view)
 *      Added: explicit REPUTATION_ORACLE_ROLE for access control
 */
contract AIAgentRegistry is Ownable2Step, Pausable {
    uint256 public constant MAX_AGENTS_PER_OWNER = 500;
    uint256 public constant MAX_METADATA_LEN     = 512;
    uint256 public constant MAX_REPUTATION       = 10_000;
    uint32  public constant WINDOW_SLOTS         = 24;
    bytes32 public constant REPUTATION_ORACLE_ROLE = keccak256("REPUTATION_ORACLE_ROLE");

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
    mapping(bytes32 => bool)       public roleAssignments;

    // Custom errors
    error AgentAlreadyExists();
    error MetadataTooLong();
    error InvalidPolicy();
    error TooManyAgents();
    error NotAuthorized();
    error NotOwner();
    error NotReputationOracle();
    error ZeroAddress();
    error ExceedsMaxPerTx();
    error ExceedsMaxPerDay();
    error AgentNotFound(bytes32 agentId);
    error AgentInactive(bytes32 agentId);
    error PolicyInactive(bytes32 agentId);

    // Events
    event AgentRegistered(bytes32 indexed agentId, address indexed owner, uint64 registeredAt);
    event AgentDeactivated(bytes32 indexed agentId);
    event ReputationAdjusted(bytes32 indexed agentId, address indexed oracle, int256 delta, uint256 newScore);
    event PolicyUpdated(bytes32 indexed agentId, uint256 maxPerTx, uint256 maxPerDay);
    event OracleRoleGranted(address indexed oracle);
    event OracleRoleRevoked(address indexed oracle);
    event SpendRecorded(bytes32 indexed agentId, uint256 amount, uint256 rollingTotal);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    constructor(address _initialOwner) Ownable(_initialOwner) {
        _grantRole(REPUTATION_ORACLE_ROLE, _initialOwner);
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return roleAssignments[keccak256(abi.encode(role, account))];
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!roleAssignments[keccak256(abi.encode(role, account))]) {
            roleAssignments[keccak256(abi.encode(role, account))] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (roleAssignments[keccak256(abi.encode(role, account))]) {
            roleAssignments[keccak256(abi.encode(role, account))] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function grantReputationOracle(address oracle) external onlyOwner {
        if (oracle == address(0)) revert ZeroAddress();
        _grantRole(REPUTATION_ORACLE_ROLE, oracle);
        emit OracleRoleGranted(oracle);
    }

    function revokeReputationOracle(address oracle) external onlyOwner {
        _revokeRole(REPUTATION_ORACLE_ROLE, oracle);
        emit OracleRoleRevoked(oracle);
    }

    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function registerAgent(
        bytes32        agentId,
        string calldata metadataURI,
        uint256        maxPerTx,
        uint256        maxPerDay
    ) external whenNotPaused {
        if (agents[agentId].registeredAt != 0) revert AgentAlreadyExists();
        if (bytes(metadataURI).length > MAX_METADATA_LEN) revert MetadataTooLong();
        if (agentsByOwner[msg.sender].length >= MAX_AGENTS_PER_OWNER) revert TooManyAgents();
        if (maxPerTx == 0 || maxPerDay < maxPerTx) revert InvalidPolicy();

        Agent storage a = agents[agentId];
        a.owner        = msg.sender;
        a.reputation   = 5_000; // Start at neutral
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
        if (a.registeredAt == 0) revert AgentNotFound(agentId);
        if (a.owner != msg.sender && msg.sender != owner()) revert NotAuthorized();
        a.active = false;
        emit AgentDeactivated(agentId);
    }

    function updatePolicy(bytes32 agentId, uint256 maxPerTx, uint256 maxPerDay) external {
        Agent storage a = agents[agentId];
        if (a.registeredAt == 0) revert AgentNotFound(agentId);
        if (a.owner != msg.sender) revert NotOwner();
        if (maxPerTx == 0 || maxPerDay < maxPerTx) revert InvalidPolicy();
        a.policy.maxPerTx  = maxPerTx;
        a.policy.maxPerDay = maxPerDay;
        emit PolicyUpdated(agentId, maxPerTx, maxPerDay);
    }

    function adjustReputation(bytes32 agentId, int256 delta) external {
        if (!roleAssignments[keccak256(abi.encode(REPUTATION_ORACLE_ROLE, msg.sender))]) revert NotReputationOracle();
        Agent storage a = agents[agentId];
        if (a.registeredAt == 0) revert AgentNotFound(agentId);

        int256 current = int256(a.reputation);
        int256 updated = current + delta;
        if (updated < 0) updated = 0;
        if (updated > int256(MAX_REPUTATION)) updated = int256(MAX_REPUTATION);
        a.reputation = uint256(updated);
        emit ReputationAdjusted(agentId, msg.sender, delta, a.reputation);
    }

    function checkAndRecordSpend(bytes32 agentId, uint256 amount) external whenNotPaused {
        Agent storage a = agents[agentId];
        if (a.registeredAt == 0) revert AgentNotFound(agentId);
        if (!a.active) revert AgentInactive(agentId);
        if (!a.policy.active) revert PolicyInactive(agentId);
        if (amount > a.policy.maxPerTx) revert ExceedsMaxPerTx();

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

        if (total + amount > a.policy.maxPerDay) revert ExceedsMaxPerDay();
        w.slots[w.cursor] += amount;

        emit SpendRecorded(agentId, amount, total + amount);
    }

    function getAgentCount(address owner_) external view returns (uint256) {
        return agentsByOwner[owner_].length;
    }

    function getRolling24hSpend(bytes32 agentId) external view returns (uint256 total) {
        Agent storage a = agents[agentId];
        if (a.registeredAt == 0) revert AgentNotFound(agentId);
        for (uint256 i = 0; i < WINDOW_SLOTS; i++) {
            total += a.window.slots[i];
        }
    }
}