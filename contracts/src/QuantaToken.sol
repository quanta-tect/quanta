// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title QuantaToken (QTA)
 * @notice ERC-20 wrapped representation of QUANTA on EVM chains.
 *         Native token will run on QUANTA L1 — this is the bridge-able version
 *         with cùng cơ chế burn deflationary.
 *
 * Features:
 *  - ERC20Burnable: for phép tự đốt
 *  - ERC20Permit: gasless approval (EIP-2612)
 *  - ERC20Votes: governance ready (snapshot voting)
 *  - AI usage tax: 0.3% phí khi gọi qua AIPaymentChannel → burn
 *  - Hard cap 1 tỷ QTA
 *  - Bridge mint/burn (chỉ bridge contract was mint khi unlock từ L1)
 */
contract QuantaToken is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public constant GENESIS_SUPPLY = 300_000_000 * 1e18;

    /// @notice Bridge contract authorized to mint when assets locked on L1
    address public bridge;

    /// @notice AI usage tax in basis points (30 = 0.3%)
    uint16 public aiUsageTaxBps = 30;
    uint16 public constant MAX_TAX_BPS = 100; // never > 1%

    /// @notice Addresses authorized to charge AI tax (marketplaces, channels)
    mapping(address => bool) public aiTaxCollectors;

    /// @notice Total amount ever burned (for transparency)
    uint256 public totalBurned;

    event BridgeUpdated(address indexed bridge);
    event AITaxCollected(address indexed collector, uint256 amount);
    event AITaxRateUpdated(uint16 newBps);

    error CapExceeded();
    error OnlyBridge();
    error InvalidTaxRate();

    constructor(address initialOwner)
        ERC20("QUANTA", "QTA")
        ERC20Permit("QUANTA")
        Ownable(initialOwner)
    {
        // Mint genesis supply to treasury (initialOwner — should be multisig)
        _mint(initialOwner, GENESIS_SUPPLY);
    }

    // ------------------------------------------------------------------
    // Bridge interface (L1 ↔ L2)
    // ------------------------------------------------------------------

    function setBridge(address _bridge) external onlyOwner {
        bridge = _bridge;
        emit BridgeUpdated(_bridge);
    }

    /// @notice Bridge mints when L1 tokens are locked
    function bridgeMint(address to, uint256 amount) external {
        if (msg.sender != bridge) revert OnlyBridge();
        if (totalSupply() + amount > MAX_SUPPLY) revert CapExceeded();
        _mint(to, amount);
    }

    /// @notice Bridge burns when user wants to withdraw to L1
    function bridgeBurn(address from, uint256 amount) external {
        if (msg.sender != bridge) revert OnlyBridge();
        _burn(from, amount);
        totalBurned += amount;
    }

    // ------------------------------------------------------------------
    // AI usage tax — collected by authorized contracts
    // ------------------------------------------------------------------

    function setAITaxCollector(address collector, bool allowed) external onlyOwner {
        aiTaxCollectors[collector] = allowed;
    }

    function setAITaxRate(uint16 newBps) external onlyOwner {
        if (newBps > MAX_TAX_BPS) revert InvalidTaxRate();
        aiUsageTaxBps = newBps;
        emit AITaxRateUpdated(newBps);
    }

    /**
     * @notice Authorized collector charges AI usage tax — token is burned.
     *         This is THE mechanism that makes QTA deflationary as AI usage grows.
     */
    function collectAITax(address from, uint256 amount) external returns (uint256 taxed) {
        require(aiTaxCollectors[msg.sender], "not collector");
        taxed = (amount * aiUsageTaxBps) / 10_000;
        if (taxed > 0) {
            _burn(from, taxed);
            totalBurned += taxed;
            emit AITaxCollected(msg.sender, taxed);
        }
    }

    // ------------------------------------------------------------------
    // OZ overrides
    // ------------------------------------------------------------------

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
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
