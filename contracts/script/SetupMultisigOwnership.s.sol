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
 *   forge script script/SetupMultisigOwnership.s.sol \
 *     --rpc-url $BASE_SEPOLIA_RPC \
 *     --broadcast \
 *     --sender $DEPLOYER_ADDRESS
 *
 * Prerequisites:
 *   1. Deploy Gnosis Safe on Base Sepolia: https://app.safe.global
 *   2. Set MULTISIG_ADDRESS to the Safe address
 *   3. Set required confirmations (e.g., 2/3)
 *
 * Post-setup:
 *   - All owner-only functions (pause, setBridge, setTaxRate, etc.) require multisig approval
 *   - Single compromised key cannot drain or freeze the protocol
 */
contract SetupMultisigOwnership is Script {
    // TODO: Replace with your Gnosis Safe address
    address constant MULTISIG = address(0x0);

    function run() external {
        require(MULTISIG != address(0), "Set MULTISIG address first");

        // Load deployed contract addresses
        QuantaToken token = QuantaToken(0x312137fb6943F8f89F5eF0f221aA102035a16625);
        AIAgentRegistry registry = AIAgentRegistry(0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB);
        AIPaymentChannel channel = AIPaymentChannel(0xF146e95b97fce1d1800F5F922AE99155711A4314);
        AIModelMarketplace market = AIModelMarketplace(0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49);

        vm.startBroadcast();

        // Transfer ownership using Ownable2Step (propose + accept)
        // Step 1: Propose new owner
        token.transferOwnership(MULTISIG);
        registry.transferOwnership(MULTISIG);
        channel.transferOwnership(MULTISIG);
        market.transferOwnership(MULTISIG);

        // Step 2: Multisig must accept ownership
        // This requires a multisig transaction calling:
        //   token.acceptOwnership()
        //   registry.acceptOwnership()
        //   channel.acceptOwnership()
        //   market.acceptOwnership()

        vm.stopBroadcast();

        console.log("Ownership proposed to multisig:", MULTISIG);
        console.log("");
        console.log("Next steps:");
        console.log("1. Gnosis Safe signers call acceptOwnership() on each contract");
        console.log("2. Verify: token.owner() should return multisig address");
        console.log("3. Test: try calling pause() from non-multisig (should fail)");
    }
}
