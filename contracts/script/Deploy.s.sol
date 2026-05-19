// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/QuantaToken.sol";
import "../src/AIAgentRegistry.sol";
import "../src/AIPaymentChannel.sol";
import "../src/AIModelMarketplace.sol";

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

        vm.startBroadcast();

        // 1. Token
        QuantaToken token = new QuantaToken(treasury);
        console.log("QuantaToken:", address(token));

        // 2. Agent Registry
        AIAgentRegistry registry = new AIAgentRegistry();
        console.log("AIAgentRegistry:", address(registry));

        // 3. Payment Channel
        AIPaymentChannel channel = new AIPaymentChannel(
            IERC20(address(token)),
            IQuantaToken(address(token))
        );
        console.log("AIPaymentChannel:", address(channel));

        // 4. Marketplace
        AIModelMarketplace market = new AIModelMarketplace(
            IERC20(address(token)),
            IQuantaToken(address(token)),
            treasury,
            validatorPool
        );
        console.log("AIModelMarketplace:", address(market));

        // 5. Wire up tax collectors
        token.setAITaxCollector(address(channel), true);
        token.setAITaxCollector(address(market), true);

        vm.stopBroadcast();

        console.log("---");
        console.log("Treasury:", treasury);
        console.log("Validator Pool:", validatorPool);
        console.log("Total Supply:", token.totalSupply() / 1e18, "QTA");
    }
}
