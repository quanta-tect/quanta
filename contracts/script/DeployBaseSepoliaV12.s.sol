// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src-v1.2/QuantaToken.sol";
import "../src-v1.2/AIAgentRegistry.sol";
import "../src-v1.2/AIPaymentChannel.sol";
import "../src-v1.2/AIModelMarketplace.sol";

/**
 * Deploy Quanta v1.2 to Base Sepolia with deployer as owner.
 *
 * Usage:
 *   forge script script/DeployBaseSepoliaV12.s.sol:DeployBaseSepoliaV12 \
 *     --rpc-url https://sepolia.base.org \
 *     --account deployer2060 \
 *     --broadcast -vvvv
 */
contract DeployBaseSepoliaV12 is Script {
    function run() external {
        address deployer = msg.sender;
        address tokenOwner = deployer;
        address registryOwner = deployer;
        address marketplaceTreasury = deployer;
        address marketplaceValidatorPool = deployer;

        console.log("Deployer:", deployer);
        console.log("ChainId:", block.chainid);

        vm.startBroadcast();

        // 1. QuantaToken
        QuantaToken token = new QuantaToken(tokenOwner);
        console.log("QuantaToken:", address(token));

        // 2. AIAgentRegistry
        AIAgentRegistry registry = new AIAgentRegistry(registryOwner);
        console.log("AIAgentRegistry:", address(registry));

        // 3. AIPaymentChannel
        AIPaymentChannel channel = new AIPaymentChannel(address(token), registryOwner);
        console.log("AIPaymentChannel:", address(channel));

        // 4. AIModelMarketplace
        AIModelMarketplace market = new AIModelMarketplace(
            address(token),
            marketplaceTreasury,
            marketplaceValidatorPool,
            registryOwner
        );
        console.log("AIModelMarketplace:", address(market));

        // Wire tax collectors
        token.setAITaxCollector(address(channel), true);
        token.setAITaxCollector(address(market), true);

        // Authorize payment channel and marketplace as global spenders in the registry
        registry.setAuthorizedSpender(address(channel), true);
        registry.setAuthorizedSpender(address(market), true);

        vm.stopBroadcast();
    }
}
