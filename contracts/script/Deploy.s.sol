// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src-v1.3/ZeusyxaToken.sol";
import "../src-v1.3/AIAgentRegistry.sol";
import "../src-v1.3/AIPaymentChannel.sol";
import "../src-v1.3/AIModelMarketplace.sol";

/**
 * Deploy script for Base Sepolia / Base mainnet.
 *
 * Usage:
 *   forge script script/Deploy.s.sol \
 *     --rpc-url $BASE_SEPOLIA_RPC \
 *     --private-key $DEPLOYER_KEY \
 *     --broadcast --verify
 */
contract DeployScript is Script {
    function run() external {
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        address validatorPool = vm.envOr("VALIDATOR_POOL", treasury);
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        vm.startBroadcast();

        // 1. Token
        ZeusyxaToken token = new ZeusyxaToken(deployer);
        console.log("ZeusyxaToken:", address(token));

        // 2. Agent Registry
        AIAgentRegistry registry = new AIAgentRegistry(deployer);
        console.log("AIAgentRegistry:", address(registry));

        // 3. Payment Channel
        AIPaymentChannel channel = new AIPaymentChannel(
            address(token),
            deployer
        );
        console.log("AIPaymentChannel:", address(channel));

        // 4. Marketplace
        AIModelMarketplace market = new AIModelMarketplace(
            address(token),
            treasury,
            validatorPool,
            deployer
        );
        console.log("AIModelMarketplace:", address(market));

        // 5. Wire up tax collectors
        token.setAITaxCollector(address(channel), true);
        token.setAITaxCollector(address(market), true);

        // 6. Queue bridge change to deployer (so deployer can mint initial supply)
        token.queueBridgeChange(deployer);

        vm.stopBroadcast();

        console.log("---");
        console.log("Treasury:", treasury);
        console.log("Validator Pool:", validatorPool);
        console.log("Total Supply:", token.totalSupply() / 1e18, "ZYX");
    }
}