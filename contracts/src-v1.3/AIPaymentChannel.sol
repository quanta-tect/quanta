// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IZeusyxaToken.sol";

/**
 * @title AIPaymentChannel (v1.3)
 * @notice x402-style state channels for off-chain AI micropayments
 * @dev Rebranded from v1.2: QUANTA → ZEUSYXA, QTA → ZYX
 *      Fixed: collectAITax now burns from payer (caller) not from contract
 *      Added: proper CEI pattern in _settle
 *      Added: TICKET_TYPEHASH as immutable
 */
contract AIPaymentChannel is EIP712, ReentrancyGuard, Ownable2Step, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IZeusyxaToken;
    using ECDSA     for bytes32;

    uint256 public constant MIN_DEPOSIT       = 0.01e18;
    uint64  public constant MIN_TIMEOUT       = 1 hours;
    uint64  public constant MAX_TIMEOUT       = 30 days;
    uint64  public constant DEFAULT_TIMEOUT   = 7 days;
    uint64  public constant CHALLENGE_WINDOW  = 24 hours;

    bytes32 public immutable TICKET_TYPEHASH = keccak256(
        "PaymentTicket(bytes32 channelId,uint256 amount,uint256 nonce)"
    );

    enum ChannelState { Open, Closing, Closed }

    struct Channel {
        address  payer;
        address  payee;
        uint256  deposit;
        uint256  settledAmount;
        uint64   openedAt;
        uint64   closeInitiatedAt;
        uint64   timeout;
        ChannelState state;
    }

    IZeusyxaToken public immutable token;
    mapping(bytes32 => Channel) public channels;

    // Custom errors
    error DepositTooSmall(uint256 deposit);
    error ZeroPayee();
    error ChannelExists();
    error InvalidTimeout(uint64 timeout);
    error NotPayee();
    error InvalidSignature();
    error AmountNotHigher(uint256 amount, uint256 current);
    error NotPayer();
    error TimeoutActive();
    error ChannelNotFound(bytes32 channelId);
    error ChannelNotOpen(bytes32 channelId);
    error ChannelNotClosing(bytes32 channelId);
    error ZeroToken();

    // Events
    event ChannelOpened(bytes32 indexed channelId, address indexed payer, address indexed payee, uint256 deposit, uint64 timeout);
    event ChannelClosed(bytes32 indexed channelId, uint256 payeeAmount, uint256 payerRefund, uint256 taxBurned);
    event ForceCloseInitiated(bytes32 indexed channelId, uint64 executeAfter);
    event ForceCloseChallenged(bytes32 indexed channelId, uint256 newSettledAmount);

    constructor(address _token, address _initialOwner)
        EIP712("AIPaymentChannel", "1")
        Ownable(_initialOwner)
    {
        if (_token == address(0)) revert ZeroToken();
        token = IZeusyxaToken(_token);
    }

    function openChannel(
        address payee,
        uint64  nonce,
        uint256 deposit,
        uint64  timeout
    ) external whenNotPaused nonReentrant returns (bytes32 channelId) {
        if (payee == address(0)) revert ZeroPayee();
        if (deposit < MIN_DEPOSIT) revert DepositTooSmall(deposit);

        if (timeout == 0) {
            timeout = DEFAULT_TIMEOUT;
        } else {
            if (timeout < MIN_TIMEOUT || timeout > MAX_TIMEOUT) revert InvalidTimeout(timeout);
        }

        channelId = keccak256(abi.encode(msg.sender, payee, nonce));
        if (channels[channelId].openedAt != 0) revert ChannelExists();

        channels[channelId] = Channel({
            payer:            msg.sender,
            payee:            payee,
            deposit:          deposit,
            settledAmount:    0,
            openedAt:         uint64(block.timestamp),
            closeInitiatedAt: 0,
            timeout:          timeout,
            state:            ChannelState.Open
        });

        token.safeTransferFrom(msg.sender, address(this), deposit);
        emit ChannelOpened(channelId, msg.sender, payee, deposit, timeout);
    }

    function closeChannel(
        bytes32 channelId,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external nonReentrant whenNotPaused {
        Channel storage c = channels[channelId];
        if (c.openedAt == 0) revert ChannelNotFound(channelId);
        if (c.state != ChannelState.Open && c.state != ChannelState.Closing) revert ChannelNotOpen(channelId);
        if (msg.sender != c.payee) revert NotPayee();
        if (amount > c.deposit) revert AmountNotHigher(amount, c.deposit);
        if (amount <= c.settledAmount) revert AmountNotHigher(amount, c.settledAmount);

        bytes32 structHash = keccak256(abi.encode(TICKET_TYPEHASH, channelId, amount, nonce));
        address signer = _hashTypedDataV4(structHash).recover(signature);
        if (signer != c.payer) revert InvalidSignature();

        c.settledAmount = amount;
        c.state = ChannelState.Closed;

        _settle(channelId, amount);
    }

    function initiateForceClose(bytes32 channelId) external whenNotPaused {
        Channel storage c = channels[channelId];
        if (c.openedAt == 0) revert ChannelNotFound(channelId);
        if (c.state != ChannelState.Open) revert ChannelNotOpen(channelId);
        if (msg.sender != c.payer) revert NotPayer();

        c.state = ChannelState.Closing;
        c.closeInitiatedAt = uint64(block.timestamp);
        emit ForceCloseInitiated(channelId, uint64(block.timestamp) + CHALLENGE_WINDOW);
    }

    function challengeForceClose(
        bytes32 channelId,
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) external nonReentrant {
        Channel storage c = channels[channelId];
        if (c.state != ChannelState.Closing) revert ChannelNotClosing(channelId);
        if (msg.sender != c.payee) revert NotPayee();
        if (amount <= c.settledAmount) revert AmountNotHigher(amount, c.settledAmount);
        if (amount > c.deposit) revert AmountNotHigher(amount, c.deposit);

        bytes32 structHash = keccak256(abi.encode(TICKET_TYPEHASH, channelId, amount, nonce));
        address signer = _hashTypedDataV4(structHash).recover(signature);
        if (signer != c.payer) revert InvalidSignature();

        c.settledAmount = amount;
        emit ForceCloseChallenged(channelId, amount);
    }

    function executeForceClose(bytes32 channelId) external nonReentrant whenNotPaused {
        Channel storage c = channels[channelId];
        if (c.state != ChannelState.Closing) revert ChannelNotClosing(channelId);
        if (msg.sender != c.payer) revert NotPayer();
        if (block.timestamp < c.closeInitiatedAt + CHALLENGE_WINDOW + c.timeout) revert TimeoutActive();

        uint256 toPayee = c.settledAmount;
        c.state = ChannelState.Closed;

        _settle(channelId, toPayee);
    }

    function _settle(bytes32 channelId, uint256 amount) internal {
        Channel storage c = channels[channelId];

        uint256 taxed = 0;
        uint256 netPayee = amount;

        if (amount > 0) {
            // Collect AI tax from payer (msg.sender = payer in executeForceClose, payee in closeChannel)
            // The tax is burned from the channel contract's balance, which holds the deposit
            // v1.3 fix: collectAITax now burns from the caller (which is the channel contract)
            // so we need to call it on behalf of the contract
            taxed = token.collectAITax(amount);
            netPayee = amount - taxed;
            if (netPayee > 0) token.safeTransfer(c.payee, netPayee);
        }

        uint256 toRefund = c.deposit - amount;
        if (toRefund > 0) token.safeTransfer(c.payer, toRefund);

        emit ChannelClosed(channelId, netPayee, toRefund, taxed);
    }

    function getChannelId(address payer, address payee, uint64 nonce) external pure returns (bytes32) {
        return keccak256(abi.encode(payer, payee, nonce));
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function pause() external onlyOwner { _pause(); emit Paused(msg.sender); }
    function unpause() external onlyOwner { _unpause(); emit Unpaused(msg.sender); }
}