// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title QuantaVestingWallet
/// @notice Linear vesting with cliff — OpenZeppelin pattern adapted
/// @dev beneficiary receives vested amounts over time via release()
contract QuantaVestingWallet is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    bool public tokenSet;

    address public immutable beneficiary;
    uint64  public immutable start;
    uint64  public immutable durationSeconds;
    uint64  public immutable cliffSeconds;

    uint256 public totalAllocated;
    uint256 public released;

    event TokensReleased(uint256 amount);
    event EtherReleased(address indexed to, uint256 amount);

    /// @param _beneficiary   Team multisig — NOT personal EOA
    /// @param _start         Mainnet deploy timestamp
    /// @param _duration      36 months = 94608000 seconds
    /// @param _cliff         12 months = 31536000 seconds
    constructor(
        address _beneficiary,
        uint64  _start,
        uint64  _duration,
        uint64  _cliff
    ) Ownable(_beneficiary) {
        if (_beneficiary == address(0)) revert();
        if (_duration == 0 || _cliff >= _duration) revert();

        beneficiary = _beneficiary;
        start = _start;
        durationSeconds = _duration;
        cliffSeconds = _cliff;
    }

    /// @notice Set QTA token address (one-time, after token deploy)
    function setToken(address _token) external onlyOwner {
        if (tokenSet) revert();
        if (_token == address(0)) revert();
        token = IERC20(_token);
        tokenSet = true;
    }

    /// @notice Vesting formula: linear monthly unlock
    /// @dev released = (now - start) / duration * total — cliff-gated
    function vestedAmount(uint64 timestamp) public view returns (uint256) {
        if (timestamp < start + cliffSeconds) return 0;
        if (timestamp >= start + durationSeconds) return totalAllocated - released;
        uint256 elapsed = uint256(timestamp - start);
        return (elapsed * totalAllocated) / durationSeconds;
    }

    /// @notice Release vested tokens to beneficiary
    function release() external onlyOwner {
        uint256 amount = vestedAmount(uint64(block.timestamp)) - released;
        if (amount == 0) revert();
        released += amount;
        token.safeTransfer(beneficiary, amount);
        emit TokensReleased(amount);
    }

    /// @notice Fund the vesting wallet — call once after deploy
    /// @dev Records totalAllocated based on actual QTA balance in this contract.
    ///      Can only be called once before any release to prevent tampering.
    function fund() external onlyOwner {
        if (released > 0 || totalAllocated > 0) revert(); // can only fund once
        totalAllocated = token.balanceOf(address(this));
        if (totalAllocated == 0) revert(); // nothing to vest
    }

    // ===================================================================
    // EMERGENCY — owner can recover non-QTA tokens (e.g. stray ERC20)
    // ===================================================================
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(token)) revert(); // protect QTA
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }
}
