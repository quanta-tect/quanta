// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../contracts/src-v1.1/QuantaToken.sol";
import "../contracts/src-v1.1/AIAgentRegistry.sol";
import "../contracts/src-v1.1/AIPaymentChannel.sol";
import "../contracts/src-v1.1/AIModelMarketplace.sol";

/**
 * @title TransferOwnershipToMultisig
 * @notice Transfers ownership of all 4 QUANTA contracts to Gnosis Safe.
 *         Uses Ownable2Step → Safe must call acceptOwnership() afterwards.
 *
 * Usage:
 *   export SAFE_ADDRESS=0xYourSafeAddress
 *   export DEPLOYER_PRIVATE_KEY=0x...
 *   forge script multisig-setup/transfer-ownership-script.s.sol \
 *     --rpc-url $BASE_RPC --broadcast
 *
 * After this: log into Safe → propose acceptOwnership() on each contract.
 */
contract TransferOwnershipToMultisig is Script {
    function run() external {
        address safe = vm.envAddress("SAFE_ADDRESS");
        address token    = vm.envAddress("QUANTA_TOKEN");
        address registry = vm.envAddress("QUANTA_REGISTRY");
        address channel  = vm.envAddress("QUANTA_CHANNEL");
        address market   = vm.envAddress("QUANTA_MARKET");

        require(safe != address(0), "SAFE_ADDRESS not set");

        vm.startBroadcast();

        // Order: most-dependent first
        console.log("Transferring AIPaymentChannel...");
        AIPaymentChannel(channel).transferOwnership(safe);

        console.log("Transferring AIModelMarketplace...");
        AIModelMarketplace(market).transferOwnership(safe);

        console.log("Transferring AIAgentRegistry...");
        AIAgentRegistry(registry).transferOwnership(safe);

        console.log("Transferring QuantaToken (last)...");
        QuantaToken(token).transferOwnership(safe);

        vm.stopBroadcast();

        console.log("");
        console.log("=================================================");
        console.log("All transferOwnership() calls submitted.");
        console.log("Safe address:", safe);
        console.log("");
        console.log("NEXT STEP (CRITICAL):");
        console.log("1. Log into Safe at https://app.safe.global");
        console.log("2. For EACH contract above, propose tx:");
        console.log("   Contract: <address>");
        console.log("   Function: acceptOwnership()");
        console.log("3. Sign with 3 of 5 hardware wallets");
        console.log("4. Execute");
        console.log("5. Verify owner() returns Safe address on each contract");
        console.log("=================================================");
    }
}
