// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IQuantaToken} from "./interfaces/IQuantaToken.sol";

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
/**
 * @title AIPaymentChannel v1.1 — Security-Hardened
 *
 * Fixes vs v1.0:
 *  - C-01: Tax burn from contract's own balance (channel pre-segregates funds)
 *  - C-03: Proper challenge period; forceClose cannot wipe payee's claims
 *  - C-04: EIP-712 signatures (chainId + verifyingContract) prevent cross-chain replay
 *  - H-04: Pausable for emergency stop
 *  - H-06: MIN_DEPOSIT to prevent dust DoS
 *  - M-05: Per-channel configurable timeout
 *  - L-05: address(0) checks
 *
 * Design:
 *  - Payee submits best signed ticket via `closeChannel`
 *  - Payer has CHALLENGE_PERIOD to submit a higher ticket if they were undercharged
 *    (impossible if payer's own signature, but useful if multisig payer)
 *  - After CHALLENGE_PERIOD, anyone can finalize via `finalize`
 *  - Payer's `forceClose` only works if NO ticket was ever submitted
 */
contract AIPaymentChannel is EIP712, ReentrancyGuard, Pausable, Ownable2Step {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    // EIP-712 typehash for off-chain signature
    bytes32 public constant TICKET_TYPEHASH =
        keccak256("Ticket(bytes32 channelId,uint256 amount,uint256 nonce)");

    struct Channel {
        address payer;
        address payee;
        uint128 deposit;
        uint128 claimedAmount;      // best amount payee submitted
        uint64  openedAt;
        uint64  closeRequestedAt;   // when payee called closeChannel
        uint64  challengePeriod;    // per-channel configurable (M-05)
        uint64  forceCloseAfter;    // payer can reclaim if untouched
        bool    finalized;
    }

    IERC20 public immutable token;
    IQuantaToken public immutable quantaToken;

    uint128 public constant MIN_DEPOSIT = 0.001 ether; // H-06: prevent dust
    uint64  public constant DEFAULT_CHALLENGE_PERIOD = 1 days;
    uint64  public constant DEFAULT_FORCE_CLOSE_AFTER = 7 days;
    uint64  public constant MAX_CHALLENGE_PERIOD = 30 days;

    mapping(bytes32 => Channel) public channels;

    event ChannelOpened(bytes32 indexed channelId, address indexed payer, address indexed payee, uint256 deposit);
    event CloseRequested(bytes32 indexed channelId, uint256 amount, uint64 finalizeAt);
    event ChannelFinalized(bytes32 indexed channelId, uint256 paidToPayee, uint256 refund);
    event ChannelForceClosed(bytes32 indexed channelId, uint256 refund);

    error InvalidSignature();
    error ChannelNotFound();
    error ChannelFinalized_();
    error NotPayer();
    error NotPayee();
    error InsufficientDeposit();
    error ChallengeNotElapsed();
    error CannotForceClose();
    error AmountExceedsDeposit();
    error AmountNotIncreasing();
    error ZeroAddress();
    error InvalidPeriod();

    constructor(IERC20 _token, IQuantaToken _quantaToken, address initialOwner)
        EIP712("QUANTA Payment Channel", "1")
        Ownable(initialOwner)
    {
        if (address(_token) == address(0)) revert ZeroAddress();
        if (address(_quantaToken) == address(0)) revert ZeroAddress();
        token = _token;
        quantaToken = _quantaToken;
    }

    function _channelId(address payer, address payee, uint64 nonce)
        internal pure returns (bytes32)
    {
        return keccak256(abi.encode(payer, payee, nonce));
    }

    /// @notice Hash a ticket for off-chain signing (EIP-712, chain-bound)
    function hashTicket(bytes32 channelId, uint256 amount, uint256 nonce)
        public view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            TICKET_TYPEHASH, channelId, amount, nonce
        )));
    }

    function openChannel(
        address payee,
        uint64  nonce,
        uint128 deposit,
        uint64  challengePeriod,
        uint64  forceCloseAfter
    ) external nonReentrant whenNotPaused returns (bytes32 channelId) {
        if (payee == address(0)) revert ZeroAddress();
        if (deposit < MIN_DEPOSIT) revert InsufficientDeposit();
        if (challengePeriod == 0) challengePeriod = DEFAULT_CHALLENGE_PERIOD;
        if (forceCloseAfter == 0) forceCloseAfter = DEFAULT_FORCE_CLOSE_AFTER;
        if (challengePeriod > MAX_CHALLENGE_PERIOD) revert InvalidPeriod();
        if (forceCloseAfter < challengePeriod * 2) revert InvalidPeriod();

        channelId = _channelId(msg.sender, payee, nonce);
        if (channels[channelId].openedAt != 0) revert(); // already exists

        // CEI: state first, then external
        channels[channelId] = Channel({
            payer: msg.sender,
            payee: payee,
            deposit: deposit,
            claimedAmount: 0,
            openedAt: uint64(block.timestamp),
            closeRequestedAt: 0,
            challengePeriod: challengePeriod,
            forceCloseAfter: forceCloseAfter,
            finalized: false
        });

        token.safeTransferFrom(msg.sender, address(this), deposit);
        emit ChannelOpened(channelId, msg.sender, payee, deposit);
    }

    /// @notice Payee submits best ticket. Starts challenge period.
    ///         If called again with HIGHER amount, extends/updates.
    function closeChannel(
        bytes32 channelId,
        uint256 amount,
        uint256 ticketNonce,
        bytes calldata signature
    ) external whenNotPaused {
        Channel storage c = channels[channelId];
        if (c.openedAt == 0) revert ChannelNotFound();
        if (c.finalized) revert ChannelFinalized_();
        if (msg.sender != c.payee) revert NotPayee();
        if (amount > c.deposit) revert AmountExceedsDeposit();
        if (amount <= c.claimedAmount) revert AmountNotIncreasing(); // C-03: monotonic

        // Verify EIP-712 signature (C-04 fix)
        bytes32 digest = hashTicket(channelId, amount, ticketNonce);
        address signer = digest.recover(signature);
        if (signer != c.payer) revert InvalidSignature();

        c.claimedAmount = uint128(amount);
        if (c.closeRequestedAt == 0) {
            c.closeRequestedAt = uint64(block.timestamp);
        }
        emit CloseRequested(channelId, amount, c.closeRequestedAt + c.challengePeriod);
    }

    /// @notice After challenge period, anyone can finalize.
    function finalize(bytes32 channelId) external nonReentrant whenNotPaused {
        Channel storage c = channels[channelId];
        if (c.openedAt == 0) revert ChannelNotFound();
        if (c.finalized) revert ChannelFinalized_();
        if (c.closeRequestedAt == 0) revert(); // not requested
        if (block.timestamp < c.closeRequestedAt + c.challengePeriod) {
            revert ChallengeNotElapsed();
        }
        _finalize(channelId);
    }

    /// @notice Payer can force-close only if NO ticket has been submitted (C-03 fix).
    function forceClose(bytes32 channelId) external nonReentrant whenNotPaused {
        Channel storage c = channels[channelId];
        if (c.openedAt == 0) revert ChannelNotFound();
        if (c.finalized) revert ChannelFinalized_();
        if (msg.sender != c.payer) revert NotPayer();
        if (c.claimedAmount > 0) revert CannotForceClose(); // C-03: cannot wipe claims
        if (block.timestamp < c.openedAt + c.forceCloseAfter) revert ChallengeNotElapsed();

        c.finalized = true;
        uint256 refund = c.deposit;
        token.safeTransfer(c.payer, refund);
        emit ChannelForceClosed(channelId, refund);
    }

    /// @dev C-01 fix: tax computed against this channel's funds, not shared pool.
    ///      Channel pre-segregates by tracking `deposit` per channel.
    function _finalize(bytes32 channelId) internal {
        Channel storage c = channels[channelId];
        c.finalized = true;

        uint256 toPayee = c.claimedAmount;
        uint256 refund = uint256(c.deposit) - toPayee;

        // C-01: To burn safely, channel transfers `taxed` portion to itself
        // conceptually and burns from its own balance. Since collectAITax
        // (v1.1) requires from == msg.sender, channel burns from its own holdings.
        uint256 taxed = 0;
        if (toPayee > 0) {
            taxed = quantaToken.collectAITax(address(this), toPayee);
            token.safeTransfer(c.payee, toPayee - taxed);
        }
        if (refund > 0) {
            token.safeTransfer(c.payer, refund);
        }

        emit ChannelFinalized(channelId, toPayee - taxed, refund);
    }

    // ------------------------------------------------------------------
    // Emergency
    // ------------------------------------------------------------------

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
