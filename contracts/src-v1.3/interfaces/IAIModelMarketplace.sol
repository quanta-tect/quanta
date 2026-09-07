// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAIModelMarketplace {
    function REGISTRATION_FEE() external view returns (uint256);
    function DEACTIVATION_GRACE() external view returns (uint64);
    function MAX_ROYALTY_BPS() external view returns (uint256);
    function MAX_MODELS_PER_USER() external view returns (uint256);
    function TREASURY_FEE_BPS() external view returns (uint256);
    function VALIDATOR_FEE_BPS() external view returns (uint256);

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

    function token() external view returns (address);
    function treasury() external view returns (address);
    function validatorPool() external view returns (address);
    function nextModelId() external view returns (uint256);
    function models(uint256) external view returns (Model memory);
    function modelCountByCreator(address) external view returns (uint256);
    function registerModel(uint256 pricePerCall, uint256 royaltyBps, string calldata metadataURI) external returns (uint256);
    function updatePrice(uint256 modelId, uint256 newPrice) external;
    function deactivateModel(uint256 modelId) external;
    function payForInference(uint256 modelId, uint256 maxPrice) external;
    function getModel(uint256 modelId) external view returns (Model memory);
    function isModelAvailable(uint256 modelId) external view returns (bool);
    function setTreasury(address _treasury) external;
    function setValidatorPool(address _pool) external;
    function setFeeSplit(uint256 _treasuryBps, uint256 _validatorBps) external;
    function pause() external;
    function unpause() external;
}