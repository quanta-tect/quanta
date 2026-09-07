// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IZeusyxaToken
 * @notice Interface for ZeusyxaToken v1.3
 */
interface IZeusyxaToken is IERC20 {
    function MAX_SUPPLY() external view returns (uint256);
    function MAX_TAX_BPS() external view returns (uint16);
    function BRIDGE_TIMELOCK() external view returns (uint64);
    function bridge() external view returns (address);
    function pendingBridge() external view returns (address);
    function bridgeChangeAt() external view returns (uint64);
    function aiTaxBps() external view returns (uint16);
    function aiTaxCollectors(address) external view returns (bool);
    function setAITaxCollector(address collector, bool enabled) external;
    function setAITaxBps(uint16 newBps) external;
    function collectAITax(uint256 amount) external returns (uint256 taxed);
    function bridgeMint(address to, uint256 amount) external;
    function bridgeBurn(address from, uint256 amount) external;
    function queueBridgeChange(address _newBridge) external;
    function applyBridgeChange() external;
    function cancelBridgeChange() external;
}