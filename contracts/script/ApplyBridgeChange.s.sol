// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src-v1.3/ZeusyxaToken.sol";

/**
 * Apply bridge change after 7-day timelock.
 *
 * Usage:
 *   forge script script/ApplyBridgeChange.s.sol \
 *     --rpc-url $BASE_SEPOLIA_RPC \
 *     --private-key $DEPLOYER_KEY \
 *     --broadcast
 */
contract ApplyBridgeChangeScript is Script {
    function run() external {
        address tokenAddr = vm.envAddress("ZEUSYXA_TOKEN_ADDRESS");
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        ZeusyxaToken token = ZeusyxaToken(tokenAddr);

        vm.startBroadcast(vm.envAddress("DEPLOYER_ADDRESS"));

        token.applyBridgeChange();
        console.log("Bridge change applied. New bridge:", token.bridge());

        vm.stopBroadcast();
    }
}