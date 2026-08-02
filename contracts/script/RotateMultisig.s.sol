// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Script.sol";
import "../src/SimpleMultisig.sol";
import "../src-v1.2/QuantaToken.sol";
import "../src-v1.2/AIAgentRegistry.sol";
import "../src-v1.2/AIPaymentChannel.sol";
import "../src-v1.2/AIModelMarketplace.sol";

/**
 * @title RotateMultisig
 * @notice Deploy new multisig + transfer ownership from old to new
 */
contract RotateMultisig is Script {
    // Old multisig (compromised key)
    address constant OLD_MULTISIG = 0xf103577A823593f8983D179129c8f3580De70e24;

    function run() external {
        address newSigner = vm.addr(vm.envUint("NEW_KEY"));
        console.log("New signer:", newSigner);

        // 1. Deploy new SimpleMultisig
        address[] memory signers = new address[](1);
        signers[0] = newSigner;

        vm.startBroadcast(vm.envUint("OLD_KEY"));

        SimpleMultisig newMsig = new SimpleMultisig(signers, 1);
        console.log("New multisig deployed at:", address(newMsig));

        // 2. Transfer ownership via old multisig (requires OLD_KEY)
        bytes memory data;

        data = abi.encodeWithSignature("transferOwnership(address)", address(newMsig));
        OLD_MULTISIG.call(abi.encodeWithSignature("execute(address,uint256,bytes)",
            0x312137fb6943F8f89F5eF0f221aA102035a16625, 0, data));
        console.log("OK: QuantaToken ownership proposed to new multisig");

        data = abi.encodeWithSignature("transferOwnership(address)", address(newMsig));
        OLD_MULTISIG.call(abi.encodeWithSignature("execute(address,uint256,bytes)",
            0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB, 0, data));
        console.log("OK: AIAgentRegistry ownership proposed to new multisig");

        data = abi.encodeWithSignature("transferOwnership(address)", address(newMsig));
        OLD_MULTISIG.call(abi.encodeWithSignature("execute(address,uint256,bytes)",
            0xF146e95b97fce1d1800F5F922AE99155711A4314, 0, data));
        console.log("OK: AIPaymentChannel ownership proposed to new multisig");

        data = abi.encodeWithSignature("transferOwnership(address)", address(newMsig));
        OLD_MULTISIG.call(abi.encodeWithSignature("execute(address,uint256,bytes)",
            0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49, 0, data));
        console.log("OK: AIModelMarketplace ownership proposed to new multisig");

        vm.stopBroadcast();

        console.log("");
        console.log("=== DONE (Step 1/2) ===");
        console.log("New multisig:", address(newMsig));
        console.log("Signer:", newSigner);
        console.log("");
        console.log("=== NEXT: Accept ownership via new multisig ===");
    }
}
