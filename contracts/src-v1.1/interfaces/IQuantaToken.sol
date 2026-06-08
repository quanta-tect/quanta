// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IQuantaToken {
    // M-DEAD-01: removed dead `from` parameter (Zcash-type code smell)
    function collectAITax(uint256 amount) external returns (uint256);
}
