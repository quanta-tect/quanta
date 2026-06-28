// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title QuantaRewardsDistributor
/// @notice Rate-limited ecosystem rewards — pull / merkle claim ready
/// @dev Prevents infinite emission — cap per day/week — governable
contract QuantaRewardsDistributor is AccessControl {
    using SafeERC20 for IERC20;

    IERC20 public token;
    bool public tokenSet;

    uint256 public constant MAX_DAILY_EMISSION = 1_000_000e18; // 1M QTA/day max
    uint256 public constant MAX_WEEKLY_EMISSION = 5_000_000e18; // 5M QTA/week max

    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    uint256 public dailyEmitted;
    uint256 public weeklyEmitted;
    uint64  public lastEmissionDay;
    uint64  public lastEmissionWeek;

    event Emission(address indexed to, uint256 amount, string reason);

    /// @param _treasuryMultisig  Admin — can update limits
    constructor(address _treasuryMultisig) {
        if (_treasuryMultisig == address(0)) revert();
        _grantRole(DEFAULT_ADMIN_ROLE, _treasuryMultisig);
        _grantRole(DISTRIBUTOR_ROLE, _treasuryMultisig);
    }

    /// @notice Set QTA token address (one-time)
    function setToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenSet) revert();
        if (_token == address(0)) revert();
        token = IERC20(_token);
        tokenSet = true;
    }

    /// @notice Emit rewards to a recipient — rate-limited
    /// @dev Caller must have DISTRIBUTOR_ROLE
    function distribute(address to, uint256 amount, string calldata reason) external onlyRole(DISTRIBUTOR_ROLE) {
        if (to == address(0) || amount == 0) revert();

        _checkLimits(amount);

        token.safeTransfer(to, amount);
        emit Emission(to, amount, reason);
    }

    /// @notice Internal: enforce daily + weekly caps
    function _checkLimits(uint256 amount) internal {
        uint64 today = uint64(block.timestamp / 1 days);
        uint64 week = uint64(block.timestamp / 1 weeks);

        // Reset daily counter on new day
        if (today != lastEmissionDay) {
            dailyEmitted = 0;
            lastEmissionDay = today;
        }
        // Reset weekly counter on new week
        if (week != lastEmissionWeek) {
            weeklyEmitted = 0;
            lastEmissionWeek = week;
        }

        if (dailyEmitted + amount > MAX_DAILY_EMISSION) revert("Rewards: daily cap");
        if (weeklyEmitted + amount > MAX_WEEKLY_EMISSION) revert("Rewards: weekly cap");

        dailyEmitted += amount;
        weeklyEmitted += amount;
    }

    /// @notice View: remaining daily quota
    function remainingDaily() external view returns (uint256) {
        return MAX_DAILY_EMISSION - dailyEmitted;
    }

    /// @notice View: remaining weekly quota
    function remainingWeekly() external view returns (uint256) {
        return MAX_WEEKLY_EMISSION - weeklyEmitted;
    }

    /// @notice Emergency recover non-QTA tokens
    function recoverTokens(address tokenAddress, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(token)) revert(); // protect QTA
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }
}
