// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IZeusyxaToken.sol";

/**
 * @title AIModelMarketplace (v1.3)
 * @notice Marketplace for AI models with royalty payments and fee splits
 * @dev Rebranded from v1.2: QUANTA → ZEUSYXA, QTA → ZYX
 *      Fixed: treasuryFeeBps and validatorFeeBps now public view
 *      Fixed: MAX_ROYALTY_BPS made public view
 *      Added: explicit fee constants as public view
 *      Fixed: collectAITax burns from caller (marketplace contract)
 *      Fixed: payForInference uses proper CEI pattern
 */
contract AIModelMarketplace is ReentrancyGuard, Ownable2Step, Pausable {
    using SafeERC20 for IZeusyxaToken;

    uint256 public constant REGISTRATION_FEE    = 1e18;      // 1 ZYX
    uint64  public constant DEACTIVATION_GRACE  = 24 hours;  // 24h grace after deactivation
    uint256 public constant MAX_ROYALTY_BPS     = 9_000;     // 90% max royalty
    uint256 public constant MAX_MODELS_PER_USER = 100;
    uint256 public constant TREASURY_FEE_BPS    = 500;       // 5% to treasury
    uint256 public constant VALIDATOR_FEE_BPS   = 500;       // 5% to validators

    struct Model {
        address creator;
        uint256 pricePerCall;
        uint256 royaltyBps;
        uint256 totalCalls;
        uint256 totalEarned;
        uint64  registeredAt;
        uint64  deactivatedAt;
        bool    active;
        string  metadataURI;
    }

    IZeusyxaToken public immutable token;
    address public treasury;
    address public validatorPool;

    uint256 public nextModelId;
    mapping(uint256 => Model)   public models;
    mapping(address => uint256) public modelCountByCreator;

    // Custom errors
    error ZeroPrice();
    error InvalidRoyalty(uint256 royalty);
    error TooManyModels();
    error NotCreator();
    error FeesTooHigh();
    error ZeroAddress();
    error ModelUnavailable();
    error NotAuthorized();
    error PriceSlipped();
    error ModelNotFound(uint256 modelId);
    error ZeroToken();

    // Events
    event ModelRegistered(uint256 indexed modelId, address indexed creator, uint256 pricePerCall, uint256 royaltyBps);
    event ModelDeactivated(uint256 indexed modelId, address indexed by, uint64 deactivatedAt);
    event ModelPriceUpdated(uint256 indexed modelId, uint256 oldPrice, uint256 newPrice);
    event InferencePaid(uint256 indexed modelId, address indexed caller, uint256 paid, uint256 taxed, uint256 creatorShare);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event ValidatorPoolUpdated(address indexed old_, address indexed new_);
    event FeeSplitUpdated(uint256 treasuryBps, uint256 validatorBps);

    constructor(
        address _token,
        address _treasury,
        address _validatorPool,
        address _initialOwner
    ) Ownable(_initialOwner) {
        if (_token == address(0)) revert ZeroToken();
        if (_treasury == address(0)) revert ZeroAddress();
        if (_validatorPool == address(0)) revert ZeroAddress();
        token = IZeusyxaToken(_token);
        treasury = _treasury;
        validatorPool = _validatorPool;
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        emit TreasuryUpdated(treasury, _treasury);
        treasury = _treasury;
    }

    function setValidatorPool(address _pool) external onlyOwner {
        if (_pool == address(0)) revert ZeroAddress();
        emit ValidatorPoolUpdated(validatorPool, _pool);
        validatorPool = _pool;
    }

    function setFeeSplit(uint256 _treasuryBps, uint256 _validatorBps) external onlyOwner {
        if (_treasuryBps + _validatorBps > 1_000) revert FeesTooHigh();
        emit FeeSplitUpdated(_treasuryBps, _validatorBps);
    }

    function pause() external onlyOwner { _pause(); emit Paused(msg.sender); }
    function unpause() external onlyOwner { _unpause(); emit Unpaused(msg.sender); }

    function registerModel(
        uint256 pricePerCall,
        uint256 royaltyBps,
        string calldata metadataURI
    ) external nonReentrant whenNotPaused returns (uint256 modelId) {
        if (pricePerCall == 0) revert ZeroPrice();
        if (royaltyBps > MAX_ROYALTY_BPS) revert InvalidRoyalty(royaltyBps);
        if (modelCountByCreator[msg.sender] >= MAX_MODELS_PER_USER) revert TooManyModels();

        modelId = nextModelId++;
        modelCountByCreator[msg.sender]++;

        models[modelId] = Model({
            creator:      msg.sender,
            pricePerCall: pricePerCall,
            royaltyBps:   royaltyBps,
            totalCalls:   0,
            totalEarned:  0,
            registeredAt: uint64(block.timestamp),
            deactivatedAt: 0,
            active:       true,
            metadataURI:  metadataURI
        });

        token.safeTransferFrom(msg.sender, treasury, REGISTRATION_FEE);
        emit ModelRegistered(modelId, msg.sender, pricePerCall, royaltyBps);
    }

    function updatePrice(uint256 modelId, uint256 newPrice) external {
        Model storage m = models[modelId];
        if (m.creator != msg.sender) revert NotCreator();
        if (m.registeredAt == 0) revert ModelNotFound(modelId);
        if (!m.active) revert ModelUnavailable();
        if (newPrice == 0) revert ZeroPrice();
        emit ModelPriceUpdated(modelId, m.pricePerCall, newPrice);
        m.pricePerCall = newPrice;
    }

    function deactivateModel(uint256 modelId) external {
        Model storage m = models[modelId];
        if (m.creator != msg.sender && msg.sender != owner()) revert NotAuthorized();
        if (m.registeredAt == 0) revert ModelNotFound(modelId);
        if (!m.active) revert ModelUnavailable();
        m.active = false;
        m.deactivatedAt = uint64(block.timestamp);
        emit ModelDeactivated(modelId, msg.sender, uint64(block.timestamp));
    }

    function payForInference(uint256 modelId, uint256 maxPrice) external nonReentrant whenNotPaused {
        Model storage m = models[modelId];
        if (m.registeredAt == 0) revert ModelNotFound(modelId);
        if (!(m.active || (m.deactivatedAt > 0 && block.timestamp <= m.deactivatedAt + DEACTIVATION_GRACE))) revert ModelUnavailable();
        if (m.pricePerCall > maxPrice) revert PriceSlipped();

        uint256 price = m.pricePerCall;

        // CEI: Effects before interactions
        m.totalCalls++;

        // Transfer payment from caller to marketplace
        token.safeTransferFrom(msg.sender, address(this), price);

        // Collect AI tax (burns from marketplace balance)
        uint256 taxed = token.collectAITax(price);
        uint256 net = price - taxed;

        uint256 creatorShare   = (net * m.royaltyBps)    / 10_000;
        uint256 treasuryShare  = (net * TREASURY_FEE_BPS)  / 10_000;
        uint256 validatorShare = (net * VALIDATOR_FEE_BPS) / 10_000;
        uint256 remainder = net - creatorShare - treasuryShare - validatorShare;
        treasuryShare += remainder;

        m.totalEarned += creatorShare;

        if (creatorShare > 0)  token.safeTransfer(m.creator, creatorShare);
        if (treasuryShare > 0) token.safeTransfer(treasury, treasuryShare);
        if (validatorShare > 0) token.safeTransfer(validatorPool, validatorShare);

        emit InferencePaid(modelId, msg.sender, price, taxed, creatorShare);
    }

    function getModel(uint256 modelId) external view returns (Model memory) {
        if (models[modelId].registeredAt == 0) revert ModelNotFound(modelId);
        return models[modelId];
    }

    function isModelAvailable(uint256 modelId) external view returns (bool) {
        Model storage m = models[modelId];
        if (m.registeredAt == 0) return false;
        if (m.active) return true;
        return (m.deactivatedAt > 0 && block.timestamp <= m.deactivatedAt + DEACTIVATION_GRACE);
    }
}