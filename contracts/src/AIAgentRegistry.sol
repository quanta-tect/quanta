// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AIAgentRegistry
 * @notice On-chain identity + spending policy + reputation for AI agents.
 *
 * Mỗi AI agent có:
 *  - Owner (EOA or multisig) — người create ra agent
 *  - Wallet address — ví riêng of agent (smart account)
 *  - Spending policy — giới hạn chi tiêu
 *  - Reputation score — increases/decreases based on behavior
 *  - Death switch — tự refund if không ping in N ngày
 *
 * Dùng was for mọi AI framework: LangChain, AutoGPT, CrewAI, Claude Computer Use...
 */
contract AIAgentRegistry {
    struct SpendingPolicy {
        uint128 maxPerTx;        // Wei
        uint128 maxPerDay;       // Wei
        uint64  deathSwitchSec;  // seconds without ping → refund
        bool    requireIntent;   // require signed intent vs raw tx
    }

    struct Agent {
        address owner;
        address wallet;          // smart account address
        string  name;
        string  metadataURI;     // IPFS URI: capabilities, model card, etc
        SpendingPolicy policy;
        uint64  registeredAt;
        uint64  lastPing;
        uint32  reputation;      // 0-10000, starts at 5000
        uint128 spentToday;
        uint64  todayStarted;
        bool    active;
    }

    mapping(bytes32 => Agent) public agents;       // agentId = keccak256(owner, name)
    mapping(address => bytes32[]) public agentsByOwner;
    bytes32[] public allAgents;

    event AgentRegistered(bytes32 indexed agentId, address indexed owner, string name, address wallet);
    event AgentPinged(bytes32 indexed agentId, uint64 timestamp);
    event PolicyUpdated(bytes32 indexed agentId);
    event SpendRecorded(bytes32 indexed agentId, uint256 amount, address recipient);
    event ReputationChanged(bytes32 indexed agentId, int32 delta, uint32 newScore);
    event AgentDeactivated(bytes32 indexed agentId, string reason);

    error AgentNotFound();
    error NotOwner();
    error AgentInactive();
    error PolicyViolation(string reason);
    error DeathSwitchTriggered();

    modifier onlyOwner(bytes32 agentId) {
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
        agentId = keccak256(abi.encode(msg.sender, name));
        require(agents[agentId].registeredAt == 0, "exists");
        require(wallet != address(0), "zero wallet");

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

    // ------------------------------------------------------------------
    // Lifecycle
    // ------------------------------------------------------------------

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

    function deactivate(bytes32 agentId, string calldata reason) external onlyOwner(agentId) {
        agents[agentId].active = false;
        emit AgentDeactivated(agentId, reason);
    }

    function updatePolicy(bytes32 agentId, SpendingPolicy calldata newPolicy)
        external
        onlyOwner(agentId)
    {
        agents[agentId].policy = newPolicy;
        emit PolicyUpdated(agentId);
    }

    // ------------------------------------------------------------------
    // Spending enforcement — called by AI Agent's smart wallet
    // ------------------------------------------------------------------

    /**
     * @notice Check + record spending. Reverts if policy violated.
     *         AI agent's smart account calls this before executing any tx.
     */
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

        // Reset daily window
        if (block.timestamp - a.todayStarted >= 1 days) {
            a.spentToday = 0;
            a.todayStarted = uint64(block.timestamp);
        }
        if (uint256(a.spentToday) + amount > a.policy.maxPerDay) {
            revert PolicyViolation("max_per_day");
        }

        a.spentToday += uint128(amount);
        a.lastPing = uint64(block.timestamp);

        emit SpendRecorded(agentId, amount, recipient);
        return true;
    }

    // ------------------------------------------------------------------
    // Reputation
    // ------------------------------------------------------------------

    /// @notice Marketplaces/services adjust reputation based on behavior.
    /// In production: gated to whitelisted reputation oracles.
    function adjustReputation(bytes32 agentId, int32 delta) external {
        Agent storage a = agents[agentId];
        if (a.registeredAt == 0) revert AgentNotFound();

        int64 newScore = int64(uint64(a.reputation)) + delta;
        if (newScore < 0) newScore = 0;
        if (newScore > 10000) newScore = 10000;
        a.reputation = uint32(uint64(newScore));

        emit ReputationChanged(agentId, delta, a.reputation);
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
}
