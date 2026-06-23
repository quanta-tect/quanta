// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title NFTMerkleAirdrop
 * @notice ERC-721 airdrop / claim contract for the NFT Airdrop Platform job
 * - ERC721Enumerable, Ownable2Step
 * - Merkle whitelist claim
 * - Replay protection via BitMaps
 * - EIP-2771 gasless meta-tx support (OpenGSN / Biconomy)
 * - Campaign pause, blacklist, rate-limit hook
 * - SIWE-ready off-chain (EIP-712)
 *
 * Verified patterns: OpenZeppelin 5.0.2
 */
contract NFTMerkleAirdrop is ERC721Enumerable, Ownable2Step, ERC2771Context, EIP712 {
    using BitMaps for BitMaps.BitMap;

    bytes32 public merkleRoot;
    uint256 public claimPrice; // 0 for free airdrop
    uint64 public claimStart;
    uint64 public claimEnd;
    uint32 public maxSupply;
    string private _baseTokenURI;
    bool public paused;

    BitMaps.BitMap private _claimed;
    mapping(address => bool) public blacklist;
    mapping(address => uint64) public lastClaimAt;

    uint256 private _nextTokenId = 1;

    event Claimed(address indexed account, uint256 indexed index, uint256 tokenId);
    event MerkleRootUpdated(bytes32 root);
    event CampaignUpdated(uint64 start, uint64 end, uint256 price);
    event BlacklistUpdated(address account, bool blocked);

    error AirdropPaused();
    error NotInClaimWindow();
    error AlreadyClaimed();
    error InvalidProof();
    error Blacklisted();
    error RateLimited();
    error MaxSupplyReached();
    error IncorrectPayment();
    error WithdrawFailed();

    constructor(
        string memory name_,
        string memory symbol_,
        bytes32 merkleRoot_,
        uint32 maxSupply_,
        string memory baseURI_,
        address trustedForwarder_
    )
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        ERC2771Context(trustedForwarder_)
        EIP712(name_, "1")
    {
        merkleRoot = merkleRoot_;
        maxSupply = maxSupply_;
        _baseTokenURI = baseURI_;
        claimStart = uint64(block.timestamp);
        claimEnd = uint64(block.timestamp + 30 days);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
    {
        if (paused) revert AirdropPaused();
        if (block.timestamp < claimStart || block.timestamp > claimEnd) revert NotInClaimWindow();
        if (blacklist[_msgSender()] || blacklist[account]) revert Blacklisted();
        if (_claimed.get(index)) revert AlreadyClaimed();
        // simple 60s rate limit (anti-sybil / bot spam)
        if (block.timestamp < lastClaimAt[_msgSender()] + 60) revert RateLimited();

        // Verify: leaf = keccak256(bytes.concat(keccak256(abi.encode(index, account, amount))))
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(index, account, amount))));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        _claimed.set(index);

        uint256 totalCost = claimPrice * amount;
        if (msg.value != totalCost) revert IncorrectPayment();

        lastClaimAt[_msgSender()] = uint64(block.timestamp);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _nextTokenId++;
            if (tokenId > maxSupply) revert MaxSupplyReached();
            _safeMint(account, tokenId);
            emit Claimed(account, index, tokenId);
        }
    }

    function isClaimed(uint256 index) external view returns (bool) {
        return _claimed.get(index);
    }

    // --- Admin ---
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        emit MerkleRootUpdated(root);
    }

    function setCampaign(uint64 start, uint64 end, uint256 price) external onlyOwner {
        claimStart = start;
        claimEnd = end;
        claimPrice = price;
        emit CampaignUpdated(start, end, price);
    }

    function setPaused(bool p) external onlyOwner { paused = p; }
    
    function setBlacklist(address account, bool blocked) external onlyOwner {
        blacklist[account] = blocked;
        emit BlacklistUpdated(account, blocked);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    function withdraw(address payable to) external onlyOwner {
        (bool ok,) = to.call{value: address etherBalance()}("");
        if (!ok) revert WithdrawFailed();
    }

    function etherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Views ---
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- ERC2771 overrides ---
    function _msgSender() internal view override(ERC2771Context, Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(ERC2771Context, Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(ERC2771Context, Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}
