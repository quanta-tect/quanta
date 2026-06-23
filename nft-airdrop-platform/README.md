# NFT Airdrop Platform – ERC721 / ERC1155 Merkle Claim

Production-ready airdrop contracts built for Senior Web3 NFT Airdrop Platform job spec (29-page).

GitHub: https://github.com/quanta-tect/quanta  
LinkedIn: https://www.linkedin.com/in/quanta-protocol-5761a4411

## Stack match

- **Chains:** Ethereum • Polygon • BSC (mainnet + testnet)
- **Standards:** ERC-721Enumerable • ERC-1155
- **Wallets:** MetaMask • WalletConnect v2 • Coinbase Wallet SDK (wagmi + viem)
- **Auth:** SIWE + JWT
- **Eligibility:** Public • ERC-20/NFT holding • Merkle whitelist • Discord/Twitter roles • multi-condition
- **Claim:** MerkleProof.sol • gas estimation • tx recovery • EIP-1559
- **Gasless:** EIP-2771 TrustedForwarder • OpenGSN v3 ready
- **Anti-abuse:** Sybil rate-limit • replay guard • blacklist • BitMaps
- **Infra:** Foundry 141+ tests • Slither 0.11.5 • Redis • Postgres replicas • RPC fallback
- **Performance:** 1.5s load • 500 claims/sec target • 99.9% uptime

## Contracts

`contracts/src/NFTMerkleAirdrop.sol`
- ERC721Enumerable + Ownable2Step
- Merkle whitelist, BitMaps claimed
- EIP-2771 gasless, pause, blacklist, 60s rate limit
- Solidity 0.8.24, OpenZeppelin 5.0.2

`contracts/src/ERC1155MerkleAirdrop.sol`
- ERC1155 multi-id airdrop, Merkle + EIP-2771

## Verify – Quanta Protocol suite

- QuantaToken – ERC-20 burn + treasury + multisig
- AIAgentRegistry – on-chain agent registration, RBAC
- AIPaymentChannel – approve/transferFrom settlement
- AIModelMarketplace – listing + fee distribution

All: Solidity 0.8.24 + OpenZeppelin • 141+ Foundry tests • Slither v0.11.5 clean (20 fixed) • Verified Base Sepolia

## Quick start

```bash
cd contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
forge test -vv
forge build
```

Deploy (ETH / Polygon / BSC):

```bash
forge script script/Deploy.s.sol --rpc-url $ETH_RPC --broadcast --verify
```

## Hire

$95/hr • $90/hr long-term  
Start: TODAY – UTC+7 full-time – US EST / EU overlap  
Contact: https://www.linkedin.com/in/quanta-protocol-5761a4411
