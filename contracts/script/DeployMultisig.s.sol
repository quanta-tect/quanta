// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Script.sol";
import "../src/SimpleMultisig.sol";
import "../src-v1.2/QuantaToken.sol";
import "../src-v1.2/AIAgentRegistry.sol";
import "../src-v1.2/AIPaymentChannel.sol";
import "../src-v1.2/AIModelMarketplace.sol";

/**
 * @title DeployMultisig
 * @notice Deploy SimpleMultisig on Base Sepolia + transfer all QUANTA contract ownership
 *
 * Usage:
 *   export DEPLOYER_KEY="0x..."
 *   export BASE_SEPOLIA_RPC=https://sepolia.base.org
 *   forge script script/DeployMultisig.s.sol \
 *     --rpc-url $BASE_SEPOLIA_RPC \
 *     --broadcast
 */
contract DeployMultisig is Script {
    function run() external {
        address deployer = vm.addr(vm.envUint("DEPLOYER_KEY"));

        // 1. Deploy SimpleMultisig (1-of-1: deployer only for now)
        address[] memory signers = new address[](1);
        signers[0] = deployer;

        vm.startBroadcast(vm.envUint("DEPLOYER_KEY"));

        SimpleMultisig multisig = new SimpleMultisig(signers, 1);
        console.log("SimpleMultisig deployed at:", address(multisig));

        // 2. Transfer ownership of all QUANTA contracts to multisig
        QuantaToken(0x312137fb6943F8f89F5eF0f221aA102035a16625)
            .transferOwnership(address(multisig));
        console.log("OK: QuantaToken ownership proposed");

        AIAgentRegistry(0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB)
            .transferOwnership(address(multisig));
        console.log("OK: AIAgentRegistry ownership proposed");

        AIPaymentChannel(0xF146e95b97fce1d1800F5F922AE99155711A4314)
            .transferOwnership(address(multisig));
        console.log("OK: AIPaymentChannel ownership proposed");

        AIModelMarketplace(0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49)
            .transferOwnership(address(multisig));
        console.log("OK: AIModelMarketplace ownership proposed");

        vm.stopBroadcast();

        console.log("");
        console.log("=== DONE ===");
        console.log("Multisig address:", address(multisig));
        console.log("Signers:", deployer);
        console.log("Threshold: 1-of-1");
        console.log("");
        console.log("=== NEXT: Accept ownership via multisig ===");
        console.log("You need to call acceptOwnership() on each contract FROM the multisig.");
        console.log("Since this is 1-of-1 and you own the multisig signer, run:");
        console.log("");
        console.log("export MULTISIG_PK=<private key for multisig signer>");
        console.log("");
        console.log("Then execute these calls through the multisig:");
        console.log("  QuantaToken.acceptOwnership()");
        console.log("  AIAgentRegistry.acceptOwnership()");
        console.log("  AIPaymentChannel.acceptOwnership()");
        console.log("  AIModelMarketplace.acceptOwnership()");
    }
}
