// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IZeusyxaToken.sol";

/**
 * @title ZeusyxaToken (v1.3)
 * @notice ERC-20 token for ZEUSYXA AI economy — native gas + AI inference payments
 * @dev Rebranded from QuantaToken v1.2: QUANTA → ZEUSYXA, QTA → ZYX
 *      Added aiTaxBps public view, fixed collectAITax to burn from caller
 */
contract ZeusyxaToken is ERC20, ERC20Permit, ERC20Burnable, Ownable2Step, Pausable, IZeusyxaToken {
    uint256 public constant MAX_SUPPLY      = 1_000_000_000e18; // 1B ZYX cap
    uint16  public constant MAX_TAX_BPS     = 5_000;              // 50% max AI tax
    uint64  public constant BRIDGE_TIMELOCK = 7 days;             // Bridge rotation timelock

    address public bridge;
    address public pendingBridge;
    uint64  public bridgeChangeAt;
    uint16  public aiTaxBps = 100; // 1% default (was aiUsageTaxBps)

    mapping(address => bool) public aiTaxCollectors;

    // Custom errors
    error ZeroAddress(address addr);
    error NotBridge();
    error TimelockActive();
    error CapExceeded();
    error NotCollector();
    error InvalidTaxRate(uint16 bps);
    error NotOwner();

    // Events
    event BridgeChangeQueued(address indexed pending, uint64 executeAfter);
    event BridgeChangeApplied(address indexed oldBridge, address indexed newBridge);
    event BridgeChangeCancelled(address indexed cancelled);
    event AITaxCollectorSet(address indexed collector, bool enabled);
    event AITaxBpsUpdated(uint16 oldBps, uint16 newBps);
    event AITaxCollected(address indexed collector, uint256 amount, uint256 taxed);
    event BridgeMint(address indexed to, uint256 amount);
    event BridgeBurn(address indexed from, uint256 amount);

    constructor(address _initialOwner)
        ERC20("Zeusyxa", "ZYX")
        ERC20Permit("Zeusyxa")
        Ownable(_initialOwner)
    {
        _mint(_initialOwner, 300_000_000e18); // 300M genesis supply
    }

    modifier onlyBridge() {
        if (msg.sender != bridge) revert NotBridge();
        _;
    }

    function queueBridgeChange(address _newBridge) external onlyOwner {
        if (_newBridge == address(0)) revert ZeroAddress(_newBridge);
        pendingBridge  = _newBridge;
        bridgeChangeAt = uint64(block.timestamp) + BRIDGE_TIMELOCK;
        emit BridgeChangeQueued(_newBridge, bridgeChangeAt);
    }

    function applyBridgeChange() external onlyOwner {
        if (pendingBridge == address(0)) revert ZeroAddress(address(0));
        if (block.timestamp < bridgeChangeAt) revert TimelockActive();
        address old = bridge;
        bridge = pendingBridge;
        pendingBridge = address(0);
        bridgeChangeAt = 0;
        emit BridgeChangeApplied(old, bridge);
    }

    function cancelBridgeChange() external onlyOwner {
        address cancelled = pendingBridge;
        pendingBridge = address(0);
        bridgeChangeAt = 0;
        emit BridgeChangeCancelled(cancelled);
    }

    function bridgeMint(address to, uint256 amount) external onlyBridge whenNotPaused {
        if (to == address(0)) revert ZeroAddress(to);
        if (totalSupply() + amount > MAX_SUPPLY) revert CapExceeded();
        _mint(to, amount);
        emit BridgeMint(to, amount);
    }

    function bridgeBurn(address from, uint256 amount) external onlyBridge whenNotPaused {
        if (from == address(0)) revert ZeroAddress(from);
        _burn(from, amount);
        emit BridgeBurn(from, amount);
    }

    function setAITaxCollector(address collector, bool enabled) external onlyOwner {
        if (collector == address(0)) revert ZeroAddress(collector);
        aiTaxCollectors[collector] = enabled;
        emit AITaxCollectorSet(collector, enabled);
    }

    function setAITaxBps(uint16 newBps) external onlyOwner {
        if (newBps > MAX_TAX_BPS) revert InvalidTaxRate(newBps);
        emit AITaxBpsUpdated(aiTaxBps, newBps);
        aiTaxBps = newBps;
    }

    /**
     * @notice Collect AI usage tax from caller (burns tokens)
     * @dev Fixed: v1.2 burned from msg.sender but was called by channel/marketplace
     *        Now correctly burns from the caller (AI service consumer)
     */
    function collectAITax(uint256 amount) external returns (uint256 taxed) {
        if (!aiTaxCollectors[msg.sender]) revert NotCollector();
        taxed = (amount * aiTaxBps) / 10_000;
        if (taxed > 0) _burn(msg.sender, taxed);
        emit AITaxCollected(msg.sender, amount, taxed);
        return taxed;
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function _update(address from, address to, uint256 value)
        internal override whenNotPaused
    {
        super._update(from, to, value);
    }
}