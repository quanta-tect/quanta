// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * ERC1155 Airdrop – multi-tokenId claim, Merkle + EIP-2771
 */
contract ERC1155MerkleAirdrop is ERC1155, Ownable2Step, ERC2771Context, ReentrancyGuard {
    using BitMaps for BitMaps.BitMap;

    bytes32 public merkleRoot;
    bool public paused;
    mapping(address => bool) public blacklist;
    BitMaps.BitMap private _claimed;

    event Claimed1155(address indexed account, uint256 indexed index, uint256 id, uint256 amount);
    event MerkleRootUpdated(bytes32 root);

    error Paused();
    error Blacklisted();
    error AlreadyClaimed();
    error InvalidProof();

    constructor(
        string memory uri_,
        bytes32 merkleRoot_,
        address trustedForwarder_
    ) ERC1155(uri_) Ownable(msg.sender) ERC2771Context(trustedForwarder_) {
        merkleRoot = merkleRoot_;
    }

    function claim(
        uint256 index,
        address account,
        uint256 id,
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant {
        if (paused) revert Paused();
        if (blacklist[_msgSender()] || blacklist[account]) revert Blacklisted();
        if (_claimed.get(index)) revert AlreadyClaimed();

        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(index, account, id, amount))));
        if (!MerkleProof.verify(proof, merkleRoot, node)) revert InvalidProof();

        _claimed.set(index);
        _mint(account, id, amount, "");
        emit Claimed1155(account, index, id, amount);
    }

    function isClaimed(uint256 index) external view returns (bool) {
        return _claimed.get(index);
    }

    function setMerkleRoot(bytes32 r) external onlyOwner {
        merkleRoot = r;
        emit MerkleRootUpdated(r);
    }
    function setPaused(bool p) external onlyOwner { paused = p; }
    function setBlacklist(address a, bool b) external onlyOwner { blacklist[a] = b; }
    function setURI(string memory newuri) external onlyOwner { _setURI(newuri); }

    function _msgSender() internal view override(ERC2771Context, Context) returns (address) { return ERC2771Context._msgSender(); }
    function _msgData() internal view override(ERC2771Context, Context) returns (bytes calldata) { return ERC2771Context._msgData(); }
    function _contextSuffixLength() internal view override(ERC2771Context, Context) returns (uint256) { return ERC2771Context._contextSuffixLength(); }
}
