// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./QuantaTokenV2.sol";

/// @title QuantaTreasuryController
/// @notice Gnosis Safe-governed treasury operations with timelock
/// @dev Executes transfers after timelock — multisig only — no single key
contract QuantaTreasuryController is AccessControl {
    using SafeERC20 for IERC20;

    IERC20 public token;

    address public pendingRecipient;
    uint256 public pendingAmount;
    uint64  public pendingAt;
    uint64  public constant TREASURY_TIMELOCK = 48 hours;

    bool public tokenSet;

    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    event TransferQueued(address indexed to, uint256 amount, uint64 executeAfter);
    event TransferExecuted(address indexed to, uint256 amount);
    event TransferCancelled(address indexed to, uint256 amount);

    /// @param _treasury   Gnosis Safe 3/5 — holds QTA
    /// @param _proposer    Treasury Safe (can queue)
    /// @param _executor    Treasury Safe (can execute after timelock)
    constructor(
        address _treasury,
        address _proposer,
        address _executor
    ) {
        if (_treasury == address(0) || _proposer == address(0) || _executor == address(0)) {
            revert();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, _treasury);
        _grantRole(PROPOSER_ROLE,    _proposer);
        _grantRole(EXECUTOR_ROLE,    _executor);
    }

    /// @notice Set QTA token address (one-time)
    function setToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenSet) revert();
        if (_token == address(0)) revert();
        token = IERC20(_token);
        tokenSet = true;
    }

    /// @notice Queue a transfer — proposer only
    function queueTransfer(address to, uint256 amount) external onlyRole(PROPOSER_ROLE) {
        if (to == address(0) || amount == 0) revert();
        if (pendingRecipient != address(0)) revert("Treasury: pending exists");

        pendingRecipient = to;
        pendingAmount = amount;
        pendingAt = uint64(block.timestamp) + TREASURY_TIMELOCK;

        emit TransferQueued(to, amount, pendingAt);
    }

    /// @notice Execute queued transfer after timelock — executor only
    function executeTransfer() external onlyRole(EXECUTOR_ROLE) {
        if (pendingRecipient == address(0)) revert("Treasury: nothing pending");
        if (block.timestamp < pendingAt) revert("Treasury: timelock active");

        address to = pendingRecipient;
        uint256 amount = pendingAmount;

        pendingRecipient = address(0);
        pendingAmount = 0;
        pendingAt = 0;

        token.safeTransfer(to, amount);
        emit TransferExecuted(to, amount);
    }

    /// @notice Cancel queued transfer — proposer only
    function cancelTransfer() external onlyRole(PROPOSER_ROLE) {
        if (pendingRecipient == address(0)) revert("Treasury: nothing pending");

        address to = pendingRecipient;
        uint256 amount = pendingAmount;

        pendingRecipient = address(0);
        pendingAmount = 0;
        pendingAt = 0;

        emit TransferCancelled(to, amount);
    }

    /// @notice Emergency sweep non-QTA tokens (e.g. stray ERC20 sent by mistake)
    function recoverTokens(address tokenAddress, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(token)) revert(); // protect QTA
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }
}
