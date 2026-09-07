// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IAIAgentRegistry {
    function MAX_AGENTS_PER_OWNER() external view returns (uint256);
    function MAX_METADATA_LEN() external view returns (uint256);
    function MAX_REPUTATION() external view returns (uint256);
    function WINDOW_SLOTS() external view returns (uint32);
    function REPUTATION_ORACLE_ROLE() external view returns (bytes32);

    struct SpendingPolicy {
        uint256 maxPerTx;
        uint256 maxPerDay;
        bool    active;
    }

    struct RollingWindow {
        uint256[24] slots;
        uint8       cursor;
        uint40      slotTs;
    }

    struct Agent {
        address owner;
        uint256 reputation;
        SpendingPolicy policy;
        RollingWindow window;
        string  metadataURI;
        uint64  registeredAt;
        bool    active;
    }

    function agents(bytes32) external view returns (Agent memory);
    function agentsByOwner(address, uint256) external view returns (bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function registerAgent(bytes32 agentId, string calldata metadataURI, uint256 maxPerTx, uint256 maxPerDay) external;
    function deactivateAgent(bytes32 agentId) external;
    function updatePolicy(bytes32 agentId, uint256 maxPerTx, uint256 maxPerDay) external;
    function adjustReputation(bytes32 agentId, int256 delta) external;
    function checkAndRecordSpend(bytes32 agentId, uint256 amount) external;
    function getAgentCount(address owner_) external view returns (uint256);
    function getRolling24hSpend(bytes32 agentId) external view returns (uint256 total);
    function grantReputationOracle(address oracle) external;
    function revokeReputationOracle(address oracle) external;
    function pause() external;
    function unpause() external;
}