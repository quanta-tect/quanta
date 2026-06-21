// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface IQuantaToken is IERC20 {
    function collectAITax(uint256 amount) external returns (uint256 taxed);
}

contract AIModelMarketplace is ReentrancyGuard, Ownable2Step, Pausable {
    using SafeERC20 for IQuantaToken;

    uint256 public constant REGISTRATION_FEE    = 1e18;
    uint64  public constant DEACTIVATION_GRACE  = 24 hours;
    uint256 public constant MAX_ROYALTY_BPS     = 9_000;
    uint256 public constant MAX_MODELS_PER_USER = 100;

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

    IQuantaToken public immutable token;
    address public treasury;
    address public validatorPool;

    uint256 public nextModelId;
    mapping(uint256 => Model)   public models;
    mapping(address => uint256) public modelCountByCreator;

    uint256 public treasuryFeeBps   = 150;
    uint256 public validatorFeeBps  = 150;

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
        require(_token != address(0), "Market: zero token");
        require(_treasury != address(0), "Market: zero treasury");
        require(_validatorPool != address(0), "Market: zero validator");
        token = IQuantaToken(_token);
        treasury = _treasury;
        validatorPool = _validatorPool;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Market: zero address");
        emit TreasuryUpdated(treasury, _treasury);
        treasury = _treasury;
    }

    function setValidatorPool(address _pool) external onlyOwner {
        require(_pool != address(0), "Market: zero address");
        emit ValidatorPoolUpdated(validatorPool, _pool);
        validatorPool = _pool;
    }

    function setFeeSplit(uint256 _treasuryBps, uint256 _validatorBps) external onlyOwner {
        require(_treasuryBps + _validatorBps <= 1_000, "Market: fees too high");
        treasuryFeeBps = _treasuryBps;
        validatorFeeBps = _validatorBps;
        emit FeeSplitUpdated(_treasuryBps, _validatorBps);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function registerModel(
        uint256 pricePerCall,
        uint256 royaltyBps,
        string calldata metadataURI
    ) external nonReentrant whenNotPaused returns (uint256 modelId) {
        require(pricePerCall > 0, "Market: zero price");
        require(royaltyBps <= MAX_ROYALTY_BPS, "Market: royalty too high");
        require(modelCountByCreator[msg.sender] < MAX_MODELS_PER_USER, "Market: too many models");

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
        require(m.creator == msg.sender, "Market: not creator");
        require(m.active, "Market: inactive");
        require(newPrice > 0, "Market: zero price");
        emit ModelPriceUpdated(modelId, m.pricePerCall, newPrice);
        m.pricePerCall = newPrice;
    }

    function deactivateModel(uint256 modelId) external {
        Model storage m = models[modelId];
        require(m.creator == msg.sender || msg.sender == owner(), "Market: not authorized");
        require(m.active, "Market: already inactive");
        m.active = false;
        m.deactivatedAt = uint64(block.timestamp);
        emit ModelDeactivated(modelId, msg.sender, uint64(block.timestamp));
    }

    function payForInference(uint256 modelId, uint256 maxPrice) external nonReentrant whenNotPaused {
        Model storage m = models[modelId];
        require(m.registeredAt != 0, "Market: model not found");
        require(m.active || (m.deactivatedAt > 0 && block.timestamp <= m.deactivatedAt + DEACTIVATION_GRACE), "Market: model unavailable");
        require(m.pricePerCall <= maxPrice, "Market: price slipped");

        uint256 price = m.pricePerCall;

        token.safeTransferFrom(msg.sender, address(this), price);

        uint256 taxed = token.collectAITax(price);
        uint256 net = price - taxed;

        uint256 creatorShare   = (net * m.royaltyBps)    / 10_000;
        uint256 treasuryShare  = (net * treasuryFeeBps)  / 10_000;
        uint256 validatorShare = (net * validatorFeeBps) / 10_000;
        uint256 remainder = net - creatorShare - treasuryShare - validatorShare;
        treasuryShare += remainder;

        m.totalCalls++;
        m.totalEarned += creatorShare;

        if (creatorShare > 0)  token.safeTransfer(m.creator, creatorShare);
        if (treasuryShare > 0) token.safeTransfer(treasury, treasuryShare);
        if (validatorShare > 0) token.safeTransfer(validatorPool, validatorShare);

        emit InferencePaid(modelId, msg.sender, price, taxed, creatorShare);
    }

    function getModel(uint256 modelId) external view returns (Model memory) {
        return models[modelId];
    }

    function isModelAvailable(uint256 modelId) external view returns (bool) {
        Model storage m = models[modelId];
        if (m.registeredAt == 0) return false;
        if (m.active) return true;
        return (m.deactivatedAt > 0 && block.timestamp <= m.deactivatedAt + DEACTIVATION_GRACE);
    }
}
