// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IQuantaToken {
    function collectAITax(uint256 amount) external returns (uint256);
}
