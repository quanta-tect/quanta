// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src-v1.1/QuantaToken.sol";
import "../src-v1.1/AIAgentRegistry.sol";
import "../src-v1.1/AIPaymentChannel.sol";
import "../src-v1.1/AIModelMarketplace.sol";

/**
 * @title Security regression tests
 * @notice For each finding in SECURITY_AUDIT.md, verify the fix.
 *         Naming: test_<Severity>_<Finding>_<Behavior>
 */
contract SecurityFixesTest is Test {
    QuantaToken token;
    AIAgentRegistry registry;
    AIPaymentChannel channel;
    AIModelMarketplace market;

    address owner = address(0xA);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address attacker = address(0xBAD);
    address oracle = address(0x0RACLE);

    uint256 alicePk = uint256(keccak256("alice"));
    address aliceSigner;

    function setUp() public {
        aliceSigner = vm.addr(alicePk);

        vm.startPrank(owner);
        token = new QuantaToken(owner);
        registry = new AIAgentRegistry(owner);
        channel = new AIPaymentChannel(IERC20(address(token)), IQuantaToken(address(token)), owner);
        market = new AIModelMarketplace(
            IERC20(address(token)),
            IQuantaToken(address(token)),
            owner,           // treasury
            owner,           // validatorPool (simplified)
            owner
        );
        token.setAITaxCollector(address(market), true);
        token.setAITaxCollector(address(channel), true);
        registry.setReputationOracle(oracle, true);

        // Fund users
        token.transfer(alice, 100_000 ether);
        token.transfer(bob, 100_000 ether);
        token.transfer(aliceSigner, 100_000 ether);
        token.transfer(attacker, 100_000 ether);
        vm.stopPrank();
    }

    // ===================================================================
    // C-02: Reputation can only be adjusted by oracle
    // ===================================================================

    function test_C02_RandomCannotAdjustReputation() public {
        vm.prank(alice);
        AIAgentRegistry.SpendingPolicy memory p = _defaultPolicy();
        bytes32 id = registry.registerAgent("bot", alice, "ipfs://x", p);

        // Attacker tries to nuke reputation
        vm.prank(attacker);
        vm.expectRevert(AIAgentRegistry.NotReputationOracle.selector);
        registry.adjustReputation(id, -5000);
    }

    function test_C02_OracleCanAdjustReputation() public {
        vm.prank(alice);
        bytes32 id = registry.registerAgent("bot", alice, "ipfs://x", _defaultPolicy());

        vm.prank(oracle);
        registry.adjustReputation(id, -1000);

        (, , , , , , , uint32 rep, , , ) = registry.agents(id);
        assertEq(rep, 4000);
    }

    // ===================================================================
    // C-04: EIP-712 prevents cross-chain replay
    // ===================================================================

    function test_C04_SignatureBoundToChain() public {
        // Open channel
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0, 0);
        vm.stopPrank();

        // Build EIP-712 signature
        bytes32 digest = channel.hashTicket(cid, 5 ether, 1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // Bob closes — should work
        vm.prank(bob);
        channel.closeChannel(cid, 5 ether, 1, sig);

        // Now: same signature should NOT work on another contract (simulating other chain)
        AIPaymentChannel channel2 = new AIPaymentChannel(
            IERC20(address(token)), IQuantaToken(address(token)), owner
        );
        vm.prank(owner);
        token.setAITaxCollector(address(channel2), true);

        vm.startPrank(aliceSigner);
        token.approve(address(channel2), 10 ether);
        bytes32 cid2 = channel2.openChannel(bob, 1, 10 ether, 0, 0);
        vm.stopPrank();

        // Hash on channel2 will be different because EIP-712 domain includes verifyingContract
        bytes32 digest2 = channel2.hashTicket(cid2, 5 ether, 1);
        assertTrue(digest != digest2, "EIP-712 should differ across contracts");

        vm.prank(bob);
        vm.expectRevert(AIPaymentChannel.InvalidSignature.selector);
        channel2.closeChannel(cid2, 5 ether, 1, sig); // replay should fail
    }

    // ===================================================================
    // C-06: collectAITax cannot burn from arbitrary address
    // ===================================================================

    function test_C06_CannotBurnFromArbitraryAddress() public {
        // Authorize attacker as collector (simulating compromised whitelist)
        vm.prank(owner);
        token.setAITaxCollector(attacker, true);

        uint256 victimBalanceBefore = token.balanceOf(alice);

        // Attacker tries to burn from victim
        vm.prank(attacker);
        vm.expectRevert(QuantaToken.MustBurnFromSelf.selector);
        token.collectAITax(alice, 1_000_000 ether);

        // Victim's balance unchanged
        assertEq(token.balanceOf(alice), victimBalanceBefore);
    }

    function test_C06_CollectorCanBurnFromSelf() public {
        // Attacker has own tokens, can tax them
        uint256 attackerBalBefore = token.balanceOf(attacker);

        vm.prank(owner);
        token.setAITaxCollector(attacker, true);

        vm.prank(attacker);
        uint256 taxed = token.collectAITax(attacker, 1000 ether);

        assertEq(taxed, 3 ether); // 0.3% of 1000
        assertEq(token.balanceOf(attacker), attackerBalBefore - 3 ether);
    }

    // ===================================================================
    // H-01: Bridge change requires timelock
    // ===================================================================

    function test_H01_BridgeChangeRequiresTimelock() public {
        vm.prank(owner);
        token.proposeBridge(attacker);

        // Try to use bridge immediately
        vm.prank(attacker);
        vm.expectRevert(QuantaToken.OnlyBridge.selector);
        token.bridgeMint(attacker, 1000 ether);

        // Try to execute change immediately
        vm.expectRevert(QuantaToken.BridgeTimelockActive.selector);
        token.executeBridgeChange();

        // Fast forward 48h
        vm.warp(block.timestamp + 48 hours + 1);
        token.executeBridgeChange();

        // Now bridge is active
        vm.prank(attacker);
        token.bridgeMint(attacker, 1000 ether);
        assertEq(token.balanceOf(attacker), 100_000 ether + 1000 ether);
    }

    // ===================================================================
    // H-05: Registration fee prevents spam
    // ===================================================================

    function test_H05_RegistrationFeeRequired() public {
        // Without approval, registration fails
        vm.prank(alice);
        vm.expectRevert(); // ERC20 transfer fails
        market.registerModel("ipfs://w", "ipfs://m", 1 ether, 7000);

        // With approval, succeeds
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 aliceBalBefore = token.balanceOf(alice);
        market.registerModel("ipfs://w", "ipfs://m", 1 ether, 7000);
        assertEq(token.balanceOf(alice), aliceBalBefore - 1 ether);
        vm.stopPrank();
    }

    // ===================================================================
    // H-06: Min deposit prevents dust DoS
    // ===================================================================

    function test_H06_MinDepositEnforced() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 1 wei);
        vm.expectRevert(AIPaymentChannel.InsufficientDeposit.selector);
        channel.openChannel(bob, 1, 1 wei, 0, 0);
        vm.stopPrank();
    }

    // ===================================================================
    // C-03: forceClose cannot wipe payee's claims
    // ===================================================================

    function test_C03_ForceCloseBlockedAfterClaim() public {
        // Open + submit claim
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0, 0);
        vm.stopPrank();

        bytes32 digest = channel.hashTicket(cid, 5 ether, 1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
        vm.prank(bob);
        channel.closeChannel(cid, 5 ether, 1, abi.encodePacked(r, s, v));

        // Time passes
        vm.warp(block.timestamp + 8 days);

        // Alice tries forceClose — should fail because claim exists
        vm.prank(aliceSigner);
        vm.expectRevert(AIPaymentChannel.CannotForceClose.selector);
        channel.forceClose(cid);

        // But finalize works
        channel.finalize(cid);
    }

    function test_C03_ForceCloseWorksWhenNoClaim() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0, 0);

        vm.warp(block.timestamp + 8 days);
        uint256 balBefore = token.balanceOf(aliceSigner);
        channel.forceClose(cid);
        assertEq(token.balanceOf(aliceSigner), balBefore + 10 ether);
        vm.stopPrank();
    }

    // ===================================================================
    // M-06: Slippage protection
    // ===================================================================

    function test_M06_SlippageProtection() public {
        vm.startPrank(alice);
        token.approve(address(market), type(uint256).max);
        uint256 modelId = market.registerModel("ipfs://w", "ipfs://m", 1 ether, 7000);
        vm.stopPrank();

        // Bob tries to pay with maxPrice = 0.5, but model is 1.0
        vm.startPrank(bob);
        token.approve(address(market), 10 ether);
        vm.expectRevert(AIModelMarketplace.PriceExceedsMax.selector);
        market.payForInference(modelId, 0.5 ether);

        // With proper maxPrice, works
        market.payForInference(modelId, 1 ether);
        vm.stopPrank();
    }

    // ===================================================================
    // H-04: Pausable works
    // ===================================================================

    function test_H04_PauseStopsTransfers() public {
        vm.prank(owner);
        token.pause();

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 1 ether);

        vm.prank(owner);
        token.unpause();

        vm.prank(alice);
        token.transfer(bob, 1 ether);
    }

    // ===================================================================
    // I-05: Tax rate capped
    // ===================================================================

    function test_I05_TaxRateCannotExceedCap() public {
        vm.prank(owner);
        vm.expectRevert(QuantaToken.InvalidTaxRate.selector);
        token.setAITaxRate(101); // > MAX_TAX_BPS (100 = 1%)

        // 100 is OK
        vm.prank(owner);
        token.setAITaxRate(100);
    }

    // ===================================================================
    // L-05: Zero address checks
    // ===================================================================

    function test_L05_ZeroAddressRejected() public {
        vm.prank(owner);
        vm.expectRevert(QuantaToken.ZeroAddress.selector);
        token.proposeBridge(address(0));

        vm.prank(owner);
        vm.expectRevert(QuantaToken.ZeroAddress.selector);
        token.setAITaxCollector(address(0), true);
    }

    // ===================================================================
    // Helpers
    // ===================================================================

    function _defaultPolicy() internal pure returns (AIAgentRegistry.SpendingPolicy memory) {
        return AIAgentRegistry.SpendingPolicy({
            maxPerTx: 1 ether,
            maxPerDay: 10 ether,
            deathSwitchSec: 7 days,
            requireIntent: false
        });
    }
}
