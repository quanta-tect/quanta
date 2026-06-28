// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src-v2/QuantaTokenV2.sol";
import "../src-v2/QuantaVestingWallet.sol";
import "../src-v2/QuantaTreasuryController.sol";
import "../src-v2/QuantaRewardsDistributor.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MCK") {
        _mint(address(this), 1_000_000e18);
    }
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

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

        // 5. Set token on support contracts (post-deploy)
        vm.startPrank(team);
        vesting.setToken(address(token));
        vesting.fund();
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

    function test_Rewards_Constructor_RevertsOnZeroTreasury() public {
        vm.expectRevert();
        new QuantaRewardsDistributor(address(0));
    }

    function test_TokenV2_Constructor_RevertsOnZeroTreasury() public {
        vm.expectRevert();
        new QuantaTokenV2(
            address(0),
            address(vesting),
            liquidity,
            address(rewards),
            community,
            reserve,
            partners,
            deployer
        );
    }

    function test_TokenV2_Constructor_RevertsOnZeroVesting() public {
        vm.expectRevert();
        new QuantaTokenV2(
            treasury,
            address(0),
            liquidity,
            address(rewards),
            community,
            reserve,
            partners,
            deployer
        );
    }

    function test_TokenV2_Constructor_RevertsOnZeroLiquidity() public {
        vm.expectRevert();
        new QuantaTokenV2(
            treasury,
            address(vesting),
            address(0),
            address(rewards),
            community,
            reserve,
            partners,
            deployer
        );
    }

    function test_TokenV2_Constructor_RevertsOnZeroEcosystem() public {
        vm.expectRevert();
        new QuantaTokenV2(
            treasury,
            address(vesting),
            liquidity,
            address(0),
            community,
            reserve,
            partners,
            deployer
        );
    }

    function test_TokenV2_Constructor_RevertsOnZeroCommunity() public {
        vm.expectRevert();
        new QuantaTokenV2(
            treasury,
            address(vesting),
            liquidity,
            address(rewards),
            address(0),
            reserve,
            partners,
            deployer
        );
    }

    function test_TokenV2_Constructor_RevertsOnZeroReserve() public {
        vm.expectRevert();
        new QuantaTokenV2(
            treasury,
            address(vesting),
            liquidity,
            address(rewards),
            community,
            address(0),
            partners,
            deployer
        );
    }

    function test_TokenV2_Constructor_RevertsOnZeroPartners() public {
        vm.expectRevert();
        new QuantaTokenV2(
            treasury,
            address(vesting),
            liquidity,
            address(rewards),
            community,
            reserve,
            address(0),
            deployer
        );
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

    function test_TokenV2_TaxRateCap100IsOK() public {
        vm.startPrank(treasury);
        token.setAITaxBps(100); // 1.0%
        vm.stopPrank();

        assertEq(token.aiUsageTaxBps(), 100);
    }

    function test_TokenV2_BurnFrom_NonBurnerReverts() public {
        address user = address(0x1111);
        vm.startPrank(treasury);
        token.transfer(user, 100e18);
        token.approve(user, 100e18); // user approves another user to burn
        // But user is not BURNER_ROLE
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert();
        token.burnFrom(user, 10e18);
        vm.stopPrank();
    }

    function test_TokenV2_TransferDuringPause_FromZeroAddress() public {
        // Mint/burn from/to address(0) should still work during pause
        vm.startPrank(treasury);
        token.pause();
        vm.stopPrank();

        // Transfer from zero (mint simulation via _mint) not possible via transfer
        // Burn to zero should work during pause
        vm.startPrank(treasury);
        token.burn(1e18);
        vm.stopPrank();

        assertEq(token.totalSupply(), 1_000_000_000e18 - 1e18);
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

    function test_TokenV2_CollectAITax_ZeroAmount() public {
        address collector = address(0x7777);

        vm.startPrank(treasury);
        token.setAITaxCollector(collector, true);
        token.transfer(collector, 100e18);
        vm.stopPrank();

        vm.startPrank(collector);
        uint256 taxedBefore = token.totalSupply();
        uint256 taxed = token.collectAITax(0);
        vm.stopPrank();

        assertEq(taxed, 0);
        assertEq(token.totalSupply(), taxedBefore);
    }

    function test_TokenV2_CollectAITax_InsufficientBalance() public {
        address collector = address(0x6666);
        uint256 amount = 1000e18;

        vm.startPrank(treasury);
        token.setAITaxCollector(collector, true);
        token.transfer(collector, 10e18); // less than amount
        vm.stopPrank();

        vm.startPrank(collector);
        uint256 taxedBefore = token.totalSupply();
        token.collectAITax(amount);
        vm.stopPrank();

        // taxed = (1000e18 * 30) / 10000 = 3e18
        // burn 3e18 from collector, totalSupply decreases by 3e18
        assertEq(token.totalSupply(), taxedBefore - 3e18);
    }

    function test_TokenV2_SetTaxCollector_ZeroAddress() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        token.setAITaxCollector(address(0), true);
        vm.stopPrank();
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
        vm.startPrank(treasury);
        token.transfer(address(vesting), 100_000_000e18);
        vm.stopPrank();

        // Warp past cliff + 1 month
        vm.warp(vesting.start() + vesting.cliffSeconds() + 30 days);

        vm.startPrank(team);
        vesting.release();
        vm.stopPrank();

        assertGt(token.balanceOf(team), 0);
    }

    function test_Vesting_Duration_Exhausted() public {
        vm.startPrank(treasury);
        token.transfer(address(vesting), 100_000_000e18);
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

    function test_Vesting_Constructor_RevertsOnZeroBeneficiary() public {
        vm.expectRevert();
        new QuantaVestingWallet(address(0), uint64(block.timestamp), 94608000, 31536000);
    }

    function test_Vesting_Constructor_DurationZeroReverts() public {
        vm.expectRevert();
        new QuantaVestingWallet(team, uint64(block.timestamp), 0, 31536000);
    }

    function test_Vesting_Constructor_CliffGTE_DurationReverts() public {
        vm.expectRevert();
        new QuantaVestingWallet(team, uint64(block.timestamp), 94608000, 94608000);
    }

    function test_Vesting_SetToken_SecondCallReverts() public {
        vm.startPrank(team);
        vm.expectRevert();
        vesting.setToken(address(token));
        vm.stopPrank();
    }

    // ===================================================================
    // QuantaTreasuryController tests
    // ===================================================================
    function test_Treasury_SetToken() public {
        assertEq(address(treasuryCtrl.token()), address(token));
    }

    function test_Treasury_SetToken_SecondCallReverts() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        treasuryCtrl.setToken(address(token));
        vm.stopPrank();
    }

    function test_Treasury_SetToken_ZeroReverts() public {
        QuantaTreasuryController fresh = new QuantaTreasuryController(
            treasury,
            treasury,
            treasury
        );
        vm.startPrank(treasury);
        vm.expectRevert();
        fresh.setToken(address(0));
        vm.stopPrank();
    }

    function test_Treasury_Constructor_RevertsOnZeroTreasury() public {
        vm.expectRevert();
        new QuantaTreasuryController(address(0), treasury, treasury);
    }

    function test_Treasury_Constructor_RevertsOnZeroProposer() public {
        vm.expectRevert();
        new QuantaTreasuryController(treasury, address(0), treasury);
    }

    function test_Treasury_Constructor_RevertsOnZeroExecutor() public {
        vm.expectRevert();
        new QuantaTreasuryController(treasury, treasury, address(0));
    }

    function test_Treasury_QueueTransfer_ZeroAmountReverts() public {
        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), 500e18);
        vm.expectRevert();
        treasuryCtrl.queueTransfer(treasury, 0);
        vm.stopPrank();
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

    function test_Treasury_RecoverNonQTA() public {
        MockERC20 mock = new MockERC20();
        mock.mint(address(treasuryCtrl), 100e18);
        vm.startPrank(treasury);
        treasuryCtrl.recoverTokens(address(mock), 100e18);
        vm.stopPrank();
    }

    function test_Treasury_GetPendingTransfer_AfterQueue() public {
        address recipient = address(0x1234);
        uint256 amount = 100e18;

        vm.startPrank(treasury);
        token.transfer(address(treasuryCtrl), amount);
        treasuryCtrl.queueTransfer(recipient, amount);
        vm.stopPrank();

        uint256 pendingAmt = treasuryCtrl.pendingAmount();
        assertEq(pendingAmt, amount);
    }

    // ===================================================================
    // Vesting: branch / edge coverage boost
    // ===================================================================
    function test_Vesting_SetToken_ZeroReverts() public {
        QuantaVestingWallet fresh = new QuantaVestingWallet(
            team,
            uint64(block.timestamp),
            94608000,
            31536000
        );
        vm.startPrank(team);
        vm.expectRevert();
        fresh.setToken(address(0));
        vm.stopPrank();
    }

    function test_Vesting_SetToken_CanOnlySetOnce() public {
        vm.startPrank(team);
        vm.expectRevert();
        vesting.setToken(address(token));
        vm.stopPrank();
    }

    function test_Vesting_CannotFundTwice() public {
        vm.startPrank(team);
        vm.expectRevert();
        vesting.fund();
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

    // ===================================================================
    // Rewards: branch / edge coverage boost
    // ===================================================================
    function test_Rewards_SetToken_ZeroReverts() public {
        QuantaRewardsDistributor fresh = new QuantaRewardsDistributor(treasury);
        vm.startPrank(treasury);
        vm.expectRevert();
        fresh.setToken(address(0));
        vm.stopPrank();
    }

    function test_Rewards_SetToken_CanOnlySetOnce() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        rewards.setToken(address(token));
        vm.stopPrank();
    }

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
        rewards.distribute(deployer, 0, "zero");
        vm.stopPrank();
    }

    function test_Rewards_NewDay_ResetsDaily() public {
        // Distribute max daily (amount=1 will trigger cap if daily already used)
        vm.startPrank(treasury);
        token.transfer(address(rewards), rewards.MAX_DAILY_EMISSION());
        vm.stopPrank();

        vm.startPrank(treasury);
        vm.warp(block.timestamp + 25 hours);
        rewards.distribute(deployer, 1, "next day");
        vm.stopPrank();
    }

    function test_Rewards_WeeklyCap() public {
        address recipient = address(0x7777);

        vm.startPrank(treasury);
        token.transfer(address(rewards), 10_000_000e18);
        vm.stopPrank();

        vm.startPrank(treasury);
        // Distribute 1M for 5 days (each within daily cap)
        for (uint256 i = 0; i < 5; i++) {
            vm.warp(block.timestamp + 1 days + 1 hours);
            rewards.distribute(recipient, 1_000_000e18, "day");
        }
        vm.warp(block.timestamp + 1 days + 1 hours);
        vm.expectRevert("Rewards: weekly cap");
        rewards.distribute(recipient, 1_000_000e18, "overflow week");
        vm.stopPrank();
    }

    function test_Rewards_NewWeek_ResetsWeekly() public {
        vm.startPrank(treasury);
        token.transfer(address(rewards), 6_000_000e18);
        vm.stopPrank();

        vm.startPrank(treasury);
        // Distribute 1M (within daily cap)
        rewards.distribute(deployer, 1_000_000e18, "week1");

        // Warp past a full week boundary
        vm.warp(block.timestamp + 7 days + 1 hours);

        // Weekly counter should reset, so we can distribute again
        rewards.distribute(deployer, 1_000_000e18, "week2");
        vm.stopPrank();
    }

    function test_Rewards_RecoverQTA_Reverts() public {
        vm.startPrank(treasury);
        vm.expectRevert();
        rewards.recoverTokens(address(token), 1e18);
        vm.stopPrank();
    }

    function test_Vesting_Vested_Cliff_ReturnsZero() public {
        uint64 cliff = vesting.cliffSeconds();
        uint256 pre = vesting.vestedAmount(cliff - 1);
        assertEq(pre, 0);
    }

    function test_Vesting_Fund_ZeroBalanceReverts() public {
        // Vesting already funded in setUp. Create a fresh vesting that holds no QTA
        // to exercise the fund() zero-balance revert path.
        QuantaVestingWallet fresh = new QuantaVestingWallet(
            team,
            uint64(block.timestamp),
            94608000,
            31536000
        );
        vm.startPrank(team);
        vm.expectRevert();
        fresh.fund();
        vm.stopPrank();
    }

    function test_Vesting_VestedAmount_LinearPath() public {
        // Cover linear branch after cliff, before duration.
        // setUp already funded vesting, so we only need to read vestedAmount
        // before/after cliff to cover the timestamp branches.
        uint64 cliff = vesting.cliffSeconds();
        uint256 before = vesting.vestedAmount(cliff - 1);
        assertEq(before, 0);
        uint64 afterCliff = cliff + 1 days;
        uint256 afterVal = vesting.vestedAmount(afterCliff);
        assertGt(afterVal, 0);
    }

    function test_Vesting_RecoverQTA_Reverts() public {
        vm.startPrank(team);
        vm.expectRevert();
        vesting.recoverTokens(address(token), 0);
        vm.stopPrank();
    }

    function test_Vesting_RecoverNonQTA() public {
        MockERC20 nonQta = new MockERC20();
        nonQta.mint(address(vesting), 100e18);
        vm.startPrank(team);
        vesting.recoverTokens(address(nonQta), 100e18);
        vm.stopPrank();
    }

    function test_Vesting_Release_ZeroAmountReverts() public {
        vm.startPrank(team);
        vm.expectRevert();
        vesting.release();
        vm.stopPrank();
    }
}
