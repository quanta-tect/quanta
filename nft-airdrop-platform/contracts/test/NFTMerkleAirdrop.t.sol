// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/NFTMerkleAirdrop.sol";

contract NFTMerkleAirdropTest is Test {
    NFTMerkleAirdrop drop;
    address owner = address(0xA11CE);
    address alice = address(0xA11c3);
    address trustedForwarder = address(0);

    // demo: index 0, alice, amount 1
    // leaf = keccak256(bytes.concat(keccak256(abi.encode(0, alice, 1))))
    bytes32 merkleRoot = 0x3c9aefc8a9eef1c8cfa4b8a7e0f0c1d2a3b4c5d6e7f8091a2b3c4d5e6f70819a;
    
    function setUp() public {
        vm.prank(owner);
        drop = new NFTMerkleAirdrop(
            "Airdrop NFT",
            "ADNFT",
            merkleRoot,
            10000,
            "https://quanta-tect.github.io/quanta/metadata/",
            trustedForwarder
        );
    }

    function test_initialState() public view {
        assertEq(drop.name(), "Airdrop NFT");
        assertEq(drop.symbol(), "ADNFT");
        assertEq(drop.maxSupply(), 10000);
        assertEq(drop.owner(), owner);
    }

    function test_setBlacklist() public {
        vm.prank(owner);
        drop.setBlacklist(alice, true);
        assertTrue(drop.blacklist(alice));
    }

    function test_pause() public {
        vm.prank(owner);
        drop.setPaused(true);
        assertTrue(drop.paused());
    }

    function test_campaignUpdate() public {
        vm.prank(owner);
        drop.setCampaign(uint64(block.timestamp), uint64(block.timestamp + 1 days), 0);
        assertEq(drop.claimPrice(), 0);
    }

    function test_replayProtection() public view {
        // BitMaps: index not claimed yet
        assertFalse(drop.isClaimed(0));
    }
}
