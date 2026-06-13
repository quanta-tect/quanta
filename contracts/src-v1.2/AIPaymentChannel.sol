// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface IQuantaToken is IERC20 {
    function collectAITax(uint256 amount) external returns (uint256 taxed);
}

contract AIPaymentChannel is EIP712, ReentrancyGuard, Ownable2Step, Pausable {
    using SafeERC20 for IQuantaToken;
    using ECDSA     for bytes32;

    uint256 public constant MIN_DEPOSIT       = 0.01e18;
    uint64  public constant MIN_TIMEOUT       = 1 hours;
    uint64  public constant MAX_TIMEOUT       = 30 days;
    uint64  public constant DEFAULT_TIMEOUT   = 7 days;
    uint64  public constant CHALLENGE_WINDOW  = 24 hours;

    bytes32 public constant TICKET_TYPEHASH = keccak256(
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

    IQuantaToken public immutable token;
    mapping(bytes32 => Channel) public channels;

    event ChannelOpened(bytes32 indexed channelId, address indexed payer, address indexed payee, uint256 deposit, uint64 timeout);
    event ChannelClosed(bytes32 indexed channelId, uint256 payeeAmount, uint256 payerRefund, uint256 taxBurned);
    event ForceCloseInitiated(bytes32 indexed channelId, uint64 executeAfter);
    event ForceCloseChallenged(bytes32 indexed channelId, uint256 newSettledAmount);

    constructor(address _token, address _initialOwner)
        EIP712("AIPaymentChannel", "1")
        Ownable(_initialOwner)
    {
        require(_token != address(0), "Channel: zero token");
        token = IQuantaToken(_token);
    }

    function openChannel(
        address payee,
        uint64  nonce,
        uint256 deposit,
        uint64  timeout
    ) external whenNotPaused nonReentrant returns (bytes32 channelId) {
        require(payee != address(0), "Channel: zero payee");
        require(deposit >= MIN_DEPOSIT, "Channel: deposit too small");

        if (timeout == 0) {
            timeout = DEFAULT_TIMEOUT;
        } else {
            require(timeout >= MIN_TIMEOUT && timeout <= MAX_TIMEOUT, "Channel: bad timeout");
        }

        channelId = keccak256(abi.encode(msg.sender, payee, nonce));
        require(channels[channelId].openedAt == 0, "Channel: exists");

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
        require(c.openedAt != 0, "Channel: not found");
        require(c.state == ChannelState.Open || c.state == ChannelState.Closing, "Channel: already closed");
        require(msg.sender == c.payee, "Channel: not payee");
        require(amount <= c.deposit, "Channel: amount > deposit");
        require(amount > c.settledAmount, "Channel: not higher than current");

        bytes32 structHash = keccak256(abi.encode(TICKET_TYPEHASH, channelId, amount, nonce));
        address signer = _hashTypedDataV4(structHash).recover(signature);
        require(signer == c.payer, "Channel: invalid signature");

        uint256 toPayee = amount;
        uint256 toRefund = c.deposit - amount;
        c.settledAmount = amount;
        c.state = ChannelState.Closed;

        _settle(channelId, toPayee, toRefund);
    }

    function initiateForceClose(bytes32 channelId) external whenNotPaused {
        Channel storage c = channels[channelId];
        require(c.openedAt != 0, "Channel: not found");
        require(c.state == ChannelState.Open, "Channel: not open");
        require(msg.sender == c.payer, "Channel: not payer");

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
        require(c.state == ChannelState.Closing, "Channel: not closing");
        require(msg.sender == c.payee, "Channel: not payee");
        require(amount > c.settledAmount, "Channel: not higher");
        require(amount <= c.deposit, "Channel: overflow");

        bytes32 structHash = keccak256(abi.encode(TICKET_TYPEHASH, channelId, amount, nonce));
        address signer = _hashTypedDataV4(structHash).recover(signature);
        require(signer == c.payer, "Channel: invalid signature");

        c.settledAmount = amount;
        emit ForceCloseChallenged(channelId, amount);
    }

    function executeForceClose(bytes32 channelId) external nonReentrant whenNotPaused {
        Channel storage c = channels[channelId];
        require(c.state == ChannelState.Closing, "Channel: not closing");
        require(msg.sender == c.payer, "Channel: not payer");
        require(block.timestamp >= c.closeInitiatedAt + CHALLENGE_WINDOW + c.timeout, "Channel: timeout active");

        uint256 toPayee = c.settledAmount;
        uint256 toRefund = c.deposit - c.settledAmount;
        c.state = ChannelState.Closed;

        _settle(channelId, toPayee, toRefund);
    }

    function _settle(bytes32 channelId, uint256 toPayee, uint256 toRefund) internal {
        Channel storage c = channels[channelId];

        uint256 taxed = 0;
        uint256 netPayee = toPayee;

        if (toPayee > 0) {
            taxed = token.collectAITax(toPayee);
            netPayee = toPayee - taxed;
            if (netPayee > 0) token.safeTransfer(c.payee, netPayee);
        }
        if (toRefund > 0) token.safeTransfer(c.payer, toRefund);

        emit ChannelClosed(channelId, netPayee, toRefund, taxed);
    }

    function getChannelId(address payer, address payee, uint64 nonce) external pure returns (bytes32) {
        return keccak256(abi.encode(payer, payee, nonce));
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
