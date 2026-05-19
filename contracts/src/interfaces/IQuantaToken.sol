// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IQuantaToken {
    function collectAITax(address from, uint256 amount) external returns (uint256);
}
