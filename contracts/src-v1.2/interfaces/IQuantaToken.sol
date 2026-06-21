// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQuantaToken is IERC20 {
    function collectAITax(uint256 amount) external returns (uint256 taxed);
}
