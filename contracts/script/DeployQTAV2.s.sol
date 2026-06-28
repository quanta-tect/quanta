// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src-v2/QuantaTokenV2.sol";
import "../src-v2/QuantaVestingWallet.sol";
import "../src-v2/QuantaTreasuryController.sol";
import "../src-v2/QuantaRewardsDistributor.sol";

/**
 * @title Deploy QTA v2 — Base mainnet
 *
 * Pre-flight (env vars):
 *   BASE_MAINNET_RPC   — Base mainnet RPC
 *   DEPLOYER_KEY       — ephemeral deployer private key
 *   TREASURY_MULTISIG  — Gnosis Safe 3/5 address
 *   TEAM_MULTISIG      — Team Safe address (vesting beneficiary)
 *
 * Usage:
 *   forge script script/DeployQTAV2.s.sol \
 *     --rpc-url $BASE_MAINNET_RPC \
 *     --private-key $DEPLOYER_KEY \
 *     --broadcast --verify
 *
 * Post-deploy:
 *   1. Verify all contracts on Basescan
 *   2. Check totalSupply == 1e27 (1B QTA)
 *   3. Confirm owner() == TREASURY_MULTISIG
 *   4. Verify 0 MINTER_ROLE holders
 *   5. Transfer vesting allocation to QuantaVestingWallet.fund()
 *   6. Publish DEPLOYMENTS.md + tag v2.0.0-mainnet
 */
contract DeployQTAV2 is Script {
    function run() external {
        address treasuryMultisig = vm.envAddress("TREASURY_MULTISIG");
        address teamMultisig     = vm.envAddress("TEAM_MULTISIG");

        uint64 deployTimestamp = uint64(block.timestamp);

        vm.startBroadcast();

        // =========================================================
        // 1. QuantaVestingWallet — team 10% — 36mo — 12mo cliff
        // =========================================================
        QuantaVestingWallet vesting = new QuantaVestingWallet(
            teamMultisig,           // beneficiary
            deployTimestamp,        // start
            94608000,               // 36 months in seconds
            31536000                 // 12 months cliff in seconds
        );
        console.log("QuantaVestingWallet:", address(vesting));

        // =========================================================
        // 2. QuantaTreasuryController — treasury ops
        // =========================================================
        QuantaTreasuryController treasuryCtrl = new QuantaTreasuryController(
            treasuryMultisig,   // admin
            treasuryMultisig,   // proposer
            treasuryMultisig    // executor
        );
        console.log("QuantaTreasuryController:", address(treasuryCtrl));

        // =========================================================
        // 3. QuantaRewardsDistributor — ecosystem rewards
        // =========================================================
        QuantaRewardsDistributor rewards = new QuantaRewardsDistributor(
            treasuryMultisig    // admin + distributor role
        );
        console.log("QuantaRewardsDistributor:", address(rewards));

        // =========================================================
        // 4. QuantaTokenV2 — mint 1B QTA — ONCE — mint disabled
        // =========================================================
        // NOTE: tokenomics allocation per playbook:
        //   15% Treasury ops, 10% Team vesting, 30% Ecosystem,
        //   10% Liquidity, 15% Community, 15% Reserve, 5% Partnerships
        QuantaTokenV2 token = new QuantaTokenV2(
            treasuryMultisig,          // treasury ops mint recipient
            address(vesting),          // team vesting
            address(0x000000000000000000000000000000000000dEaD), // liquidity lock (placeholder)
            address(rewards),          // ecosystem rewards
            address(0x000000000000000000000000000000000000dEaD), // community (placeholder)
            address(0x000000000000000000000000000000000000dEaD), // reserve (placeholder)
            address(0x000000000000000000000000000000000000dEaD), // partnerships (placeholder)
            treasuryMultisig           // initial owner (renounced after role grant)
        );
        console.log("QuantaTokenV2:", address(token));

        // =========================================================
        // 5. Post-deploy: set token address on support contracts
        // =========================================================
        vesting.setToken(address(token));
        treasuryCtrl.setToken(address(token));
        rewards.setToken(address(token));

        // =========================================================
        // 6. Verify mint - check total supply
        // =========================================================
        uint256 supply = token.totalSupply();
        console.log("Total Supply:", supply);
        require(supply == 1_000_000_000e18, "Deploy: total supply mismatch");

        // =========================================================
        // 7. Set initial tax collectors
        // =========================================================
        // (to be done after marketplace/payment contracts are deployed)
        // token.setAITaxCollector(..., true);

        vm.stopBroadcast();

        // =========================================================
        // 8. Output summary
        // =========================================================
        console.log("\n=== QTA v2 Mainnet Deploy Complete ===");
        console.log("Network chainId:", block.chainid);
        console.log("Deploy timestamp:", deployTimestamp);
        console.log("Treasury Multisig:",  treasuryMultisig);
        console.log("Team Multisig:",      teamMultisig);
        console.log("\nNext steps:");
        console.log("1. Verify contracts on Basescan");
        console.log("2. Transfer QTA to vesting/treasury/rewards from treasury multisig");
        console.log("3. Renounce DEFAULT_ADMIN of QuantaTokenV2 (already done in constructor)");
        console.log("4. Setup pauser role to emergency multisig");
        console.log("5. Publish addresses to DEPLOYMENTS.md");
    }
}
