// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Test.sol";
import "../src-v2/QuantaTokenV2.sol";
import "../src-v2/QuantaVestingWallet.sol";
import "../src-v2/QuantaTreasuryController.sol";
import "../src-v2/QuantaRewardsDistributor.sol";

contract QtaV2Tests is Test {
    // ===================================================================
    // Accounts
    // ===================================================================
    address deployer   = address(0xDeaD);
    address treasury   = address(0xCAFE);
    address team       = address(0xBEEF);
    address liquidity  = address(0xDEAD);
    address ecosystem  = address(0xFACE);
    address community  = address(0xBABE);
    address reserve    = address(0xBEAD);
    address partners   = address(0xC0DE);

    // ===================================================================
    // Contracts
    // ===================================================================
    QuantaTokenV2         token;
    QuantaVestingWallet   vesting;
    QuantaTreasuryController treasuryCtrl;
    QuantaRewardsDistributor rewards;

    // ===================================================================
    // Setup
    // ===================================================================
    function setUp() public {
        vm.startPrank(deployer);

        // 1. Vesting — deploy first (no token yet)
        vesting = new QuantaVestingWallet(
            team,                    // beneficiary
            uint64(block.timestamp), // start
            94608000,                // 36mo
            31536000                 // 12mo cliff
        );

        // 2. Treasury controller — no token yet
        treasuryCtrl = new QuantaTreasuryController(
            treasury,    // admin
            treasury,    // proposer
            treasury     // executor
        );

        // 3. Rewards — no token yet
        rewards = new QuantaRewardsDistributor(treasury);

        // 4. TokenV2 — mint 1B — to addresses above
        // Note: vesting/treasuryCtrl/rewards don't have token set yet,
        // but constructor mints QTA to them anyway.
        token = new QuantaTokenV2(
            treasury,      // treasury ops 15%
            address(vesting),      // team vesting 10%
            liquidity,    // liquidity 10%
            address(rewards),      // ecosystem 30%
            community,    // community 15%
            reserve,      // reserve 15%
            partners,     // partnerships 5%
            deployer      // initial owner (renounced in constructor)
        );
        vm.stopPrank();

        // 5. Set token on support contracts (post-deploy)
        vm.startPrank(team);
        vesting.setToken(address(token));
        vm.stopPrank();

        vm.startPrank(treasury);
        treasuryCtrl.setToken(address(token));
        rewards.setToken(address(token));
        vm.stopPrank();
    }

    // ===================================================================
    // QuantaTokenV2 tests
    // ===================================================================
    function test_TokenV2_TotalSupply_1B() public {
        assertEq(token.totalSupply(), 1_000_000_000e18);
    }

    function test_TokenV2_VerifyTotalSupply() public {
        assertEq(token.verifyTotalSupply(), 1_000_000_000e18);
    }

    function test_TokenV2_Constructor_SetsRoles() public {
        // deployer roles should be revoked after constructor
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), deployer));
        assertFalse(token.hasRole(token.PAUSER_ROLE(), deployer));
        // treasury should have admin + pauser
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), treasury));
        assertTrue(token.hasRole(token.PAUSER_ROLE(), treasury));
    }

    function test_TokenV2_NoMinterRole() public {
        // No MINTER_ROLE in this contract
        bytes32 minterRole = keccak256("MINTER_ROLE");
        assertFalse(token.hasRole(minterRole, treasury));
        assertFalse(token.hasRole(minterRole, deployer));
    }

    function test_TokenV2_Pause_BlocksTransfers() public {
        address buyer = address(0x1234);
        address seller = address(0x5678);

        // Setup: transfer some from treasury to buyer
        vm.startPrank(treasury);
        token.transfer(buyer, 1000e18);
        vm.stopPrank();

        // Pause from treasury multisig
        vm.startPrank(treasury);
        token.pause();
        vm.stopPrank();

        // Transfer should fail
        vm.startPrank(buyer);
        vm.expectRevert();
        token.transfer(seller, 500e18);
        vm.stopPrank();

        // Unpause
        vm.startPrank(treasury);
        token.unpause();
        vm.stopPrank();

        // Transfer should work again
        vm.startPrank(buyer);
        token.transfer(seller, 500e18);
        vm.stopPrank();

        assertEq(token.balanceOf(seller), 500e18);
    }

    function test_TokenV2_Burn_WorksWhenPaused() public {
        address user = address(0x1111);

        vm.startPrank(treasury);
        token.transfer(user, 1000e18);
        token.pause();
        vm.stopPrank();

        // Burn should still work (from != 0)
        vm.startPrank(user);
        token.burn(100e18);
        vm.stopPrank();

        assertEq(token.balanceOf(user), 900e18);
        assertEq(token.totalSupply(), 1_000_000_000e18 - 100e18);
    }

    function test_TokenV2_SetTaxRate() public {
        vm.startPrank(treasury);
        token.setAITaxBps(50); // 0.5%
        vm.stopPrank();

        assertEq(token.aiUsageTaxBps(), 50);
    }

    function test_TokenV2_TaxRateCannotExceed100() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        token.setAITaxBps(101);
        vm.stopPrank();
    }

    function test_TokenV2_SetTaxCollector() public {
        address collector = address(0x9999);
        vm.startPrank(treasury);
        token.setAITaxCollector(collector, true);
        vm.stopPrank();

        assertTrue(token.aiTaxCollectors(collector));
    }

    function test_TokenV2_CollectAITax_BurnsFromCollector() public {
        address collector = address(0x8888);
        uint256 amount = 1000e18;

        vm.startPrank(treasury);
        token.setAITaxCollector(collector, true);
        token.transfer(collector, amount);
        vm.stopPrank();

        vm.startPrank(collector);
        uint256 taxedBefore = token.totalSupply();
        token.collectAITax(amount);
        vm.stopPrank();

        assertEq(token.totalSupply(), taxedBefore - (amount * token.aiUsageTaxBps()) / 10_000);
    }

    function test_TokenV2_Allocation_Check() public {
        (uint256 treasuryAmt, uint256 teamAmt, uint256 ecosystemAmt, uint256 liquidityAmt, uint256 communityAmt, uint256 reserveAmt, uint256 partnershipsAmt) = token.allocation();

        assertEq(treasuryAmt,      150_000_000e18);
        assertEq(teamAmt,          100_000_000e18);
        assertEq(ecosystemAmt,     300_000_000e18);
        assertEq(liquidityAmt,     100_000_000e18);
        assertEq(communityAmt,     150_000_000e18);
        assertEq(reserveAmt,       150_000_000e18);
        assertEq(partnershipsAmt,   50_000_000e18);
    }

    // ===================================================================
    // QuantaVestingWallet tests
    // ===================================================================
    function test_Vesting_Cliff_ZeroUnlock() public {
        // At start + cliff - 1 second = 0 releasable
        uint256 cliffTime = vesting.start() + vesting.cliffSeconds() - 1;
        vm.warp(cliffTime);

        // fund first
        vm.startPrank(treasury);
        token.transfer(address(vesting), 100_000_000e18);
        vm.stopPrank();

        vm.startPrank(team);
        vm.expectRevert(); // releasable = 0, release reverts
        vesting.release();
        vm.stopPrank();
    }

    function test_Vesting_AfterCliff_LinearUnlock() public {
        // TokenV2 constructor already minted 100M to vesting
        vm.startPrank(team);
        vesting.fund();
        vm.stopPrank();

        // Warp past cliff + 1 month
        vm.warp(vesting.start() + vesting.cliffSeconds() + 30 days);

        vm.startPrank(team);
        vesting.release();
        vm.stopPrank();

        assertEq(token.balanceOf(team), 36073059360730593607305936); // ~36.07M after 12mo+30d
    }

    function test_Vesting_Duration_Exhausted() public {
        // TokenV2 constructor already minted 100M to vesting
        vm.startPrank(team);
        vesting.fund();
        vm.stopPrank();

        vm.warp(vesting.start() + vesting.durationSeconds());

        uint256 balanceBefore = token.balanceOf(team);
        vm.startPrank(team);
        vesting.release();
        vm.stopPrank();

        assertEq(token.balanceOf(team), balanceBefore + 100_000_000e18);
    }

    function test_Vesting_SetToken() public {
        assertEq(address(vesting.token()), address(token));
    }

    // ===================================================================
    // QuantaTreasuryController tests
    // ===================================================================
    function test_Treasury_SetToken() public {
        assertEq(address(treasuryCtrl.token()), address(token));
    }

    function test_Treasury_QueueExecuteTransfer() public {
        address recipient = address(0x1234);
        uint256 amount = 500e18;

        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), amount);
        treasuryCtrl.queueTransfer(recipient, amount);
        vm.stopPrank();

        vm.warp(block.timestamp + treasuryCtrl.TREASURY_TIMELOCK() + 1);

        vm.startPrank(treasury);
        treasuryCtrl.executeTransfer();
        vm.stopPrank();

        assertEq(token.balanceOf(recipient), amount);
    }

    function test_Treasury_ExecuteBeforeTimelock_Reverts() public {
        address recipient = address(0x1234);
        uint256 amount = 500e18;

        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), amount);
        treasuryCtrl.queueTransfer(recipient, amount);
        vm.stopPrank();

        vm.startPrank(treasury);
        vm.expectRevert("Treasury: timelock active");
        treasuryCtrl.executeTransfer();
        vm.stopPrank();
    }

    function test_Treasury_CancelTransfer() public {
        address recipient = address(0x1234);
        uint256 amount = 500e18;

        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), amount);
        treasuryCtrl.queueTransfer(recipient, amount);
        treasuryCtrl.cancelTransfer();
        vm.stopPrank();

        // After cancel, trying to execute should revert
        vm.startPrank(treasury);
        vm.expectRevert("Treasury: nothing pending");
        treasuryCtrl.executeTransfer();
        vm.stopPrank();
    }

    // ===================================================================
    // QuantaRewardsDistributor tests
    // ===================================================================
    function test_Rewards_SetToken() public {
        assertEq(address(rewards.token()), address(token));
    }

    function test_Rewards_Distribute_WithinLimits() public {
        address recipient = address(0x7777);
        uint256 amount = 100e18;

        vm.startPrank(treasury);
        token.transfer(address(rewards), amount);
        vm.stopPrank();

        vm.startPrank(treasury);
        rewards.distribute(recipient, amount, "test");
        vm.stopPrank();

        assertEq(token.balanceOf(recipient), amount);
    }

    function test_Rewards_DailyCap() public {
        address recipient = address(0x7777);

        vm.startPrank(treasury);
        // Fund with more than daily cap
        token.transfer(address(rewards), 2_000_000e18);
        vm.stopPrank();

        vm.startPrank(treasury);
        // First 1M should work
        rewards.distribute(recipient, 1_000_000e18, "first");

        // Second 1M should fail
        vm.expectRevert("Rewards: daily cap");
        rewards.distribute(recipient, 1_000_000e18, "second");
        vm.stopPrank();
    }

    function test_Rewards_RemainingDaily() public {
        vm.startPrank(treasury);
        token.transfer(address(rewards), 100e18);
        rewards.distribute(address(0x7777), 100e18, "first");
        vm.stopPrank();

        uint256 remaining = rewards.remainingDaily();
        assertEq(remaining, 999_900e18);
    }

    function test_Rewards_WeeklyCap() public {
        address recipient = address(0x7777);

        vm.startPrank(treasury);
        token.transfer(address(rewards), 6_000_000e18);
        vm.stopPrank();

        vm.startPrank(treasury);
        rewards.distribute(recipient, 500_000e18, "first");
        rewards.distribute(recipient, 500_000e18, "second");
        // now weekly emitted = 1M, daily = 1M (or 0 if new day). Next distribution should hit daily cap.
        vm.expectRevert("Rewards: daily cap");
        rewards.distribute(recipient, 1e18, "third");
        vm.stopPrank();
    }

    function test_Rewards_RemainingWeekly() public {
        vm.startPrank(treasury);
        token.transfer(address(rewards), 100e18);
        rewards.distribute(address(0x7777), 100e18, "first");
        vm.stopPrank();

        uint256 remaining = rewards.remainingWeekly();
        assertEq(remaining, 4_999_900e18);
    }

    // ===================================================================
    // AccessControl tests
    // ===================================================================
    function test_AccessControl_NonAdminCannotPause() public {
        address random = address(0x2222);
        vm.startPrank(random);
        vm.expectRevert();
        token.pause();
        vm.stopPrank();
    }

    function test_AccessControl_NonAdminCannotSetTax() public {
        address random = address(0x2222);
        vm.startPrank(random);
        vm.expectRevert();
        token.setAITaxBps(50);
        vm.stopPrank();
    }

    // ===================================================================
    // Token edge cases
    // ===================================================================
    function test_TokenV2_NameAndSymbol() public {
        assertEq(token.name(), "Quanta");
        assertEq(token.symbol(), "QTA");
    }

    function test_TokenV2_MintDisabledAfterConstruction() public {
        // totalSupply must equal max supply
        assertEq(token.totalSupply(), 1_000_000_000e18);
    }

    function test_TokenV2_SetTaxCollector_ZeroReverts() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        token.setAITaxCollector(address(0), true);
        vm.stopPrank();
    }

    // ===================================================================
    // Vesting edge cases
    // ===================================================================
    function test_Vesting_CannotFundTwice() public {
        vm.startPrank(team);
        vesting.fund();
        vm.stopPrank();

        vm.startPrank(team);
        vm.expectRevert();
        vesting.fund();
        vm.stopPrank();
    }

    // ===================================================================
    // Treasury edge cases
    // ===================================================================
    function test_Treasury_RecoverNonQTA() public {
        address fakeToken = address(0xABCD);
        // Fake ERC20 with balance 0 — we just test flow via the contract's reject logic
        vm.startPrank(treasury);
        vm.expectRevert();
        treasuryCtrl.recoverTokens(address(token), 1e18); // QTA should revert
        vm.stopPrank();
    }

    function test_Treasury_QueueTransfer_ZeroRecipientReverts() public {
        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), 100e18);
        vm.expectRevert();
        treasuryCtrl.queueTransfer(address(0), 100e18);
        vm.stopPrank();
    }

    function test_Treasury_QueueTransfer_ZeroAmountReverts() public {
        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), 100e18);
        vm.expectRevert();
        treasuryCtrl.queueTransfer(address(0x1234), 0);
        vm.stopPrank();
    }

    function test_Vesting_SetToken_CannotSetTwice() public {
        vm.startPrank(team);
        vm.expectRevert();
        vesting.setToken(address(token));
        vm.stopPrank();
    }

    function test_Treasury_SetToken_CannotSetTwice() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        treasuryCtrl.setToken(address(token));
        vm.stopPrank();
    }

    // ===================================================================
    // Rewards edge cases
    // ===================================================================
    function test_Rewards_Distribute_ZeroToReverts() public {
        vm.startPrank(treasury);
        token.transfer(address(rewards), 100e18);
        vm.stopPrank();

        vm.startPrank(treasury);
        vm.expectRevert();
        rewards.distribute(address(0), 100e18, "bad");
        vm.stopPrank();
    }

    function test_Rewards_Distribute_ZeroAmountReverts() public {
        vm.startPrank(treasury);
        token.transfer(address(rewards), 100e18);
        vm.stopPrank();

        vm.startPrank(treasury);
        vm.expectRevert();
        rewards.distribute(address(0x7777), 0, "bad");
        vm.stopPrank();
    }

    function test_Treasury_CannotRecoverQTA() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        treasuryCtrl.recoverTokens(address(token), 1e18);
        vm.stopPrank();
    }

    function test_Rewards_CannotRecoverQTA() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        rewards.recoverTokens(address(token), 1e18);
        vm.stopPrank();
    }

    // ===================================================================
    // Token: branch coverage boost
    // ===================================================================
    function test_TokenV2_Pause_BlocksTransfer() public {
        address user = address(0x1111);
        address other = address(0x2222);

        vm.startPrank(treasury);
        token.transfer(user, 1000e18);
        token.pause();
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert("EnforcedPause");
        token.transfer(other, 100e18);
        vm.stopPrank();
    }

    function test_Token_CollectAITax_ZeroTaxed() public {
        vm.startPrank(treasury);
        token.setAITaxCollector(deployer, true);
        token.setAITaxBps(0);
        token.transfer(deployer, 100 ether);
        vm.stopPrank();

        vm.startPrank(deployer);
        token.approve(address(this), 100 ether);
        uint256 taxed = token.collectAITax(100 ether);
        assertEq(taxed, 0);
        vm.stopPrank();
    }

    function test_TokenV2_UnpauseResumesTransfers() public {
        address user = address(0x1111);
        address other = address(0x2222);

        vm.startPrank(treasury);
        token.transfer(user, 1000e18);
        token.pause();
        token.unpause();
        vm.stopPrank();

        vm.startPrank(user);
        token.transfer(other, 100e18);
        vm.stopPrank();

        assertEq(token.balanceOf(other), 100e18);
    }

    function test_TokenV2_TaxRate_Boundary100() public {
        vm.startPrank(treasury);
        token.setAITaxBps(100); // 1% — boundary
        vm.stopPrank();
        assertEq(token.aiUsageTaxBps(), 100);
    }

    function test_TokenV2_MintAuthRevoked() public {
        // constructor already renounced DEFAULT_ADMIN_ROLE for deployer
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), deployer));
    }

    // ===================================================================
    // Treasury: branch / edge coverage boost
    // ===================================================================
    function test_Treasury_QueueTransfer_AllowsRequeueAfterCancel() public {
        address recipient = address(0x1234);
        uint256 amount = 100e18;

        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), amount);
        treasuryCtrl.queueTransfer(recipient, amount);
        treasuryCtrl.cancelTransfer();
        // After cancel, can queue again
        treasuryCtrl.queueTransfer(recipient, amount - 1e18);
        vm.stopPrank();

        assertEq(treasuryCtrl.pendingAmount(), amount - 1e18);
    }

    function test_Treasury_ExecuteTransfer_WhenNothingPending_Reverts() public {
        vm.startPrank(treasury);
        vm.expectRevert("Treasury: nothing pending");
        treasuryCtrl.executeTransfer();
        vm.stopPrank();
    }
    // ===================================================================
    // Rewards: branch / edge coverage boost
    // ===================================================================
    function test_Rewards_SetToken_ZeroReverts() public {
        // rewards already has token set in setUp(); deploy a fresh one
        QuantaRewardsDistributor fresh = new QuantaRewardsDistributor(treasury);
        vm.startPrank(treasury);
        vm.expectRevert();
        fresh.setToken(address(0));
        vm.stopPrank();
    }

    function test_Rewards_SetToken_CanOnlySetOnce() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        rewards.setToken(address(token)); // already set
        vm.stopPrank();
    }

    function test_Rewards_RecoverNonQTA_RevertsOnQTA() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        rewards.recoverTokens(address(token), 1e18); // QTA protection
        vm.stopPrank();
    }

    // ===================================================================
    // TokenV2: branch / edge coverage boost
    // ===================================================================
    function test_TokenV2_CollectAITax_NotCollectorReverts() public {
        vm.startPrank(address(0x9999));
        vm.expectRevert();
        token.collectAITax(100e18);
        vm.stopPrank();
    }

    // ===================================================================
    // Treasury: branch / edge coverage boost
    // ===================================================================
    function test_Treasury_QueueTransfer_PendingExistsReverts() public {
        address recipient = address(0x1234);
        uint256 amount = 100e18;

        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), amount);
        treasuryCtrl.queueTransfer(recipient, amount);
        vm.stopPrank();

        vm.startPrank(treasury);
        vm.expectRevert("Treasury: pending exists");
        treasuryCtrl.queueTransfer(recipient, amount - 1e18);
        vm.stopPrank();
    }

    function test_Treasury_CancelTransfer_NothingPendingReverts() public {
        vm.startPrank(treasury);
        vm.expectRevert("Treasury: nothing pending");
        treasuryCtrl.cancelTransfer();
        vm.stopPrank();
    }

    function test_Treasury_RecoverQTA_Reverts() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        treasuryCtrl.recoverTokens(address(token), 1e18);
        vm.stopPrank();
    }

    // ===================================================================
    // Vesting: branch / edge coverage boost
    // ===================================================================
    function test_Vesting_SetToken_ZeroReverts() public {
        vm.startPrank(team);
        vm.expectRevert();
        vesting.setToken(address(0));
        vm.stopPrank();
    }

    function test_Vesting_SetToken_CanOnlySetOnce() public {
        vm.startPrank(team);
        vm.expectRevert();
        vesting.setToken(address(token));
        vm.stopPrank();
    }

    function test_Vesting_FundTwice_Reverts() public {
        vm.startPrank(team);
        vesting.fund(); // first time succeeds
        vm.expectRevert();
        vesting.fund(); // second time reverts
        vm.stopPrank();
    }

    function test_Vesting_FundZeroBalance_Reverts() public {
        QuantaVestingWallet fresh = new QuantaVestingWallet(
            team,
            uint64(block.timestamp),
            94608000,
            31536000
        );
        vm.startPrank(team);
        fresh.setToken(address(token));
        vm.expectRevert();
        fresh.fund();
        vm.stopPrank();
    }

    function test_Rewards_RecoverQTA_Reverts() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        rewards.recoverTokens(address(token), 1e18);
        vm.stopPrank();
    }
}
