// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "forge-std/Test.sol";
import "../src-v1.2/QuantaToken.sol";
import "../src-v1.2/AIAgentRegistry.sol";
import "../src-v1.2/AIPaymentChannel.sol";
import "../src-v1.2/AIModelMarketplace.sol";

contract QuantaSecurityTests is Test {
    address owner = address(0x1);
    address alice = address(0x2);
    address bob = address(0x3);
    address treasury = address(0x6);
    address validator = address(0x7);

    QuantaToken qtk;
    AIAgentRegistry registry;
    AIPaymentChannel channel;
    AIModelMarketplace market;

    function setUp() public {
        vm.startPrank(owner);
        qtk = new QuantaToken(owner);
        registry = new AIAgentRegistry(owner);
        channel = new AIPaymentChannel(address(qtk), owner);
        market = new AIModelMarketplace(address(qtk), treasury, validator, owner);

        qtk.setAITaxCollector(address(channel), true);
        qtk.setAITaxCollector(address(market), true);

        qtk.queueBridgeChange(owner);
        vm.warp(block.timestamp + 48 hours + 1);
        qtk.applyBridgeChange();

        qtk.bridgeMint(alice, 10_000e18);
        qtk.bridgeMint(bob, 10_000e18);
        vm.stopPrank();
    }

    function test_BasicDeployment() public {
        assertEq(qtk.totalSupply(), 300_000_000e18);
    }
}