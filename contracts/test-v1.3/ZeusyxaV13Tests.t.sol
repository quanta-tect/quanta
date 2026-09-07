// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Test.sol";
import "../src-v1.3/ZeusyxaToken.sol";
import "../src-v1.3/AIAgentRegistry.sol";
import "../src-v1.3/AIPaymentChannel.sol";
import "../src-v1.3/AIModelMarketplace.sol";

contract ZeusyxaV13Test is Test {
    ZeusyxaToken    token;
    AIAgentRegistry registry;
    AIPaymentChannel channel;
    AIModelMarketplace marketplace;

    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");
    address carol = makeAddr("carol");
    address treasury = makeAddr("treasury");
    address validators = makeAddr("validators");

    bytes32 agentId1 = keccak256("agent-1");
    bytes32 agentId2 = keccak256("agent-2");

    function setUp() public {
        token = new ZeusyxaToken(address(this));
        registry = new AIAgentRegistry(address(this));
        channel = new AIPaymentChannel(address(token), address(this));
        marketplace = new AIModelMarketplace(
            address(token),
            treasury,
            validators,
            address(this)
        );

        token.queueBridgeChange(address(this));
        vm.warp(block.timestamp + 7 days + 1);
        token.applyBridgeChange();
        token.bridgeMint(alice, 10_000e18);
        token.bridgeMint(bob, 10_000e18);
        token.bridgeMint(carol, 10_000e18);

        // Grant registry REPUTATION_ORACLE_ROLE to this test contract
        registry.grantReputationOracle(address(this));

        // Set test contract as AI tax collector for channel and marketplace
        token.setAITaxCollector(address(channel), true);
        token.setAITaxCollector(address(marketplace), true);

        vm.startPrank(alice);
        token.approve(address(channel), type(uint256).max);
        token.approve(address(marketplace), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(channel), type(uint256).max);
        token.approve(address(marketplace), type(uint256).max);
        vm.stopPrank();
    }

    // ========== ZeusyxaToken Tests ==========

    function testTokenNameSymbol() public {
        assertEq(token.name(), "Zeusyxa");
        assertEq(token.symbol(), "ZYX");
        assertEq(token.decimals(), 18);
    }

    function testTokenConstants() public {
        assertEq(token.MAX_SUPPLY(), 1_000_000_000e18);
        assertEq(token.MAX_TAX_BPS(), 5_000);
        assertEq(token.BRIDGE_TIMELOCK(), 7 days);
    }

    function testMintAndBalance() public {
        assertEq(token.balanceOf(alice), 10_000e18);
    }

    function testAITax() public {
        // Test contract is not a collector, but channel and marketplace are
        // So we test through the channel/marketplace which call collectAITax internally
        // Just verify the token has correct default tax bps
        assertEq(token.aiTaxBps(), 100);
    }

    function testSetAITaxBps() public {
        token.setAITaxBps(500); // 5%
        assertEq(token.aiTaxBps(), 500);
    }

    function testBridgeQueueAndApply() public {
        token.queueBridgeChange(bob);
        assertEq(token.pendingBridge(), bob);
        assertEq(token.bridgeChangeAt(), block.timestamp + 7 days);

        vm.warp(block.timestamp + 7 days + 1);
        token.applyBridgeChange();
        assertEq(token.bridge(), bob);
        assertEq(token.pendingBridge(), address(0));
    }

    // ========== AIAgentRegistry Tests ==========

    function testRegisterAgent() public {
        vm.startPrank(alice);
        registry.registerAgent(agentId1, "ipfs://metadata", 100e18, 1_000e18);
        vm.stopPrank();

        assertEq(registry.getAgentCount(alice), 1);
    }

    function testRegisterAgentDuplicateFails() public {
        vm.startPrank(alice);
        registry.registerAgent(agentId1, "ipfs://metadata", 100e18, 1_000e18);
        vm.expectRevert(AIAgentRegistry.AgentAlreadyExists.selector);
        registry.registerAgent(agentId1, "ipfs://other", 100e18, 1_000e18);
        vm.stopPrank();
    }

    function testRegisterAgentTooManyFails() public {
        vm.startPrank(alice);
        for (uint256 i = 0; i < 500; i++) {
            registry.registerAgent(bytes32(uint256(i)), "meta", 100e18, 1_000e18);
        }
        vm.expectRevert(AIAgentRegistry.TooManyAgents.selector);
        registry.registerAgent(bytes32(uint256(500)), "meta", 100e18, 1_000e18);
        vm.stopPrank();
    }

    function testUpdatePolicy() public {
        vm.startPrank(alice);
        registry.registerAgent(agentId1, "ipfs://meta", 100e18, 1_000e18);
        registry.updatePolicy(agentId1, 200e18, 2_000e18);
        vm.stopPrank();

        // Verify policy updated by checking spend limits
        vm.prank(alice);
        registry.checkAndRecordSpend(agentId1, 200e18); // Should work with new limit
        assertEq(registry.getRolling24hSpend(agentId1), 200e18);
    }

    function testAdjustReputation() public {
        vm.startPrank(alice);
        registry.registerAgent(agentId1, "ipfs://meta", 100e18, 1_000e18);
        vm.stopPrank();

        vm.prank(address(this));
        registry.adjustReputation(agentId1, 1_000);
        // Can't directly read reputation but can verify via events or other means
        // Just test it doesn't revert
    }

    function testCheckAndRecordSpend() public {
        vm.startPrank(alice);
        registry.registerAgent(agentId1, "ipfs://meta", 100e18, 1_000e18);
        vm.stopPrank();

        vm.prank(alice);
        registry.checkAndRecordSpend(agentId1, 100e18);
        assertEq(registry.getRolling24hSpend(agentId1), 100e18);

        // Second spend within per-tx limit
        vm.prank(alice);
        registry.checkAndRecordSpend(agentId1, 100e18);
        assertEq(registry.getRolling24hSpend(agentId1), 200e18);

        // Exceed per-tx limit first (900e18 > 100e18 maxPerTx)
        vm.prank(alice);
        vm.expectRevert(AIAgentRegistry.ExceedsMaxPerTx.selector);
        registry.checkAndRecordSpend(agentId1, 900e18);
    }

    function testCheckAndRecordSpendExceedsPerTx() public {
        vm.startPrank(alice);
        registry.registerAgent(agentId1, "ipfs://meta", 100e18, 1_000e18);
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert(AIAgentRegistry.ExceedsMaxPerTx.selector);
        registry.checkAndRecordSpend(agentId1, 200e18);
    }

    function testDeactivateAgent() public {
        vm.startPrank(alice);
        registry.registerAgent(agentId1, "ipfs://meta", 100e18, 1_000e18);
        vm.stopPrank();

        vm.prank(alice);
        registry.deactivateAgent(agentId1);

        // Try to spend on deactivated agent - should revert AgentInactive
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(0xf2c6592c, agentId1));
        registry.checkAndRecordSpend(agentId1, 100e18);
    }

    function testRollingWindowExpiry() public {
        vm.startPrank(alice);
        registry.registerAgent(agentId1, "ipfs://meta", 600e18, 1_000e18);
        vm.stopPrank();

        vm.prank(alice);
        registry.checkAndRecordSpend(agentId1, 500e18);

        vm.warp(block.timestamp + 25 hours);

        vm.prank(alice);
        registry.checkAndRecordSpend(agentId1, 600e18);
        assertEq(registry.getRolling24hSpend(agentId1), 600e18);
    }

    // ========== AIPaymentChannel Tests ==========

    function testOpenChannel() public {
        uint64 nonce = 1;
        bytes32 channelId = channel.getChannelId(alice, bob, nonce);

        vm.startPrank(alice);
        channel.openChannel(bob, nonce, 1_000e18, 7 days);
        vm.stopPrank();

        // Channel opened successfully (no revert)
    }

    function testForceClose() public {
        uint64 nonce = 1;
        bytes32 channelId = channel.getChannelId(alice, bob, nonce);

        vm.startPrank(alice);
        channel.openChannel(bob, nonce, 1_000e18, 7 days);
        vm.stopPrank();

        vm.prank(alice);
        channel.initiateForceClose(channelId);

        vm.warp(block.timestamp + 24 hours + 7 days + 1);

        vm.prank(alice);
        channel.executeForceClose(channelId);
        // Force close executed successfully (no revert)
    }

    // ========== AIModelMarketplace Tests ==========

    function testRegisterModel() public {
        vm.startPrank(alice);
        uint256 modelId = marketplace.registerModel(100e18, 1_000, "ipfs://model-meta");
        vm.stopPrank();

        assertEq(modelId, 0);
        assertEq(marketplace.modelCountByCreator(alice), 1);
        assertEq(token.balanceOf(alice), 10_000e18 - 1e18);
        assertEq(token.balanceOf(treasury), 1e18);
    }

    function testRegisterModelInvalidRoyalty() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(0x8243d3d7, 9500));
        marketplace.registerModel(100e18, 9_500, "ipfs://model-meta");
        vm.stopPrank();
    }

    function testPayForInference() public {
        vm.startPrank(alice);
        uint256 modelId = marketplace.registerModel(100e18, 1_000, "ipfs://model-meta");
        vm.stopPrank();

        vm.startPrank(bob);
        marketplace.payForInference(modelId, 100e18);
        vm.stopPrank();

        // Inference paid successfully
    }

    function testDeactivateModel() public {
        vm.startPrank(alice);
        uint256 modelId = marketplace.registerModel(100e18, 1_000, "ipfs://model-meta");
        vm.stopPrank();

        vm.startPrank(alice);
        marketplace.deactivateModel(modelId);
        vm.stopPrank();

        // Model deactivated (no revert)
    }
}