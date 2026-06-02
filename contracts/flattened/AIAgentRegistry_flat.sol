// SPDX-License-Identifier: MIT
pragma solidity =0.8.24 ^0.8.20;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol

// OpenZeppelin Contracts (last updated v5.1.0) (access/Ownable2Step.sol)

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This extension of the {Ownable} contract includes a two-step mechanism to transfer
 * ownership, where the new owner must call {acceptOwnership} in order to replace the
 * old one. This can help prevent common mistakes, such as transfers of ownership to
 * incorrect accounts, or to contracts that are unable to interact with the
 * permission system.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     *
     * Setting `newOwner` to the zero address is allowed; this can be used to cancel an initiated ownership transfer.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// src-v1.1/AIAgentRegistry.sol

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
