// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src-v1.1/QuantaToken.sol";
import "../src-v1.1/AIAgentRegistry.sol";
import "../src-v1.1/AIPaymentChannel.sol";
import "../src-v1.1/AIModelMarketplace.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IQuantaToken} from "../src-v1.1/interfaces/IQuantaToken.sol";

contract DeployV11Script is Script {
    function run() external {
        address deployer = vm.addr(vm.envUint("DEPLOYER_KEY"));
        address treasury = vm.envOr("TREASURY_ADDRESS", deployer);
        address validatorPool = vm.envOr("VALIDATOR_POOL", treasury);

        console.log("Deployer:", deployer);
        console.log("Treasury:", treasury);

        vm.startBroadcast(vm.envUint("DEPLOYER_KEY"));

        QuantaToken token = new QuantaToken(deployer);
        console.log("QuantaToken:", address(token));

        AIAgentRegistry registry = new AIAgentRegistry(deployer);
        console.log("AIAgentRegistry:", address(registry));

        AIPaymentChannel channel = new AIPaymentChannel(
            IERC20(address(token)),
            IQuantaToken(address(token)),
            deployer
        );
        console.log("AIPaymentChannel:", address(channel));

        AIModelMarketplace market = new AIModelMarketplace(
            IERC20(address(token)),
            IQuantaToken(address(token)),
            treasury,
            validatorPool,
            deployer
        );
        console.log("AIModelMarketplace:", address(market));

        token.setAITaxCollector(address(channel), true);
        token.setAITaxCollector(address(market), true);

        vm.stopBroadcast();

        console.log("---");
        console.log("Treasury:", treasury);
        console.log("Total Supply:", token.totalSupply() / 1e18, "QTA");
    }
}
