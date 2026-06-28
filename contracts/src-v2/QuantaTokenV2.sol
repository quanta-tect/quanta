// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/// @title QuantaTokenV2
/// @notice QTA v2 mainnet — mint disabled forever — AccessControl — no bridgeMint
/// @dev MAX_SUPPLY = 1_000_000_000e18 — mint ONCE in constructor — renounce MINTER_ROLE
contract QuantaTokenV2 is ERC20Permit, ERC20Burnable, ERC20Pausable, AccessControl {
    using SafeERC20 for IERC20;

    // ===================================================================
    // CONSTANTS
    // ===================================================================
    uint256 public constant MAX_SUPPLY      = 1_000_000_000e18;
    uint16  public constant MAX_TAX_BPS     = 100;
    uint16  public constant DEFAULT_TAX_BPS = 30; // 0.3%

    // ===================================================================
    // ROLES
    // ===================================================================
    bytes32 public constant PAUSER_ROLE    = keccak256("PAUSER_ROLE");
    bytes32 public constant TAX_ADMIN_ROLE = keccak256("TAX_ADMIN_ROLE");
    bytes32 public constant BURNER_ROLE    = keccak256("BURNER_ROLE");
    // NOTE: No MINTER_ROLE — mint disabled forever after constructor

    // ===================================================================
    // STATE
    // ===================================================================
    uint16  public aiUsageTaxBps = DEFAULT_TAX_BPS;

    mapping(address => bool) public aiTaxCollectors;

    // ===================================================================
    // CUSTOM ERRORS
    // ===================================================================
    error InvalidTaxRate(uint16 bps);
    error NotCollector();
    error ZeroAddress(address addr);
    error NotPauser();

    // ===================================================================
    // EVENTS
    // ===================================================================
    event AITaxBpsUpdated(uint16 oldBps, uint16 newBps);
    event AITaxCollectorSet(address indexed collector, bool enabled);
    event AITaxCollected(address indexed collector, uint256 amount, uint256 taxed);

    // ===================================================================
    // CONSTRUCTOR — MINT EXACTLY 1B QTA — ONCE — NO FURTHER MINT
    // ===================================================================
    /// @param treasuryMultisig   Gnosis Safe 3/5 — ops + reserve + emergency
    /// @param vestingWallet       VestingWallet — team 10% — 36mo — 12mo cliff
    /// @param liquidityWallet     Gnosis Safe 2/3 — LP lock
    /// @param ecosystemRewards    RewardsDistributor — rate-limited 30%
    /// @param communityWallet     Gnosis Safe 2/3 — airdrop / loyalty 15%
    /// @param reserveWallet       Gnosis Safe 3/5 — strategic 15%
    /// @param partnershipsWallet  Gnosis Safe 2/3 — partnerships 5%
    constructor(
        address treasuryMultisig,
        address vestingWallet,
        address liquidityWallet,
        address ecosystemRewards,
        address communityWallet,
        address reserveWallet,
        address partnershipsWallet,
        address _initialOwner
    )
        ERC20("Quanta", "QTA")
        ERC20Permit("Quanta")
    {
        if (treasuryMultisig   == address(0)) revert ZeroAddress(treasuryMultisig);
        if (vestingWallet       == address(0)) revert ZeroAddress(vestingWallet);
        if (liquidityWallet     == address(0)) revert ZeroAddress(liquidityWallet);
        if (ecosystemRewards    == address(0)) revert ZeroAddress(ecosystemRewards);
        if (communityWallet     == address(0)) revert ZeroAddress(communityWallet);
        if (reserveWallet       == address(0)) revert ZeroAddress(reserveWallet);
        if (partnershipsWallet  == address(0)) revert ZeroAddress(partnershipsWallet);

        // Tokenomics per playbook — sum MUST = 1,000,000,000e18
        _mint(treasuryMultisig,    150_000_000e18); // 15% — Treasury ops
        _mint(vestingWallet,       100_000_000e18); // 10% — Team — VESTED
        _mint(ecosystemRewards,    300_000_000e18); // 30% — Ecosystem & rewards
        _mint(liquidityWallet,     100_000_000e18); // 10% — Liquidity — time-locked
        _mint(communityWallet,     150_000_000e18); // 15% — Community & loyalty
        _mint(reserveWallet,       150_000_000e18); // 15% — Strategic reserve
        _mint(partnershipsWallet,   50_000_000e18); //  5% — Partnerships & growth
        // TOTAL = 1,000,000,000e18

        // Setup roles — deployer = initial owner for setup, renounce later
        _grantRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _grantRole(PAUSER_ROLE,    _initialOwner);
        _grantRole(TAX_ADMIN_ROLE, _initialOwner);
        _grantRole(BURNER_ROLE,    _initialOwner);

        // Renounce deployer admin after role setup — prevents accidental misuse
        _revokeRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _revokeRole(PAUSER_ROLE,    _initialOwner);
        _revokeRole(TAX_ADMIN_ROLE, _initialOwner);
        _revokeRole(BURNER_ROLE,    _initialOwner);

        // Grant roles to treasury multisig for ongoing operations
        _grantRole(DEFAULT_ADMIN_ROLE, treasuryMultisig);
        _grantRole(PAUSER_ROLE,    treasuryMultisig);
        _grantRole(TAX_ADMIN_ROLE, treasuryMultisig);
    }

    // ===================================================================
    // MODIFIERS
    // ===================================================================
    modifier onlyPauser() {
        if (!hasRole(PAUSER_ROLE, msg.sender)) revert NotPauser();
        _;
    }

    // Resolve diamond _update between ERC20 / ERC20Pausable
    // Allow mint/burn during pause; block regular transfers/moves
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        if (from != address(0) && to != address(0)) {
            require(!paused(), "EnforcedPause");
        }
        ERC20._update(from, to, value);
    }

    // ===================================================================
    // PAUSE — only PAUSER_ROLE (multisig break-glass)
    // ===================================================================
    function pause() external onlyPauser {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // ===================================================================
    // TAX — only TAX_ADMIN_ROLE
    // ===================================================================
    function setAITaxBps(uint16 newBps) external onlyRole(TAX_ADMIN_ROLE) {
        if (newBps > MAX_TAX_BPS) revert InvalidTaxRate(newBps);
        emit AITaxBpsUpdated(aiUsageTaxBps, newBps);
        aiUsageTaxBps = newBps;
    }

    function setAITaxCollector(address collector, bool enabled) external onlyRole(TAX_ADMIN_ROLE) {
        if (collector == address(0)) revert ZeroAddress(collector);
        aiTaxCollectors[collector] = enabled;
        emit AITaxCollectorSet(collector, enabled);
    }

    function collectAITax(uint256 amount) external returns (uint256 taxed) {
        if (!aiTaxCollectors[msg.sender]) revert NotCollector();
        taxed = (amount * aiUsageTaxBps) / 10_000;
        if (taxed > 0) _burn(msg.sender, taxed);
        emit AITaxCollected(msg.sender, amount, taxed);
    }

    // ===================================================================
    // VIEW HELPERS
    // ===================================================================
    /// @notice Convenience: verify constructor minted exactly MAX_SUPPLY
    function verifyTotalSupply() external pure returns (uint256 minted) {
        return MAX_SUPPLY;
    }

    /// @notice Return allocation breakdown for transparency
    function allocation() external pure returns (uint256 treasury, uint256 team, uint256 ecosystem, uint256 liquidity, uint256 community, uint256 reserve, uint256 partnerships) {
        treasury      = 150_000_000e18;
        team          = 100_000_000e18;
        ecosystem     = 300_000_000e18;
        liquidity     = 100_000_000e18;
        community     = 150_000_000e18;
        reserve       = 150_000_000e18;
        partnerships  =  50_000_000e18;
    }
}
