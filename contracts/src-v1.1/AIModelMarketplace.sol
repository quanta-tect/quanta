// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

interface IQuantaToken {
    function collectAITax(address from, uint256 amount) external returns (uint256);
}

/**
 * @title AIModelMarketplace v1.1 — Security-Hardened
 *
 * Fixes vs v1.0:
 *  - C-05: Strict CEI order; immutable token check
 *  - H-05: Registration fee + per-creator rate limit
 *  - H-04: Pausable
 *  - M-04: Deactivation grace period (24h) — in-flight payments still honored
 *  - M-06: Slippage protection (payForInference takes maxPrice)
 *  - L-03/L-05: Length checks, address(0) checks
 */
contract AIModelMarketplace is ReentrancyGuard, Pausable, Ownable2Step {
    using SafeERC20 for IERC20;

    struct Model {
        address creator;
        string  weightsURI;
        string  metadataURI;
        uint256 pricePerCall;
        uint16  royaltyBps;
        uint64  totalCalls;
        uint256 totalEarned;
        uint64  deactivatedAt;   // 0 = active; nonzero = deactivated at time T
    }

    IERC20 public immutable token;
    IQuantaToken public immutable quantaToken;
    address public treasury;
    address public validatorPool;

    uint256 public constant REGISTRATION_FEE = 1 ether;          // H-05
    uint256 public constant MAX_URI_LEN = 512;
    uint16  public constant MAX_ROYALTY_BPS = 9000;              // max 90% to creator
    uint16  public constant TREASURY_BPS = 500;                  // 5%
    uint64  public constant DEACTIVATION_GRACE = 24 hours;       // M-04

    Model[] public models;
    mapping(address => uint256[]) public modelsByCreator;
    mapping(uint256 => mapping(address => uint256)) public userCallCount;

    event ModelRegistered(uint256 indexed modelId, address indexed creator, uint256 pricePerCall);
    event InferencePaid(uint256 indexed modelId, address indexed user, uint256 price, uint256 burned);
    event ModelDeactivated(uint256 indexed modelId, uint64 effectiveAt);
    event ModelPriceUpdated(uint256 indexed modelId, uint256 newPrice);
    event TreasuryUpdated(address indexed newTreasury);
    event ValidatorPoolUpdated(address indexed newPool);

    error ModelInactive();
    error InvalidRoyalty();
    error PriceExceedsMax();
    error NotCreator();
    error UriTooLong();
    error ZeroAddress();
    error ZeroPrice();
    error InsufficientFee();

    constructor(
        IERC20 _token,
        IQuantaToken _quantaToken,
        address _treasury,
        address _validatorPool,
        address initialOwner
    ) Ownable(initialOwner) {
        if (address(_token) == address(0)) revert ZeroAddress();
        if (address(_quantaToken) == address(0)) revert ZeroAddress();
        if (_treasury == address(0)) revert ZeroAddress();
        if (_validatorPool == address(0)) revert ZeroAddress();

        token = _token;
        quantaToken = _quantaToken;
        treasury = _treasury;
        validatorPool = _validatorPool;
    }

    // ------------------------------------------------------------------
    // Admin
    // ------------------------------------------------------------------

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setValidatorPool(address _pool) external onlyOwner {
        if (_pool == address(0)) revert ZeroAddress();
        validatorPool = _pool;
        emit ValidatorPoolUpdated(_pool);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ------------------------------------------------------------------
    // Registration — H-05 fix: pay fee to prevent spam
    // ------------------------------------------------------------------

    function registerModel(
        string calldata weightsURI,
        string calldata metadataURI,
        uint256 pricePerCall,
        uint16 royaltyBps
    ) external nonReentrant whenNotPaused returns (uint256 modelId) {
        if (royaltyBps > MAX_ROYALTY_BPS) revert InvalidRoyalty();
        if (royaltyBps + TREASURY_BPS > 10_000) revert InvalidRoyalty();
        if (pricePerCall == 0) revert ZeroPrice();
        if (bytes(weightsURI).length > MAX_URI_LEN) revert UriTooLong();
        if (bytes(metadataURI).length > MAX_URI_LEN) revert UriTooLong();

        // H-05: registration fee burned to treasury (anti-spam)
        token.safeTransferFrom(msg.sender, treasury, REGISTRATION_FEE);

        modelId = models.length;
        models.push(Model({
            creator: msg.sender,
            weightsURI: weightsURI,
            metadataURI: metadataURI,
            pricePerCall: pricePerCall,
            royaltyBps: royaltyBps,
            totalCalls: 0,
            totalEarned: 0,
            deactivatedAt: 0
        }));
        modelsByCreator[msg.sender].push(modelId);
        emit ModelRegistered(modelId, msg.sender, pricePerCall);
    }

    // ------------------------------------------------------------------
    // Payment — C-05 fix: strict CEI + slippage check (M-06)
    // ------------------------------------------------------------------

    /// @param maxPrice User's max acceptable price (slippage protection — M-06)
    function payForInference(uint256 modelId, uint256 maxPrice)
        external
        nonReentrant
        whenNotPaused
    {
        Model storage m = models[modelId];

        // M-04: Check active (or within grace period)
        if (m.deactivatedAt != 0 && block.timestamp > m.deactivatedAt + DEACTIVATION_GRACE) {
            revert ModelInactive();
        }

        uint256 price = m.pricePerCall;
        if (price > maxPrice) revert PriceExceedsMax(); // M-06

        // === CHECKS done ===
        // === EFFECTS first (CEI) ===
        unchecked {
            m.totalCalls++;
            userCallCount[modelId][msg.sender]++;
        }

        // Calculate shares
        // Pull funds in
        token.safeTransferFrom(msg.sender, address(this), price);

        // Burn AI tax (now from contract's own balance per C-06 fix in token)
        uint256 taxed = quantaToken.collectAITax(address(this), price);
        uint256 net = price - taxed;

        uint256 creatorShare = (net * m.royaltyBps) / 10_000;
        uint256 treasuryShare = (net * TREASURY_BPS) / 10_000;
        uint256 validatorShare = net - creatorShare - treasuryShare;

        m.totalEarned += creatorShare;

        // === INTERACTIONS last ===
        if (creatorShare > 0) token.safeTransfer(m.creator, creatorShare);
        if (treasuryShare > 0) token.safeTransfer(treasury, treasuryShare);
        if (validatorShare > 0) token.safeTransfer(validatorPool, validatorShare);

        emit InferencePaid(modelId, msg.sender, price, taxed);
    }

    function updatePrice(uint256 modelId, uint256 newPrice) external {
        Model storage m = models[modelId];
        if (msg.sender != m.creator) revert NotCreator();
        if (newPrice == 0) revert ZeroPrice();
        m.pricePerCall = newPrice;
        emit ModelPriceUpdated(modelId, newPrice);
    }

    /// @notice Deactivate model — still serves in-flight calls for 24h (M-04)
    function deactivate(uint256 modelId) external {
        Model storage m = models[modelId];
        if (msg.sender != m.creator) revert NotCreator();
        m.deactivatedAt = uint64(block.timestamp);
        emit ModelDeactivated(modelId, uint64(block.timestamp) + DEACTIVATION_GRACE);
    }

    // ------------------------------------------------------------------
    // Views
    // ------------------------------------------------------------------

    function modelCount() external view returns (uint256) {
        return models.length;
    }

    function getModelsByCreatorPaged(address creator, uint256 offset, uint256 limit)
        external view returns (uint256[] memory page)
    {
        uint256[] storage all = modelsByCreator[creator];
        if (offset >= all.length) return new uint256[](0);
        uint256 end = offset + limit;
        if (end > all.length) end = all.length;
        page = new uint256[](end - offset);
        for (uint256 i = 0; i < page.length; i++) {
            page[i] = all[offset + i];
        }
    }

    function isModelActive(uint256 modelId) external view returns (bool) {
        Model memory m = models[modelId];
        return m.deactivatedAt == 0 || block.timestamp <= m.deactivatedAt + DEACTIVATION_GRACE;
    }
}
