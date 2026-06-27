// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract QuantaToken is ERC20, ERC20Permit, ERC20Burnable, Ownable2Step, Pausable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY      = 1_000_000_000e18;
    uint16  public constant MAX_TAX_BPS     = 100;
    uint64  public constant BRIDGE_TIMELOCK = 48 hours;

    address public bridge;
    address public pendingBridge;
    uint64  public bridgeChangeAt;
    uint16  public aiUsageTaxBps = 30;

    mapping(address => bool) public aiTaxCollectors;

    // Custom errors
    error ZeroAddress(address addr);
    error NotBridge();
    error TimelockActive();
    error CapExceeded();
    error NotCollector();
    error InvalidTaxRate(uint16 bps);
    error NotOwner();

    event BridgeChangeQueued(address indexed pending, uint64 executeAfter);
    event BridgeChangeApplied(address indexed oldBridge, address indexed newBridge);
    event BridgeChangeCancelled(address indexed cancelled);
    event AITaxCollectorSet(address indexed collector, bool enabled);
    event AITaxBpsUpdated(uint16 oldBps, uint16 newBps);
    event AITaxCollected(address indexed collector, uint256 amount, uint256 taxed);
    event BridgeMint(address indexed to, uint256 amount);
    event BridgeBurn(address indexed from, uint256 amount);
    event TokensRecovered(address indexed token, address indexed to, uint256 amount);

    constructor(address _initialOwner)
        ERC20("Quanta", "QTA")
        ERC20Permit("Quanta")
        Ownable(_initialOwner)
    {
        _mint(_initialOwner, 300_000_000e18);
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
        require(pendingBridge != address(0), "QTA: no pending change");
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
        emit AITaxBpsUpdated(aiUsageTaxBps, newBps);
        aiUsageTaxBps = newBps;
    }

    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(this)) revert ZeroAddress(tokenAddress);
        IERC20(tokenAddress).safeTransfer(owner(), amount);
        emit TokensRecovered(tokenAddress, owner(), amount);
    }

    function collectAITax(uint256 amount) external returns (uint256 taxed) {
        if (!aiTaxCollectors[msg.sender]) revert NotCollector();
        taxed = (amount * aiUsageTaxBps) / 10_000;
        if (taxed > 0) _burn(msg.sender, taxed);
        emit AITaxCollected(msg.sender, amount, taxed);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function _update(address from, address to, uint256 value)
        internal override whenNotPaused
    {
        super._update(from, to, value);
    }
}
