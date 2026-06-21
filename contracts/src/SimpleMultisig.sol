// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

/// @title SimpleMultisig — Minimal multisig wallet for QUANTA testnet
/// @notice 1-of-N multisig (any signer can execute). Expandable to M-of-N.
/// @dev For testnet/development. Mainnet should use Gnosis Safe.
contract SimpleMultisig {
    address[] public signers;
    uint256 public threshold;

    mapping(bytes32 => bool) public executed;

    event TransactionExecuted(bytes32 indexed txHash, address indexed to, uint256 value, bytes data);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    modifier onlySigner() {
        bool isSigner = false;
        for (uint256 i = 0; i < signers.length; i++) {
            if (msg.sender == signers[i]) {
                isSigner = true;
                break;
            }
        }
        require(isSigner, "MSig: not signer");
        _;
    }

    constructor(address[] memory _signers, uint256 _threshold) {
        require(_signers.length > 0, "MSig: no signers");
        require(_threshold > 0 && _threshold <= _signers.length, "MSig: bad threshold");

        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "MSig: zero signer");
            signers.push(_signers[i]);
            emit SignerAdded(_signers[i]);
        }
        threshold = _threshold;
    }

    /// @notice Execute a transaction (call `to` with `data` and optional `value`)
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlySigner returns (bool success) {
        bytes32 txHash = keccak256(abi.encodePacked(block.timestamp, msg.sender, to, value, data));
        require(!executed[txHash], "MSig: already executed");

        executed[txHash] = true;
        (success, ) = to.call{value: value}(data);
        require(success, "MSig: call failed");

        emit TransactionExecuted(txHash, to, value, data);
    }

    /// @notice Add a new signer
    function addSigner(address _signer) external onlySigner {
        require(_signer != address(0), "MSig: zero address");
        signers.push(_signer);
        emit SignerAdded(_signer);
    }

    /// @notice Get all signers
    function getSigners() external view returns (address[] memory) {
        return signers;
    }

    /// @notice Get number of signers
    function signerCount() external view returns (uint256) {
        return signers.length;
    }

    /// @notice Fallback to receive ETH
    receive() external payable {}
}
