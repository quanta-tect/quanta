// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/QuantaToken.sol";
import "../src/AIAgentRegistry.sol";
import "../src/AIModelMarketplace.sol";

contract QuantaTokenTest is Test {
    QuantaToken token;
    AIAgentRegistry registry;
    AIModelMarketplace market;

    address treasury = address(0xCAFE);
    address validatorPool = address(0xBEEF);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        token = new QuantaToken(treasury);
        registry = new AIAgentRegistry();
        market = new AIModelMarketplace(IERC20(address(token)), IQuantaToken(address(token)), treasury, validatorPool);

        // Authorize marketplace as tax collector
        vm.prank(treasury);
        token.setAITaxCollector(address(market), true);

        // Fund alice and bob
        vm.startPrank(treasury);
        token.transfer(alice, 10_000 ether);
        token.transfer(bob, 10_000 ether);
        vm.stopPrank();
    }

    function testGenesisSupply() public view {
        assertEq(token.totalSupply(), 300_000_000 ether);
        assertEq(token.MAX_SUPPLY(), 1_000_000_000 ether);
    }

    function testRegisterAgent() public {
        AIAgentRegistry.SpendingPolicy memory policy = AIAgentRegistry.SpendingPolicy({
            maxPerTx: 1 ether,
            maxPerDay: 10 ether,
            deathSwitchSec: 7 days,
            requireIntent: false
        });

        vm.prank(alice);
        bytes32 agentId = registry.registerAgent("ResearchBot", alice, "ipfs://meta", policy);

        (address owner,,,, , , , , , ) = registry.agents(agentId);
        // Note: returning all fields would need a getter — simplified check
        assertEq(owner, alice);
        assertTrue(registry.isAlive(agentId));
    }

    function testModelMarketplaceWithBurn() public {
        // Alice registers a model at 1 QTA per call
        vm.prank(alice);
        uint256 modelId = market.registerModel("ipfs://weights", "ipfs://card", 1 ether, 7000);

        uint256 supplyBefore = token.totalSupply();
        uint256 aliceBefore = token.balanceOf(alice);

        // Bob pays for inference
        vm.startPrank(bob);
        token.approve(address(market), 1 ether);
        market.payForInference(modelId);
        vm.stopPrank();

        // Verify: tax was burned, creator got 70% of net
        uint256 supplyAfter = token.totalSupply();
        uint256 aliceAfter = token.balanceOf(alice);

        assertLt(supplyAfter, supplyBefore, "supply should decrease (burn)");
        uint256 burned = supplyBefore - supplyAfter;
        assertEq(burned, 0.003 ether, "0.3% AI tax burned");

        uint256 net = 1 ether - burned;
        uint256 expectedCreator = (net * 7000) / 10000;
        assertEq(aliceAfter - aliceBefore, expectedCreator, "creator gets 70% of net");
    }

    function testCannotExceedMaxSupply() public {
        vm.prank(treasury);
        token.setBridge(address(this));

        // Try to mint over cap
        uint256 remaining = token.MAX_SUPPLY() - token.totalSupply();
        token.bridgeMint(alice, remaining); // OK
        vm.expectRevert(QuantaToken.CapExceeded.selector);
        token.bridgeMint(alice, 1);
    }

    function testBurnableByHolder() public {
        uint256 before = token.totalSupply();
        vm.prank(alice);
        token.burn(100 ether);
        assertEq(token.totalSupply(), before - 100 ether);
        assertEq(token.totalBurned(), 0); // totalBurned only tracks bridge+tax burns
    }
}
