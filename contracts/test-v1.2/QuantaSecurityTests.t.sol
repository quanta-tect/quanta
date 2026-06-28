// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Test.sol";
import "../src-v1.2/QuantaToken.sol";
import "../src-v1.2/AIAgentRegistry.sol";
import "../src-v1.2/AIPaymentChannel.sol";
import "../src-v1.2/AIModelMarketplace.sol";

/**
 * @title QuantaV12SecurityTests
 * @notice Comprehensive security + regression tests for QUANTA v1.2
 * @dev Tests all 4 contracts with their hardened security features
 *
 * Run: forge test -vvv
 */
contract QuantaV12SecurityTests is Test {
    // ===================================================================
    // Contracts
    // ===================================================================

    QuantaToken token;
    AIAgentRegistry registry;
    AIPaymentChannel channel;
    AIModelMarketplace market;

    // ===================================================================
    // Accounts
    // ===================================================================

    address owner = address(0xA);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address attacker = address(0xBAD);
    address oracle = address(0x04AC1E);
    address treasury = address(0xCAFE);
    address validator = address(0xBEEF);

    uint256 alicePk = uint256(keccak256("alice"));
    address aliceSigner;

    // ===================================================================
    // Events (for emission testing)
    // ===================================================================

    event Transfer(address indexed from, address indexed to, uint256 value);

    // ===================================================================
    // Setup
    // ===================================================================

    function setUp() public {
        aliceSigner = vm.addr(alicePk);

        vm.startPrank(owner);
        token = new QuantaToken(owner);
        registry = new AIAgentRegistry(owner);
        channel = new AIPaymentChannel(address(token), owner);
        market = new AIModelMarketplace(
            address(token),
            treasury,
            validator,
            owner
        );

        // Authorize tax collectors
        token.setAITaxCollector(address(channel), true);
        token.setAITaxCollector(address(market), true);

        // Set reputation oracle
        registry.setReputationOracle(oracle, true);

        // Fund users
        token.transfer(alice, 100_000 ether);
        token.transfer(bob, 100_000 ether);
        token.transfer(aliceSigner, 100_000 ether);
        token.transfer(attacker, 100_000 ether);
        vm.stopPrank();
    }

    // ===================================================================
    // QUANTA TOKEN TESTS
    // ===================================================================

    function test_Token_GenesisSupply() public view {
        assertEq(token.totalSupply(), 300_000_000 ether);
        assertEq(token.balanceOf(owner), 300_000_000 ether - 400_000 ether);
    }

    function test_Token_MaxSupply() public view {
        assertEq(token.MAX_SUPPLY(), 1_000_000_000 ether);
    }

    function test_Token_Transfer() public {
        uint256 aliceBal = token.balanceOf(alice);
        uint256 bobBal = token.balanceOf(bob);

        vm.prank(alice);
        token.transfer(bob, 1 ether);

        assertEq(token.balanceOf(alice), aliceBal - 1 ether);
        assertEq(token.balanceOf(bob), bobBal + 1 ether);
    }

    function test_Token_TransferFailsWhenPaused() public {
        vm.prank(owner);
        token.pause();

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 1 ether);
    }

    function test_Token_UnpauseResumesTransfers() public {
        vm.prank(owner);
        token.pause();
        vm.prank(owner);
        token.unpause();

        vm.prank(alice);
        token.transfer(bob, 1 ether); // Should succeed
    }

    function test_Token_OnlyOwnerCanPause() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        token.pause();
    }

    function test_Token_Burn() public {
        uint256 supplyBefore = token.totalSupply();
        vm.prank(alice);
        token.burn(100 ether);
        assertEq(token.totalSupply(), supplyBefore - 100 ether);
    }

    function test_Token_SetTaxRate() public {
        vm.prank(owner);
        token.setAITaxBps(50); // 0.5%
        assertEq(token.aiUsageTaxBps(), 50);
    }

    function test_Token_TaxRateCannotExceedCap() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(QuantaToken.InvalidTaxRate.selector, uint16(101)));
        token.setAITaxBps(101); // > MAX_TAX_BPS (100 = 1%)
    }

    function test_Token_TaxRateCap100IsOK() public {
        vm.prank(owner);
        token.setAITaxBps(100); // Exactly 1%
        assertEq(token.aiUsageTaxBps(), 100);
    }

    function test_Token_SetTaxCollector() public {
        vm.prank(owner);
        token.setAITaxCollector(attacker, true);
        assertTrue(token.aiTaxCollectors(attacker));
    }

    function test_Token_SetTaxCollector_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(QuantaToken.ZeroAddress.selector, address(0)));
        token.setAITaxCollector(address(0), true);
    }

    function test_Token_CollectAITax_BurnsFromCollector() public {
        // Give attacker tokens and authorize
        vm.prank(owner);
        token.setAITaxCollector(attacker, true);

        uint256 attackerBalBefore = token.balanceOf(attacker);
        uint256 supplyBefore = token.totalSupply();

        vm.prank(attacker);
        uint256 taxed = token.collectAITax(1000 ether);

        // Tax = 0.3% of 1000 = 3 ether
        assertEq(taxed, 3 ether);
        assertEq(token.balanceOf(attacker), attackerBalBefore - 3 ether);
        assertEq(token.totalSupply(), supplyBefore - 3 ether);
    }

    function test_Token_CollectAITax_NotCollector() public {
        vm.prank(attacker);
        vm.expectRevert(QuantaToken.NotCollector.selector);
        token.collectAITax(1000 ether);
    }

    function test_Token_CollectAITax_CannotBurnFromArbitrary() public {
        // Authorize attacker as collector
        vm.prank(owner);
        token.setAITaxCollector(attacker, true);

        uint256 aliceBalBefore = token.balanceOf(alice);

        // Attacker calls collectAITax — burns from attacker, NOT from alice
        vm.prank(attacker);
        token.collectAITax(1000 ether);

        // Alice's balance unchanged
        assertEq(token.balanceOf(alice), aliceBalBefore);
    }

    function test_Token_BridgeMint() public {
        // Set bridge via timelock
        vm.prank(owner);
        token.queueBridgeChange(address(this));
        vm.warp(block.timestamp + 48 hours + 1);
        vm.prank(owner);
        token.applyBridgeChange();

        uint256 supplyBefore = token.totalSupply();
        token.bridgeMint(alice, 1000 ether);
        assertEq(token.totalSupply(), supplyBefore + 1000 ether);
        assertEq(token.balanceOf(alice), 100_000 ether + 1000 ether);
    }

    function test_Token_BridgeMint_OnlyBridge() public {
        vm.prank(attacker);
        vm.expectRevert(QuantaToken.NotBridge.selector);
        token.bridgeMint(attacker, 1000 ether);
    }

    function test_Token_BridgeMint_CannotExceedCap() public {
        vm.prank(owner);
        token.queueBridgeChange(address(this));
        vm.warp(block.timestamp + 48 hours + 1);
        vm.prank(owner);
        token.applyBridgeChange();

        uint256 remaining = token.MAX_SUPPLY() - token.totalSupply();
        token.bridgeMint(alice, remaining); // OK

        vm.expectRevert(QuantaToken.CapExceeded.selector);
        token.bridgeMint(alice, 1);
    }

    function test_Token_BridgeBurn() public {
        vm.prank(owner);
        token.queueBridgeChange(address(this));
        vm.warp(block.timestamp + 48 hours + 1);
        vm.prank(owner);
        token.applyBridgeChange();

        uint256 aliceBalBefore = token.balanceOf(alice);
        token.bridgeBurn(alice, 1000 ether);
        assertEq(token.balanceOf(alice), aliceBalBefore - 1000 ether);
    }

    function test_Token_BridgeTimelock_Queue() public {
        vm.prank(owner);
        token.queueBridgeChange(attacker);

        // Bridge not active yet
        vm.prank(attacker);
        vm.expectRevert(QuantaToken.NotBridge.selector);
        token.bridgeMint(attacker, 100 ether);
    }

    function test_Token_BridgeTimelock_ExecuteAfter48h() public {
        vm.prank(owner);
        token.queueBridgeChange(attacker);

        // Try before 48h
        vm.warp(block.timestamp + 47 hours);
        vm.expectRevert(QuantaToken.TimelockActive.selector);
        vm.prank(owner);
        token.applyBridgeChange();

        // After 48h
        vm.warp(block.timestamp + 48 hours + 1);
        vm.prank(owner);
        token.applyBridgeChange();

        // Now bridge works
        vm.prank(attacker);
        token.bridgeMint(attacker, 100 ether);
    }

    function test_Token_BridgeTimelock_Cancel() public {
        vm.prank(owner);
        token.queueBridgeChange(attacker);

        vm.prank(owner);
        token.cancelBridgeChange();

        // Even after 48h, bridge not active
        vm.warp(block.timestamp + 48 hours + 1);
        vm.prank(attacker);
        vm.expectRevert(QuantaToken.NotBridge.selector);
        token.bridgeMint(attacker, 100 ether);
    }

    function test_Token_BridgeMint_Paused() public {
        vm.prank(owner);
        token.queueBridgeChange(address(this));
        vm.warp(block.timestamp + 48 hours + 1);
        vm.prank(owner);
        token.applyBridgeChange();

        vm.prank(owner);
        token.pause();

        vm.expectRevert();
        token.bridgeMint(alice, 100 ether);
    }

    function test_Token_BridgeMint_ZeroToReverts() public {
        vm.prank(owner);
        token.queueBridgeChange(address(this));
        vm.warp(block.timestamp + 48 hours + 1);
        vm.prank(owner);
        token.applyBridgeChange();

        vm.prank(address(this));
        vm.expectRevert(abi.encodeWithSelector(QuantaToken.ZeroAddress.selector, address(0)));
        token.bridgeMint(address(0), 100 ether);
    }

    function test_Token_BridgeBurn_ZeroFromReverts() public {
        vm.prank(owner);
        token.queueBridgeChange(address(this));
        vm.warp(block.timestamp + 48 hours + 1);
        vm.prank(owner);
        token.applyBridgeChange();

        vm.prank(address(this));
        vm.expectRevert(abi.encodeWithSelector(QuantaToken.ZeroAddress.selector, address(0)));
        token.bridgeBurn(address(0), 100 ether);
    }

    function test_Token_RecoverTokens_RevertsOnQTA() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(QuantaToken.ZeroAddress.selector, address(token)));
        token.recoverTokens(address(token), 100 ether);
    }

    function test_Token_Permit() public {
        // EIP-2612 permit test
        uint256 nonce = token.nonces(aliceSigner);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 DOMAIN_SEPARATOR = token.DOMAIN_SEPARATOR();
        bytes32 PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, aliceSigner, bob, 1 ether, nonce, deadline)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);

        vm.prank(bob);
        token.permit(aliceSigner, bob, 1 ether, deadline, v, r, s);

        assertEq(token.allowance(aliceSigner, bob), 1 ether);
    }

    // ===================================================================
    // AI AGENT REGISTRY TESTS
    // ===================================================================

    function test_Registry_RegisterAgent() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "ResearchBot"));
        registry.registerAgent(agentId, "ipfs://meta", 1 ether, 10 ether);

        (address ownerAddr, uint256 reputation, , , string memory uri, uint64 registeredAt, bool active) =
            registry.agents(agentId);

        assertEq(ownerAddr, alice);
        assertEq(reputation, 5000); // Default starting reputation
        assertEq(keccak256(bytes(uri)), keccak256("ipfs://meta"));
        assertTrue(active);
        assertGt(registeredAt, 0);
    }

    function test_Registry_RegisterAgent_DuplicateId() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        // Same ID should fail
        vm.prank(alice);
        vm.expectRevert(AIAgentRegistry.AgentAlreadyExists.selector);
        registry.registerAgent(agentId, "ipfs://m2", 2 ether, 20 ether);
    }

    function test_Registry_RegisterAgent_MetadataTooLong() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        string memory longMeta = new string(513); // > MAX_METADATA_LEN (512)
        vm.expectRevert(AIAgentRegistry.MetadataTooLong.selector);
        registry.registerAgent(agentId, longMeta, 1 ether, 10 ether);
    }

    function test_Registry_RegisterAgent_InvalidPolicy() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));

        // maxPerTx > maxPerDay
        vm.expectRevert(AIAgentRegistry.InvalidPolicy.selector);
        registry.registerAgent(agentId, "ipfs://m", 10 ether, 1 ether);
    }

    function test_Registry_RegisterAgent_MaxPerOwner() public {
        // Register MAX_AGENTS_PER_OWNER agents
        for (uint256 i = 0; i < 500; i++) {
            vm.prank(alice);
            bytes32 botId = keccak256(abi.encode(alice, string(abi.encodePacked("Bot", i))));
            registry.registerAgent(botId, "ipfs://m", 1 ether, 10 ether);
        }

        // 501st should fail
        vm.prank(alice);
        bytes32 botId = keccak256(abi.encode(alice, "BotOverflow"));
        vm.expectRevert(AIAgentRegistry.TooManyAgents.selector);
        registry.registerAgent(botId, "ipfs://m", 1 ether, 10 ether);
    }

    function test_Registry_DeactivateAgent() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.prank(alice);
        registry.deactivateAgent(agentId);

        (, , , , , , bool active) = registry.agents(agentId);
        assertFalse(active);
    }

    function test_Registry_DeactivateAgent_OnlyOwner() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.prank(attacker);
        vm.expectRevert(AIAgentRegistry.NotAuthorized.selector);
        registry.deactivateAgent(agentId);
    }

    function test_Registry_UpdatePolicy() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.prank(alice);
        registry.updatePolicy(agentId, 2 ether, 20 ether);
    }

    function test_Registry_UpdatePolicy_OnlyOwner() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.prank(attacker);
        vm.expectRevert(AIAgentRegistry.NotOwner.selector);
        registry.updatePolicy(agentId, 2 ether, 20 ether);
    }

    function test_Registry_AdjustReputation_OnlyOracle() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.prank(attacker);
        vm.expectRevert(AIAgentRegistry.NotReputationOracle.selector);
        registry.adjustReputation(agentId, -1000);
    }

    function test_Registry_AdjustReputation_OracleCanAdjust() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.prank(oracle);
        registry.adjustReputation(agentId, -1000);

        (, uint256 reputation, , , , , ) = registry.agents(agentId);
        assertEq(reputation, 4000);
    }

    function test_Registry_AdjustReputation_CappedAtZero() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.prank(oracle);
        registry.adjustReputation(agentId, -999999);

        (, uint256 reputation, , , , , ) = registry.agents(agentId);
        assertEq(reputation, 0);
    }

    function test_Registry_AdjustReputation_CappedAtMax() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.prank(oracle);
        registry.adjustReputation(agentId, 999999);

        (, uint256 reputation, , , , , ) = registry.agents(agentId);
        assertEq(reputation, 10000); // MAX_REPUTATION
    }

    function test_Registry_SetReputationOracle() public {
        vm.prank(owner);
        registry.setReputationOracle(attacker, true);
        assertTrue(registry.reputationOracles(attacker));
    }

    function test_Registry_SetReputationOracle_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(AIAgentRegistry.ZeroAddress.selector);
        registry.setReputationOracle(address(0), true);
    }

    function test_Registry_CheckAndRecordSpend_WithinLimit() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        // Spend within limit
        registry.checkAndRecordSpend(agentId, 0.5 ether);
        registry.checkAndRecordSpend(agentId, 0.5 ether);

        uint256 total = registry.getRolling24hSpend(agentId);
        assertEq(total, 1 ether);
    }

    function test_Registry_CheckAndRecordSpend_ExceedsMaxPerTx() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        vm.expectRevert(AIAgentRegistry.ExceedsMaxPerTx.selector);
        registry.checkAndRecordSpend(agentId, 2 ether); // > maxPerTx (1 ether)
    }

    function test_Registry_CheckAndRecordSpend_ExceedsMaxPerDay() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        // Spend 10 ether (max per day)
        for (uint256 i = 0; i < 10; i++) {
            registry.checkAndRecordSpend(agentId, 1 ether);
        }

        // 11th should fail
        vm.expectRevert(AIAgentRegistry.ExceedsMaxPerDay.selector);
        registry.checkAndRecordSpend(agentId, 1 ether);
    }

    function test_Registry_RollingWindow_ExpiresAfter1Hour() public {
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);

        // Spend 5 ether
        for (uint256 i = 0; i < 5; i++) {
            registry.checkAndRecordSpend(agentId, 1 ether);
        }

        // Advance 1 hour + 1 second
        vm.warp(block.timestamp + 1 hours + 1);

        // Old spend should be expired, can spend again
        for (uint256 i = 0; i < 5; i++) {
            registry.checkAndRecordSpend(agentId, 1 ether);
        }
    }

    function test_Registry_Paused() public {
        vm.prank(owner);
        registry.pause();

        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        vm.expectRevert();
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);
    }

    // ===================================================================
    // AI PAYMENT CHANNEL TESTS
    // ===================================================================

    function test_Channel_Open() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        (address payer, address payee, uint256 deposit, uint256 settledAt, uint64 openedAt, uint64 closeInitiatedAt, uint64 timeout, AIPaymentChannel.ChannelState state) =
            channel.channels(cid);

        assertEq(payer, aliceSigner);
        assertEq(payee, bob);
        assertEq(deposit, 10 ether);
        assertEq(settledAt, 0);
        assertEq(uint8(state), uint8(AIPaymentChannel.ChannelState.Open));
        assertGt(openedAt, 0);
    }

    function test_Channel_Open_MinDeposit() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 1 ether);
        // Below MIN_DEPOSIT (0.01 ether = 1e16)
        vm.expectRevert(abi.encodeWithSelector(AIPaymentChannel.DepositTooSmall.selector, 0.001 ether));
        channel.openChannel(bob, 1, 0.001 ether, 0);
        vm.stopPrank();
    }

    function test_Channel_Open_ZeroPayee() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        vm.expectRevert(AIPaymentChannel.ZeroPayee.selector);
        channel.openChannel(address(0), 1, 10 ether, 0);
        vm.stopPrank();
    }

    function test_Channel_Open_Duplicate() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 20 ether);
        channel.openChannel(bob, 1, 10 ether, 0);

        vm.expectRevert(AIPaymentChannel.ChannelExists.selector);
        channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();
    }

    function test_Channel_Open_CustomTimeout() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        // Custom timeout = 12 hours
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 12 hours);
        vm.stopPrank();

        (, , , , , , uint64 timeout, ) = channel.channels(cid);
        assertEq(timeout, 12 hours);
    }

    function test_Channel_Open_TimeoutBounds() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        // Below MIN_TIMEOUT (1 hour)
        vm.expectRevert(abi.encodeWithSelector(AIPaymentChannel.InvalidTimeout.selector, uint64(30 minutes)));
        channel.openChannel(bob, 1, 10 ether, 30 minutes);

        // Above MAX_TIMEOUT (30 days)
        vm.expectRevert(abi.encodeWithSelector(AIPaymentChannel.InvalidTimeout.selector, uint64(31 days)));
        channel.openChannel(bob, 2, 10 ether, 31 days);
        vm.stopPrank();
    }

    function test_Channel_Close() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        // Sign ticket
        bytes32 structHash = keccak256(
            abi.encode(
                channel.TICKET_TYPEHASH(),
                cid,
                5 ether,
                uint256(1)
            )
        );
        bytes32 digest = channel.domainSeparator();
        bytes32 fullDigest = keccak256(
            abi.encodePacked("\x19\x01", digest, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, fullDigest);
        bytes memory sig = abi.encodePacked(r, s, v);

        uint256 bobBalBefore = token.balanceOf(bob);

        vm.prank(bob);
        channel.closeChannel(cid, 5 ether, 1, sig);

        // Bob gets 5 ether minus tax
        uint256 bobReceived = token.balanceOf(bob) - bobBalBefore;
        assertGt(bobReceived, 0);
        assertLt(bobReceived, 5 ether); // Tax deducted

        // Channel closed
        (, , , , , , , AIPaymentChannel.ChannelState state) = channel.channels(cid);
        assertEq(uint8(state), uint8(AIPaymentChannel.ChannelState.Closed));
    }

    function test_Channel_Close_OnlyPayee() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        vm.prank(attacker);
        vm.expectRevert(AIPaymentChannel.NotPayee.selector);
        channel.closeChannel(cid, 5 ether, 1, "");
    }

    function test_Channel_Close_InvalidSignature() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        // Sign with wrong key
        uint256 bobPk = uint256(keccak256("bob"));
        bytes32 structHash = keccak256(
            abi.encode(channel.TICKET_TYPEHASH(), cid, 5 ether, uint256(1))
        );
        bytes32 digest = channel.domainSeparator();
        bytes32 fullDigest = keccak256(
            abi.encodePacked("\x19\x01", digest, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPk, fullDigest);

        vm.prank(bob);
        vm.expectRevert(AIPaymentChannel.InvalidSignature.selector);
        channel.closeChannel(cid, 5 ether, 1, abi.encodePacked(r, s, v));
    }

    function test_Channel_Close_AmountNotHigher() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        // Initiate force close (state becomes Closing)
        vm.prank(aliceSigner);
        channel.initiateForceClose(cid);

        // Sign for 5 ether (nonce 1) - valid challenge
        bytes32 structHash1 = keccak256(
            abi.encode(channel.TICKET_TYPEHASH(), cid, 5 ether, uint256(1))
        );
        bytes32 digest = channel.domainSeparator();
        bytes32 fullDigest1 = keccak256(
            abi.encodePacked("\x19\x01", digest, structHash1)
        );
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(alicePk, fullDigest1);

        vm.prank(bob);
        channel.challengeForceClose(cid, 5 ether, 1, abi.encodePacked(r1, s1, v1));

        // Sign for 3 ether (nonce 2) - lower amount, should fail
        bytes32 structHash2 = keccak256(
            abi.encode(channel.TICKET_TYPEHASH(), cid, 3 ether, uint256(2))
        );
        bytes32 fullDigest2 = keccak256(
            abi.encodePacked("\x19\x01", digest, structHash2)
        );
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(alicePk, fullDigest2);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(AIPaymentChannel.AmountNotHigher.selector, 3 ether, 5 ether));
        channel.challengeForceClose(cid, 3 ether, 2, abi.encodePacked(r2, s2, v2));
    }

    function test_Channel_ForceClose_Initiate() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        vm.prank(aliceSigner);
        channel.initiateForceClose(cid);

        (, , , , , uint64 closeInitiatedAt, , AIPaymentChannel.ChannelState state) =
            channel.channels(cid);
        assertEq(uint8(state), uint8(AIPaymentChannel.ChannelState.Closing));
        assertGt(closeInitiatedAt, 0);
    }

    function test_Channel_ForceClose_OnlyPayer() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        vm.prank(attacker);
        vm.expectRevert(AIPaymentChannel.NotPayer.selector);
        channel.initiateForceClose(cid);
    }

    function test_Channel_ForceClose_Challenge() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        // Initiate force close
        vm.prank(aliceSigner);
        channel.initiateForceClose(cid);

        // Bob challenges with signed ticket for 3 ether
        bytes32 structHash = keccak256(
            abi.encode(channel.TICKET_TYPEHASH(), cid, 3 ether, uint256(1))
        );
        bytes32 digest = channel.domainSeparator();
        bytes32 fullDigest = keccak256(
            abi.encodePacked("\x19\x01", digest, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, fullDigest);

        vm.prank(bob);
        channel.challengeForceClose(cid, 3 ether, 1, abi.encodePacked(r, s, v));

        // settledAmount updated
        (, , , uint256 settledAmount, , , , ) = channel.channels(cid);
        assertEq(settledAmount, 3 ether);
    }

    function test_Channel_ForceClose_ExecuteAfterTimeout() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        // Initiate force close
        vm.prank(aliceSigner);
        channel.initiateForceClose(cid);

        // Advance past challenge window + timeout
        vm.warp(block.timestamp + 24 hours + 7 days + 1);

        uint256 aliceBalBefore = token.balanceOf(aliceSigner);
        vm.prank(aliceSigner);
        channel.executeForceClose(cid);

        // Alice gets full refund (no claim was made)
        uint256 aliceReceived = token.balanceOf(aliceSigner) - aliceBalBefore;
        assertEq(aliceReceived, 10 ether);
    }

    function test_Channel_ForceClose_CannotExecuteDuringChallenge() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        vm.prank(aliceSigner);
        channel.initiateForceClose(cid);

        // Try to execute before challenge window expires
        vm.warp(block.timestamp + 1 hours);
        vm.prank(aliceSigner);
        vm.expectRevert(AIPaymentChannel.TimeoutActive.selector);
        channel.executeForceClose(cid);
    }

    function test_Channel_CrossChainReplayFails() public {
        // Open channel on this contract
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        bytes32 cid = channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        // Sign ticket
        bytes32 structHash = keccak256(
            abi.encode(channel.TICKET_TYPEHASH(), cid, 5 ether, uint256(1))
        );
        bytes32 digest = channel.domainSeparator();
        bytes32 fullDigest = keccak256(
            abi.encodePacked("\x19\x01", digest, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, fullDigest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // Deploy new channel contract (simulating different chain)
        AIPaymentChannel channel2 = new AIPaymentChannel(address(token), owner);
        vm.prank(owner);
        token.setAITaxCollector(address(channel2), true);

        // Open channel on channel2 with same params
        vm.startPrank(aliceSigner);
        token.approve(address(channel2), 10 ether);
        bytes32 cid2 = channel2.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();

        // Try to replay signature on channel2 — should fail (different domain separator)
        vm.prank(bob);
        vm.expectRevert(AIPaymentChannel.InvalidSignature.selector);
        channel2.closeChannel(cid2, 5 ether, 1, sig);
    }

    function test_Channel_Paused() public {
        vm.prank(owner);
        channel.pause();

        vm.startPrank(aliceSigner);
        token.approve(address(channel), 10 ether);
        vm.expectRevert();
        channel.openChannel(bob, 1, 10 ether, 0);
        vm.stopPrank();
    }

    // ===================================================================
    // AI MODEL MARKETPLACE TESTS
    // ===================================================================

    function test_Marketplace_RegisterModel() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether + 10 ether); // registration fee + extra
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://meta");
        vm.stopPrank();

        assertEq(modelId, 0);

        AIModelMarketplace.Model memory m = market.getModel(modelId);

        assertEq(m.creator, alice);
        assertEq(m.pricePerCall, 1 ether);
        assertEq(m.royaltyBps, 7000);
        assertTrue(m.active);
        assertEq(keccak256(bytes(m.metadataURI)), keccak256("ipfs://meta"));
    }

    function test_Marketplace_RegisterModel_FeeDeducted() public {
        uint256 treasuryBalBefore = token.balanceOf(treasury);

        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();

        // Registration fee (1 ether) goes to treasury
        assertEq(token.balanceOf(treasury), treasuryBalBefore + 1 ether);
    }

    function test_Marketplace_RegisterModel_TooManyModels() public {
        vm.startPrank(alice);
        token.approve(address(market), 200 ether); // Enough for 200 registrations

        for (uint256 i = 0; i < 100; i++) {
            market.registerModel(1 ether, 7000, "ipfs://m");
        }

        // 101st should fail
        vm.expectRevert(AIModelMarketplace.TooManyModels.selector);
        market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();
    }

    function test_Marketplace_RegisterModel_InvalidRoyalty() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        vm.expectRevert(abi.encodeWithSelector(AIModelMarketplace.InvalidRoyalty.selector, 9500));
        market.registerModel(1 ether, 9500, "ipfs://m"); // > MAX_ROYALTY_BPS (9000)
        vm.stopPrank();
    }

    function test_Marketplace_RegisterModel_ZeroPrice() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        vm.expectRevert(AIModelMarketplace.ZeroPrice.selector);
        market.registerModel(0, 7000, "ipfs://m");
        vm.stopPrank();
    }

    function test_Marketplace_PayForInference() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();

        uint256 aliceBalBefore = token.balanceOf(alice);
        uint256 bobBalBefore = token.balanceOf(bob);
        uint256 treasuryBalBefore = token.balanceOf(treasury);
        uint256 validatorBalBefore = token.balanceOf(validator);

        vm.startPrank(bob);
        token.approve(address(market), 1 ether);
        market.payForInference(modelId, 1 ether);
        vm.stopPrank();

        // Bob paid 1 ether
        assertLt(token.balanceOf(bob), bobBalBefore);

        // Alice (creator) got royalty
        assertGt(token.balanceOf(alice), aliceBalBefore);

        // Treasury and validator got fees
        assertGt(token.balanceOf(treasury), treasuryBalBefore);
        assertGt(token.balanceOf(validator), validatorBalBefore);
    }

    function test_Marketplace_PayForInference_SlippageProtection() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(market), 1 ether);
        vm.expectRevert(AIModelMarketplace.PriceSlipped.selector);
        market.payForInference(modelId, 0.5 ether); // maxPrice < actual price
        vm.stopPrank();
    }

    function test_Marketplace_PayForInference_InactiveModel() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        market.deactivateModel(modelId);
        vm.stopPrank();

        // Warp past the 24h grace period
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(bob);
        token.approve(address(market), 1 ether);
        vm.expectRevert(AIModelMarketplace.ModelUnavailable.selector);
        market.payForInference(modelId, 1 ether);
        vm.stopPrank();
    }

    function test_Marketplace_PayForInference_GracePeriod() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        market.deactivateModel(modelId);
        vm.stopPrank();

        // Within grace period (24h), can still pay
        vm.warp(block.timestamp + 12 hours);

        vm.startPrank(bob);
        token.approve(address(market), 1 ether);
        market.payForInference(modelId, 1 ether); // Should succeed within grace
        vm.stopPrank();

        // After grace period, fails
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(bob);
        token.approve(address(market), 1 ether);
        vm.expectRevert(AIModelMarketplace.ModelUnavailable.selector);
        market.payForInference(modelId, 1 ether);
        vm.stopPrank();
    }

    function test_Marketplace_UpdatePrice() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        market.updatePrice(modelId, 2 ether);
        vm.stopPrank();

        AIModelMarketplace.Model memory m = market.getModel(modelId);
        assertEq(m.pricePerCall, 2 ether);
    }

    function test_Marketplace_UpdatePrice_OnlyCreator() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();

        vm.prank(attacker);
        vm.expectRevert(AIModelMarketplace.NotCreator.selector);
        market.updatePrice(modelId, 2 ether);
    }

    function test_Marketplace_DeactivateModel() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        market.deactivateModel(modelId);
        vm.stopPrank();

        AIModelMarketplace.Model memory m = market.getModel(modelId);
        assertFalse(m.active);
        assertGt(m.deactivatedAt, 0);
    }

    function test_Marketplace_DeactivateModel_OnlyCreator() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();

        vm.prank(attacker);
        vm.expectRevert(AIModelMarketplace.NotAuthorized.selector);
        market.deactivateModel(modelId);
    }

    function test_Marketplace_IsModelAvailable() public {
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();

        assertTrue(market.isModelAvailable(modelId));

        vm.prank(alice);
        market.deactivateModel(modelId);

        // Within grace period
        assertTrue(market.isModelAvailable(modelId));

        // After grace period
        vm.warp(block.timestamp + 25 hours);
        assertFalse(market.isModelAvailable(modelId));
    }

    function test_Marketplace_NextModelId() public {
        assertEq(market.nextModelId(), 0);

        vm.startPrank(alice);
        token.approve(address(market), 10 ether);
        market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();

        assertEq(market.nextModelId(), 1);
    }

    function test_Marketplace_SetTreasury() public {
        vm.startPrank(owner);
        market.setTreasury(address(0x1234));
        vm.warp(block.timestamp + market.TREASURY_TIMELOCK() + 1);
        market.applyTreasuryChange();
        vm.stopPrank();
        assertEq(market.treasury(), address(0x1234));
    }

    function test_Marketplace_SetTreasury_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(AIModelMarketplace.ZeroAddress.selector);
        market.setTreasury(address(0));
    }

    function test_Marketplace_SetValidatorPool() public {
        vm.startPrank(owner);
        market.setValidatorPool(address(0x5678));
        vm.warp(block.timestamp + market.TREASURY_TIMELOCK() + 1);
        market.applyValidatorPoolChange();
        vm.stopPrank();
        assertEq(market.validatorPool(), address(0x5678));
    }

    function test_Marketplace_SetFeeSplit() public {
        vm.prank(owner);
        market.setFeeSplit(200, 100); // 2% treasury, 1% validator
        assertEq(market.treasuryFeeBps(), 200);
        assertEq(market.validatorFeeBps(), 100);
    }

    function test_Marketplace_SetFeeSplit_ExceedsMax() public {
        vm.prank(owner);
        vm.expectRevert(AIModelMarketplace.FeesTooHigh.selector);
        market.setFeeSplit(600, 500); // 6% + 5% = 11% > 10% max
    }

    function test_Marketplace_Paused() public {
        vm.prank(owner);
        market.pause();

        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        vm.expectRevert();
        market.registerModel(1 ether, 7000, "ipfs://m");
        vm.stopPrank();
    }

    // ===================================================================
    // INTEGRATION TESTS
    // ===================================================================

    function test_FullFlow_AgentRegister_ChannelOpen_Pay_Settle() public {
        // 1. Alice registers agent
        vm.prank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "TradingBot"));
        registry.registerAgent(agentId, "ipfs://trading-bot", 1 ether, 100 ether);

        // 2. Alice opens payment channel with Bob
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 100 ether);
        bytes32 cid = channel.openChannel(bob, 1, 100 ether, 0);
        vm.stopPrank();

        // 3. Bob closes channel with signed ticket
        bytes32 structHash = keccak256(
            abi.encode(channel.TICKET_TYPEHASH(), cid, 50 ether, uint256(1))
        );
        bytes32 digest = channel.domainSeparator();
        bytes32 fullDigest = keccak256(
            abi.encodePacked("\x19\x01", digest, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, fullDigest);

        uint256 bobBalBefore = token.balanceOf(bob);
        vm.prank(bob);
        channel.closeChannel(cid, 50 ether, 1, abi.encodePacked(r, s, v));

        // Bob received payment
        assertGt(token.balanceOf(bob), bobBalBefore);

        // 4. Alice records spend (must respect maxPerTx = 1 ether)
        for (uint256 i = 0; i < 50; i++) {
            registry.checkAndRecordSpend(agentId, 1 ether);
        }

        // 5. Rolling window tracks spend
        uint256 totalSpend = registry.getRolling24hSpend(agentId);
        assertEq(totalSpend, 50 ether);
    }

    function test_FullFlow_ModelRegister_Pay() public {
        // 1. Alice registers model
        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        uint256 modelId = market.registerModel(0.1 ether, 7000, "ipfs://llama-8b");
        vm.stopPrank();

        // 2. Bob pays for inference
        uint256 aliceBalBefore = token.balanceOf(alice);
        uint256 bobBalBefore = token.balanceOf(bob);

        vm.startPrank(bob);
        token.approve(address(market), 0.1 ether);
        market.payForInference(modelId, 0.1 ether);
        vm.stopPrank();

        // Alice earned royalty
        assertGt(token.balanceOf(alice), aliceBalBefore);

        // Bob paid
        assertLt(token.balanceOf(bob), bobBalBefore);

        // Model stats updated
        AIModelMarketplace.Model memory m = market.getModel(modelId);
        assertEq(m.totalCalls, 1);
        assertGt(m.totalEarned, 0);
    }

    // ===================================================================
    // FUZZ TESTS
    // ===================================================================

    function testFuzz_TokenTransfer(uint256 amount) public {
        amount = bound(amount, 1, token.balanceOf(alice));

        uint256 aliceBalBefore = token.balanceOf(alice);
        uint256 bobBalBefore = token.balanceOf(bob);

        vm.prank(alice);
        token.transfer(bob, amount);

        assertEq(token.balanceOf(alice), aliceBalBefore - amount);
        assertEq(token.balanceOf(bob), bobBalBefore + amount);
    }

    function testFuzz_RegisterAgent(uint128 maxPerTx, uint128 maxPerDay) public {
        // Ensure valid policy: maxPerTx <= maxPerDay, both > 0
        maxPerTx = uint128(bound(maxPerTx, 1 ether, 100 ether));
        maxPerDay = uint128(bound(maxPerDay, maxPerTx, 1000 ether));

        vm.startPrank(alice);
        bytes32 agentId = keccak256(abi.encode(alice, "FuzzBot"));
        registry.registerAgent(agentId, "ipfs://m", maxPerTx, maxPerDay);
        vm.stopPrank();

        (, , , , , , bool active) = registry.agents(agentId);
        assertTrue(active);
    }

    function testFuzz_OpenChannel(uint256 deposit) public {
        deposit = bound(deposit, 0.01 ether, token.balanceOf(alice));

        vm.startPrank(alice);
        token.approve(address(channel), deposit);
        bytes32 cid = channel.openChannel(bob, uint64(deposit), deposit, 0);
        vm.stopPrank();

        (, , uint256 actualDeposit, , , , , ) = channel.channels(cid);
        assertEq(actualDeposit, deposit);
    }


    // ===================================================================
    // Missing branch / edge coverage boost
    // ===================================================================
    function test_Registry_DeactivateAgent_NotOwnerAndNotAgentOwner() public {
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        vm.startPrank(alice);
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert();
        registry.deactivateAgent(agentId);
        vm.stopPrank();
    }

    function test_Registry_AdjustReputation_AgentNotFound() public {
        vm.startPrank(oracle);
        vm.expectRevert();
        registry.adjustReputation(keccak256("missing"), 100);
        vm.stopPrank();
    }

    function test_Registry_CheckAndRecordSpend_PausedReverts() public {
        bytes32 agentId = keccak256(abi.encode(alice, "Bot"));
        vm.startPrank(alice);
        registry.registerAgent(agentId, "ipfs://m", 1 ether, 10 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        registry.pause();
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        registry.checkAndRecordSpend(agentId, 0.1 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        registry.unpause();
        vm.stopPrank();
    }

    function test_Registry_RegisterAgent_PausedReverts() public {
        vm.startPrank(owner);
        registry.pause();
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert();
        registry.registerAgent(keccak256("paused"), "ipfs://m", 1 ether, 10 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        registry.unpause();
        vm.stopPrank();
    }

    function test_Marketplace_RegisterModel_WhenPaused() public {
        vm.startPrank(owner);
        market.pause();
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(market), 1 ether);
        vm.expectRevert();
        market.registerModel(0.1 ether, 7000, "ipfs://m");
        vm.stopPrank();

        vm.startPrank(owner);
        market.unpause();
        vm.stopPrank();
    }

    function test_Marketplace_PayForInference_GraceExpired() public {
        vm.startPrank(alice);
        token.approve(address(market), 10 ether);
        uint256 modelId = market.registerModel(0.5 ether, 8000, "ipfs://m");
        vm.stopPrank();

        vm.startPrank(owner);
        market.deactivateModel(modelId);
        vm.stopPrank();

        vm.warp(block.timestamp + 25 hours + 1);

        vm.startPrank(bob);
        vm.expectRevert(AIModelMarketplace.ModelUnavailable.selector);
        market.payForInference(modelId, 1 ether);
        vm.stopPrank();
    }

    function test_Marketplace_ApplyValidatorPool_TimelockActive() public {
        vm.startPrank(owner);
        market.setValidatorPool(address(0xDead));
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert();
        market.applyValidatorPoolChange();
        vm.stopPrank();
    }

    function test_Marketplace_ApplyTreasury_TimelockActive() public {
        vm.startPrank(owner);
        market.setTreasury(address(0xFeed));
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert();
        market.applyTreasuryChange();
        vm.stopPrank();
    }

    function test_Channel_Close_NotPayee() public {
        vm.startPrank(alice);
        token.approve(address(channel), 1 ether);
        bytes32 cid = channel.openChannel(bob, 1, 1 ether, uint64(7 days));
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(AIPaymentChannel.NotPayee.selector);
        channel.closeChannel(cid, 0.5 ether, 0, "0x");
        vm.stopPrank();
    }

    function test_Channel_InitiateForceClose_NotOpen() public {
        vm.startPrank(aliceSigner);
        token.approve(address(channel), 1 ether);
        bytes32 cid = channel.openChannel(bob, 1, 1 ether, uint64(7 days));
        vm.stopPrank();

        // bob (payee) closes with aliceSigner's (payer) signature
        vm.startPrank(bob);
        bytes32 structHash = keccak256(abi.encode(channel.TICKET_TYPEHASH(), cid, 0.3 ether, uint256(0)));
        bytes32 digest = channel.domainSeparator();
        bytes32 fullDigest = keccak256(abi.encodePacked("\x19\x01", digest, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, fullDigest);
        bytes memory sig = abi.encodePacked(r, s, v);
        channel.closeChannel(cid, 0.3 ether, 0, sig);
        vm.stopPrank();

        vm.startPrank(aliceSigner);
        vm.expectRevert("Channel: not open");
        channel.initiateForceClose(cid);
        vm.stopPrank();
    }

    function test_Channel_ExecuteForceClose_NotAfterTimeout() public {
        vm.startPrank(alice);
        token.approve(address(channel), 1 ether);
        bytes32 cid = channel.openChannel(bob, 1, 1 ether, uint64(7 days));
        vm.stopPrank();

        vm.startPrank(alice);
        channel.initiateForceClose(cid);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(AIPaymentChannel.TimeoutActive.selector);
        channel.executeForceClose(cid);
        vm.stopPrank();
    }

    function test_Channel_Open_WhenPaused() public {
        vm.startPrank(owner);
        channel.pause();
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(channel), 1 ether);
        vm.expectRevert();
        channel.openChannel(bob, 2, 1 ether, uint64(7 days));
        vm.stopPrank();

        vm.startPrank(owner);
        channel.unpause();
        vm.stopPrank();
    }

    function test_Token_BridgeBurn_Paused() public {
        // Set a valid bridge via timelock
        vm.startPrank(owner);
        token.queueBridgeChange(address(this));
        vm.warp(block.timestamp + 49 hours);
        token.applyBridgeChange();
        vm.stopPrank();

        vm.startPrank(owner);
        token.pause();
        vm.stopPrank();

        vm.startPrank(address(this));
        vm.expectRevert();
        token.bridgeBurn(alice, 1 ether);
        vm.stopPrank();

        vm.startPrank(owner);
        token.unpause();
        vm.stopPrank();
    }

    function test_Token_Transfer_AmountExceedsBalance() public {
        vm.startPrank(alice);
        token.approve(address(this), type(uint256).max);
        vm.expectRevert();
        token.transfer(bob, type(uint256).max);
        vm.stopPrank();
    }

    function test_Token_CollectAITax_AmountZero() public {
        vm.startPrank(alice);
        token.transfer(aliceSigner, 1 ether);
        token.approve(address(channel), 1 ether);
        vm.stopPrank();

        vm.startPrank(aliceSigner);
        vm.expectRevert();
        token.collectAITax(0);
        vm.stopPrank();
    }

    function test_Token_CollectAITax_BalanceInsufficient() public {
        vm.startPrank(aliceSigner);
        vm.expectRevert();
        token.collectAITax(1);
        vm.stopPrank();
    }
}
