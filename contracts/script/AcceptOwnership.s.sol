// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Script.sol";
import "../src/SimpleMultisig.sol";

/**
 * @title AcceptOwnership
 * @notice Use the multisig to accept ownership of all QUANTA contracts
 *
 * Usage:
 *   export DEPLOYER_KEY="0x..."
 *   forge script script/AcceptOwnership.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast
 */
contract AcceptOwnership is Script {
    // SimpleMultisig deployed in previous step
    address constant MULTISIG = 0xf103577A823593f8983D179129c8f3580De70e24;

    function run() external {
        console.log("=== Accept Ownership via Multisig ===");
        console.log("Multisig:", MULTISIG);

        SimpleMultisig msig = SimpleMultisig(payable(MULTISIG));

        // Encode acceptOwnership() calls
        bytes memory data1 = abi.encodeWithSignature("acceptOwnership()");
        bytes memory data2 = abi.encodeWithSignature("acceptOwnership()");
        bytes memory data3 = abi.encodeWithSignature("acceptOwnership()");
        bytes memory data4 = abi.encodeWithSignature("acceptOwnership()");

        vm.startBroadcast(vm.envUint("DEPLOYER_KEY"));

        msig.execute(0x312137fb6943F8f89F5eF0f221aA102035a16625, 0, data1);
        console.log("OK: QuantaToken ownership accepted");

        msig.execute(0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB, 0, data2);
        console.log("OK: AIAgentRegistry ownership accepted");

        msig.execute(0xF146e95b97fce1d1800F5F922AE99155711A4314, 0, data3);
        console.log("OK: AIPaymentChannel ownership accepted");

        msig.execute(0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49, 0, data4);
        console.log("OK: AIModelMarketplace ownership accepted");

        vm.stopBroadcast();

        console.log("");
        console.log("=== ALL DONE ===");
        console.log("All 4 contracts now owned by multisig:", MULTISIG);
    }
}
