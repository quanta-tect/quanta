// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IQuantaToken} from "./interfaces/IQuantaToken.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
/**
 * @title AIModelMarketplace
 * @notice On-chain marketplace for AI models, datasets, compute.
 *
 * Creator registers model with:
 *   - weightsHash (IPFS/Arweave URI of weights)
 *   - pricePerCall (QTA per inference)
 *   - royaltyBps (% creator giữ lại)
 *
 * Users (human or AI agent) gọi `payForInference()` để mua quyền dùng.
 * Phí auto chia:
 *   - 70% → creator (royalty)
 *   - 25% → validator pool (compute provider)
 *   - 5%  → treasury
 *   - + AI tax → burn
 */
contract AIModelMarketplace is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Model {
        address creator;
        string  weightsURI;      // IPFS / Arweave
        string  metadataURI;     // Model card, capabilities
        uint256 pricePerCall;
        uint16  royaltyBps;      // 7000 = 70%
        uint64  totalCalls;
        uint256 totalEarned;
        bool    active;
    }

    IERC20 public immutable token;
    IQuantaToken public immutable quantaToken;
    address public treasury;
    address public validatorPool;

    Model[] public models;
    mapping(address => uint256[]) public modelsByCreator;
    mapping(uint256 => mapping(address => uint256)) public userCallCount;

    event ModelRegistered(uint256 indexed modelId, address indexed creator, uint256 pricePerCall);
    event InferencePaid(uint256 indexed modelId, address indexed user, uint256 amount);
    event ModelUpdated(uint256 indexed modelId);

    error ModelInactive();
    error InvalidRoyalty();

    constructor(IERC20 _token, IQuantaToken _quantaToken, address _treasury, address _validatorPool) {
        token = _token;
        quantaToken = _quantaToken;
        treasury = _treasury;
        validatorPool = _validatorPool;
    }

    function registerModel(
        string calldata weightsURI,
        string calldata metadataURI,
        uint256 pricePerCall,
        uint16 royaltyBps
    ) external returns (uint256 modelId) {
        if (royaltyBps > 9000) revert InvalidRoyalty(); // max 90% to creator

        modelId = models.length;
        models.push(Model({
            creator: msg.sender,
            weightsURI: weightsURI,
            metadataURI: metadataURI,
            pricePerCall: pricePerCall,
            royaltyBps: royaltyBps,
            totalCalls: 0,
            totalEarned: 0,
            active: true
        }));
        modelsByCreator[msg.sender].push(modelId);
        emit ModelRegistered(modelId, msg.sender, pricePerCall);
    }

    function payForInference(uint256 modelId) external nonReentrant {
        Model storage m = models[modelId];
        if (!m.active) revert ModelInactive();

        uint256 price = m.pricePerCall;
        token.safeTransferFrom(msg.sender, address(this), price);

        // Burn AI tax first
        uint256 taxed = quantaToken.collectAITax(address(this), price);
        uint256 net = price - taxed;

        uint256 creatorShare = (net * m.royaltyBps) / 10_000;
        uint256 treasuryShare = (net * 500) / 10_000; // 5%
        uint256 validatorShare = net - creatorShare - treasuryShare;

        token.safeTransfer(m.creator, creatorShare);
        token.safeTransfer(treasury, treasuryShare);
        token.safeTransfer(validatorPool, validatorShare);

        unchecked {
            m.totalCalls++;
            m.totalEarned += creatorShare;
            userCallCount[modelId][msg.sender]++;
        }

        emit InferencePaid(modelId, msg.sender, price);
    }

    function updatePrice(uint256 modelId, uint256 newPrice) external {
        Model storage m = models[modelId];
        require(msg.sender == m.creator, "not creator");
        m.pricePerCall = newPrice;
        emit ModelUpdated(modelId);
    }

    function deactivate(uint256 modelId) external {
        Model storage m = models[modelId];
        require(msg.sender == m.creator, "not creator");
        m.active = false;
        emit ModelUpdated(modelId);
    }

    function modelCount() external view returns (uint256) {
        return models.length;
    }

    function getModelsByCreator(address creator) external view returns (uint256[] memory) {
        return modelsByCreator[creator];
    }
}
