// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Script.sol";
import "../src/SimpleMultisig.sol";

/**
 * @title AcceptOwnershipNew
 * @notice Accept ownership of all QUANTA contracts via new multisig
 */
contract AcceptOwnershipNew is Script {
    address constant NEW_MULTISIG = 0x9261020D451a631AcB26e5BcA26b7BD3c95b726D;

    function run() external {
        SimpleMultisig msig = SimpleMultisig(payable(NEW_MULTISIG));

        bytes memory data = abi.encodeWithSignature("acceptOwnership()");

        vm.startBroadcast(vm.envUint("NEW_KEY"));

        msig.execute(0x312137fb6943F8f89F5eF0f221aA102035a16625, 0, data);
        console.log("OK: QuantaToken ownership accepted");

        msig.execute(0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB, 0, data);
        console.log("OK: AIAgentRegistry ownership accepted");

        msig.execute(0xF146e95b97fce1d1800F5F922AE99155711A4314, 0, data);
        console.log("OK: AIPaymentChannel ownership accepted");

        msig.execute(0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49, 0, data);
        console.log("OK: AIModelMarketplace ownership accepted");

        vm.stopBroadcast();

        console.log("");
        console.log("=== ALL DONE ===");
        console.log("All contracts owned by new multisig:", NEW_MULTISIG);
        console.log("Signer (KEEP SAFE):", vm.addr(vm.envUint("NEW_KEY")));
    }
}
