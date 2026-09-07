// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleMultisig
 * @notice Minimal 2-of-N multisig for treasury/emergency operations
 */
contract SimpleMultisig is Ownable {
    uint256 public constant THRESHOLD = 2;
    address[] public owners;

    event OwnersChanged(address[] owners);
    event Execution(address indexed target, uint256 value, bytes data, bool success);

    constructor(address[] memory _owners) Ownable(_owners[0]) {
        require(_owners.length >= THRESHOLD, "Need at least 2 owners");
        owners = _owners;
    }

    function execute(address target, uint256 value, bytes calldata data) external {
        uint256 approvals = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                approvals++;
                break;
            }
        }
        require(approvals >= THRESHOLD, "Not enough approvals");
        
        (bool success, ) = target.call{value: value}(data);
        emit Execution(target, value, data, success);
        require(success, "Execution failed");
    }

    function changeOwners(address[] calldata newOwners) external onlyOwner {
        require(newOwners.length >= THRESHOLD, "Need at least 2 owners");
        owners = newOwners;
        emit OwnersChanged(newOwners);
    }
}