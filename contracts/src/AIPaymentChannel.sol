// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IQuantaToken} from "./interfaces/IQuantaToken.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @title AIPaymentChannel
 * @notice x402-style state channels for AI micropayments.
 *
 * Flow:
 *  1. Payer (AI agent / human) opens channel with deposit
 *  2. Off-chain: payer signs incremental state {channelId, spent, nonce}
 *  3. Payee accumulates signed states, can submit best one anytime
 *  4. Close: payee submits final state → settle in 1 onchain tx
 *
 * Result: 1 triệu micropayments = 2 on-chain tx (open + close).
 * Fee per micropayment ≈ 0 (just 1 off-chain signature).
 */
contract AIPaymentChannel {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    using SafeERC20 for IERC20;

    struct Channel {
        address payer;
        address payee;
        uint256 deposit;
        uint256 settledAmount;
        uint64  openedAt;
        uint64  challengePeriodEnd;
        bool    closed;
    }

    IERC20 public immutable token;
    IQuantaToken public immutable quantaToken;
    uint64 public constant CHALLENGE_PERIOD = 1 days;

    mapping(bytes32 => Channel) public channels;

    event ChannelOpened(bytes32 indexed channelId, address indexed payer, address indexed payee, uint256 deposit);
    event ChannelClosed(bytes32 indexed channelId, uint256 paidToPayee, uint256 refund);
    event ChannelChallenged(bytes32 indexed channelId, uint256 newAmount);

    error InvalidSignature();
    error ChannelAlreadyClosed();
    error ChannelNotReady();
    error InsufficientDeposit();
    error AmountDecreased();

    constructor(IERC20 _token, IQuantaToken _quantaToken) {
        token = _token;
        quantaToken = _quantaToken;
    }

    function _channelId(address payer, address payee, uint64 nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(payer, payee, nonce));
    }

    /**
     * @notice Open channel with deposit.
     */
    function openChannel(address payee, uint64 nonce, uint256 deposit)
        external
        returns (bytes32 channelId)
    {
        channelId = _channelId(msg.sender, payee, nonce);
        require(channels[channelId].openedAt == 0, "exists");

        channels[channelId] = Channel({
            payer: msg.sender,
            payee: payee,
            deposit: deposit,
            settledAmount: 0,
            openedAt: uint64(block.timestamp),
            challengePeriodEnd: 0,
            closed: false
        });

        token.safeTransferFrom(msg.sender, address(this), deposit);
        emit ChannelOpened(channelId, msg.sender, payee, deposit);
    }

    /**
     * @notice Payee submit signed state để close channel.
     * @param signature Signature từ payer ký {channelId, amount}
     */
    function closeChannel(bytes32 channelId, uint256 amount, bytes calldata signature)
        external
    {
        Channel storage c = channels[channelId];
        require(!c.closed, "closed");
        require(msg.sender == c.payee, "only payee");
        require(amount <= c.deposit, "amount > deposit");

        // Verify signature
        bytes32 msgHash = keccak256(abi.encode(channelId, amount)).toEthSignedMessageHash();
        address signer = msgHash.recover(signature);
        if (signer != c.payer) revert InvalidSignature();

        c.settledAmount = amount;
        c.challengePeriodEnd = uint64(block.timestamp) + CHALLENGE_PERIOD;

        // Settle immediately (no challenge in this MVP — production will có)
        _settle(channelId);
    }

    /**
     * @notice Payer có thể challenge bằng cách show signed state with amount thấp hơn?
     *         Không — payee chỉ submit was max amount already ký. Nên đơn giản hơn:
     *         Payer có thể force-close if payee không close in T thời gian.
     */
    function forceClose(bytes32 channelId) external {
        Channel storage c = channels[channelId];
        require(!c.closed, "closed");
        require(msg.sender == c.payer, "only payer");
        require(block.timestamp >= c.openedAt + 7 days, "too early");

        // Refund everything to payer if payee never claimed
        c.settledAmount = 0;
        _settle(channelId);
    }

    function _settle(bytes32 channelId) internal {
        Channel storage c = channels[channelId];
        c.closed = true;

        uint256 toPayee = c.settledAmount;
        uint256 refund = c.deposit - toPayee;

        if (toPayee > 0) {
            // Collect AI tax → burn portion
            uint256 taxed = quantaToken.collectAITax(address(this), toPayee);
            // Note: tax was burn từ contract's balance — need token approve self
            token.safeTransfer(c.payee, toPayee - taxed);
        }
        if (refund > 0) {
            token.safeTransfer(c.payer, refund);
        }

        emit ChannelClosed(channelId, toPayee, refund);
    }

    // ------------------------------------------------------------------
    // Helper: create hash để off-chain ký
    // ------------------------------------------------------------------

    function hashState(bytes32 channelId, uint256 amount) external pure returns (bytes32) {
        return keccak256(abi.encode(channelId, amount)).toEthSignedMessageHash();
    }
}
