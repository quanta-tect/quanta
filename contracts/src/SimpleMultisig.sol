// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

/** @title SimpleMultisig — Minimal multisig wallet for QUANTA testnet
 * @notice Operation-centric threshold wallet: any signer can broadcast an
 *         operation, but it only executes once enough distinct signers have
 *         confirmed the same op. Use separate EOAs per signer.
 * @dev For testnet/development. Mainnet should use Gnosis Safe.
 */
contract SimpleMultisig {
    address[] public signers;
    uint256 public threshold;

    mapping(bytes32 => bool) public executed;
    mapping(bytes32 => uint256) public confirmations;
    mapping(bytes32 => mapping(address => bool)) public signerConfirmed;

    event TransactionExecuted(bytes32 indexed txHash, address indexed to, uint256 value, bytes data);
    event Confirmation(bytes32 indexed txHash, address indexed signer);
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
        bytes32 txHash = keccak256(abi.encodePacked(to, value, data));
        require(!executed[txHash], "MSig: already executed");

        if (!signerConfirmed[txHash][msg.sender]) {
            signerConfirmed[txHash][msg.sender] = true;
            confirmations[txHash]++;
            emit Confirmation(txHash, msg.sender);
        }

        require(confirmations[txHash] >= threshold, "MSig: threshold not met");

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
