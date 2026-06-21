// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Script.sol";
import "../src-v1.2/QuantaToken.sol";
import "../src-v1.2/AIAgentRegistry.sol";
import "../src-v1.2/AIPaymentChannel.sol";
import "../src-v1.2/AIModelMarketplace.sol";

/**
 * @title SetupMultisigOwnership
 * @notice Transfer ownership of all v1.2 contracts to a Gnosis Safe multisig
 *
 * Usage:
 *   export MULTISIG_ADDRESS=0xYourSafeAddress
 *   forge script script/SetupMultisigOwnership.s.sol \
 *     --rpc-url $BASE_SEPOLIA_RPC \
 *     --broadcast \
 *     --private-key $DEPLOYER_KEY
 *
 * Prerequisites:
 *   1. Deploy Gnosis Safe on Base Sepolia: https://app.safe.global
 *   2. Set MULTISIG_ADDRESS env var to the Safe address
 *
 * Post-setup (Ownable2Step):
 *   - This script calls transferOwnership(multisig) on all 4 contracts
 *   - The multisig must then call acceptOwnership() on each contract
 *   - Until accepted, the current owner retains control
 */
contract SetupMultisigOwnership is Script {
    function run() external {
        address multisig = vm.envAddress("MULTISIG_ADDRESS");
        require(multisig != address(0), "MULTISIG_ADDRESS must be set");

        // Deployed contract addresses (Base Sepolia v1.2)
        QuantaToken token = QuantaToken(0x312137fb6943F8f89F5eF0f221aA102035a16625);
        AIAgentRegistry registry = AIAgentRegistry(0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB);
        AIPaymentChannel channel = AIPaymentChannel(0xF146e95b97fce1d1800F5F922AE99155711A4314);
        AIModelMarketplace market = AIModelMarketplace(0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49);

        console.log("=== QUANTA Multisig Ownership Transfer ===");
        console.log("Multisig:", multisig);
        console.log("");

        vm.startBroadcast();

        // Step 1: Propose new owner on all 4 contracts (Ownable2Step)
        token.transferOwnership(multisig);
        console.log("OK: QuantaToken ownership proposed");

        registry.transferOwnership(multisig);
        console.log("OK: AIAgentRegistry ownership proposed");

        channel.transferOwnership(multisig);
        console.log("OK: AIPaymentChannel ownership proposed");

        market.transferOwnership(multisig);
        console.log("OK: AIModelMarketplace ownership proposed");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Open Gnosis Safe UI: https://app.safe.global");
        console.log("2. Create 4 transactions calling acceptOwnership():");
        console.log("   - QuantaToken:       0x312137fb6943F8f89F5eF0f221aA102035a16625");
        console.log("   - AIAgentRegistry:   0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB");
        console.log("   - AIPaymentChannel:  0xF146e95b97fce1d1800F5F922AE99155711A4314");
        console.log("   - AIModelMarketplace: 0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49");
        console.log("3. Get required confirmations from signers");
        console.log("4. Execute transactions");
        console.log("5. Verify: cast call <addr> 'owner()(address)' --rpc-url $BASE_SEPOLIA_RPC");
    }
}
