// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;  // L-01: pinned

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title QuantaToken (QTA) v1.1 — Security-Hardened
 * @notice ERC-20 wrapped representation of QUANTA on EVM chains.
 *
 * Security improvements over v1.0:
 *  - C-06: collectAITax can only burn from msg.sender (not arbitrary `from`)
 *  - H-01: Bridge changes require 48h timelock
 *  - H-04: Pausable for emergency stop
 *  - I-01: Ownable2Step (2-step ownership transfer prevents typo loss)
 *  - L-01: Solidity version pinned
 *  - L-05: address(0) checks on all setters
 *  - I-05: Hard cap on tax rate (max 1%) to prevent governance abuse
 *
 * Security improvements over v1.1 (v1.2 hardening):
 *  - H-BRIDGE-01: bridgeMint rate-limited (max 1M QTA/day) to prevent rapid supply inflation
 *  - H-BRIDGE-02: bridgeBurn requires allowance — cannot burn from arbitrary holders
 *  - M-DEAD-01: Removed dead `from` parameter from collectAITax (Zcash-type code smell)
 */
contract QuantaToken is ERC20, ERC20Burnable, ERC20Pausable, ERC20Permit, ERC20Votes, Ownable2Step {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public constant GENESIS_SUPPLY = 300_000_000 * 1e18;

    // H-01: timelock for bridge changes
    uint256 public constant BRIDGE_CHANGE_DELAY = 48 hours;
    address public bridge;
    address public pendingBridge;
    uint256 public pendingBridgeActivatesAt;

    uint16 public aiUsageTaxBps = 30;
    uint16 public constant MAX_TAX_BPS = 100; // hard cap 1%

    mapping(address => bool) public aiTaxCollectors;
    uint256 public totalBurned;

    // H-BRIDGE-01: Rate limit bridge minting to prevent rapid supply inflation
    uint256 public constant MAX_BRIDGE_MINT_PER_DAY = 1_000_000 * 1e18; // 1M QTA/day
    uint256 public bridgeMintedToday;
    uint256 public bridgeMintDayStart;

    event BridgeChangeProposed(address indexed newBridge, uint256 activatesAt);
    event BridgeChangeExecuted(address indexed bridge);
    event AITaxCollectorSet(address indexed collector, bool allowed);  // M-01
    event AITaxCollected(address indexed collector, uint256 amount);
    event AITaxRateUpdated(uint16 newBps);
    event BridgeMinted(address indexed to, uint256 amount);  // M-01
    event BridgeBurned(address indexed from, uint256 amount);

    error CapExceeded();
    error OnlyBridge();
    error InvalidTaxRate();
    error ZeroAddress();
    error BridgeTimelockActive();
    error NoBridgeChangePending();
    error BridgeMintRateExceeded();
    error InsufficientBridgeBurnAllowance();

    constructor(address initialOwner)
        ERC20("QUANTA", "QTA")
        ERC20Permit("QUANTA")
        Ownable(initialOwner)
    {
        if (initialOwner == address(0)) revert ZeroAddress();
        _mint(initialOwner, GENESIS_SUPPLY);
    }

    // ------------------------------------------------------------------
    // Bridge (with timelock — H-01 fix)
    // ------------------------------------------------------------------

    function proposeBridge(address _bridge) external onlyOwner {
        if (_bridge == address(0)) revert ZeroAddress();
        pendingBridge = _bridge;
        pendingBridgeActivatesAt = block.timestamp + BRIDGE_CHANGE_DELAY;
        emit BridgeChangeProposed(_bridge, pendingBridgeActivatesAt);
    }

    function executeBridgeChange() external {
        if (pendingBridge == address(0)) revert NoBridgeChangePending();
        if (block.timestamp < pendingBridgeActivatesAt) revert BridgeTimelockActive();
        bridge = pendingBridge;
        pendingBridge = address(0);
        pendingBridgeActivatesAt = 0;
        emit BridgeChangeExecuted(bridge);
    }

    function cancelBridgeChange() external onlyOwner {
        pendingBridge = address(0);
        pendingBridgeActivatesAt = 0;
    }

    function bridgeMint(address to, uint256 amount) external whenNotPaused {
        if (msg.sender != bridge) revert OnlyBridge();
        if (to == address(0)) revert ZeroAddress();
        if (totalSupply() + amount > MAX_SUPPLY) revert CapExceeded();

        // H-BRIDGE-01: Rate limit — max 1M QTA per day
        if (block.timestamp >= bridgeMintDayStart + 1 days) {
            bridgeMintedToday = 0;
            bridgeMintDayStart = block.timestamp;
        }
        if (bridgeMintedToday + amount > MAX_BRIDGE_MINT_PER_DAY) revert BridgeMintRateExceeded();
        bridgeMintedToday += amount;
        _mint(to, amount);
        emit BridgeMinted(to, amount);
    }

    function bridgeBurn(address from, uint256 amount) external whenNotPaused {
        if (msg.sender != bridge) revert OnlyBridge();
        // H-BRIDGE-02: Cannot burn from arbitrary holders — requires allowance
        uint256 currentAllowance = allowance(from, msg.sender);
        if (currentAllowance < amount) revert InsufficientBridgeBurnAllowance();
        _burn(from, amount);
        totalBurned += amount;
        emit BridgeBurned(from, amount);
    }

    // ------------------------------------------------------------------
    // AI Tax — C-06 fix: only burns from msg.sender, not arbitrary address
    // ------------------------------------------------------------------

    function setAITaxCollector(address collector, bool allowed) external onlyOwner {
        if (collector == address(0)) revert ZeroAddress();
        aiTaxCollectors[collector] = allowed;
        emit AITaxCollectorSet(collector, allowed);
    }

    function setAITaxRate(uint16 newBps) external onlyOwner {
        if (newBps > MAX_TAX_BPS) revert InvalidTaxRate();
        aiUsageTaxBps = newBps;
        emit AITaxRateUpdated(newBps);
    }

    /**
     * @notice Burns AI usage tax from CALLER'S balance.
     *         Caller (Marketplace/Channel) must hold the tokens being taxed.
     *         FIX M-DEAD-01: removed dead `from` parameter (Zcash-type code smell).
     * @param amount Amount to compute tax against
     * @return taxed Actual amount burned
     */
    function collectAITax(uint256 amount) external returns (uint256 taxed) {
        require(aiTaxCollectors[msg.sender], "not collector");

        taxed = (amount * aiUsageTaxBps) / 10_000;
        if (taxed > 0) {
            _burn(msg.sender, taxed);
            totalBurned += taxed;
            emit AITaxCollected(msg.sender, taxed);
        }
    }

    // ------------------------------------------------------------------
    // Emergency pause (H-04 fix)
    // ------------------------------------------------------------------

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ------------------------------------------------------------------
    // OZ multiple-inheritance overrides
    // ------------------------------------------------------------------

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }
}
