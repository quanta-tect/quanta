// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAIPaymentChannel {
    function MIN_DEPOSIT() external view returns (uint256);
    function MIN_TIMEOUT() external view returns (uint64);
    function MAX_TIMEOUT() external view returns (uint64);
    function DEFAULT_TIMEOUT() external view returns (uint64);
    function CHALLENGE_WINDOW() external view returns (uint64);
    function TICKET_TYPEHASH() external view returns (bytes32);

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

    function token() external view returns (address);
    function channels(bytes32) external view returns (Channel memory);
    function openChannel(address payee, uint64 nonce, uint256 deposit, uint64 timeout) external returns (bytes32);
    function closeChannel(bytes32 channelId, uint256 amount, uint256 nonce, bytes calldata signature) external;
    function initiateForceClose(bytes32 channelId) external;
    function challengeForceClose(bytes32 channelId, uint256 amount, uint256 nonce, bytes calldata signature) external;
    function executeForceClose(bytes32 channelId) external;
    function getChannelId(address payer, address payee, uint64 nonce) external pure returns (bytes32);
    function domainSeparator() external view returns (bytes32);
    function pause() external;
    function unpause() external;
}