# Zeusyxa v1.3 Deployment Guide

## Prerequisites

1. **Foundry** installed (v1.8.1+)
2. **Base Sepolia RPC** endpoint (Alchemy, Infura, etc.)
3. **Deployer wallet** with ETH for gas on Base Sepolia
4. **Etherscan API key** for contract verification

## Setup

```bash
cd contracts
cp ../.env.example ../.env
# Edit .env with your values
```

## Deploy to Base Sepolia

```bash
# Load environment
source ../.env

# Deploy
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --private-key $DEPLOYER_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## After Deployment

1. Note the deployed contract addresses from the output
2. Update SDK `src/constants.ts` with new addresses
3. Run SDK integration tests: `cd ../sdk && npm test`
4. Update docs/DEPLOYMENTS.md with new addresses

## Contract Addresses (v1.3)

| Contract | Address | Verified |
|----------|---------|----------|
| ZeusyxaToken |  |  |
| AIAgentRegistry |  |  |
| AIPaymentChannel |  |  |
| AIModelMarketplace |  |  |

## Bridge Setup (Post-Deploy)

The deployment queues a bridge change to the deployer. After 7 days timelock:

```bash
# Apply bridge change (allows deployer to mint/burn)
forge script script/ApplyBridgeChange.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --private-key $DEPLOYER_KEY \
  --broadcast
```