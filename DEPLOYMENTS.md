# Zeusyxa Deployments

## Base Sepolia Testnet

### V2 Contracts (Deployed June 27, 2026)

| Contract | Address | Verified |
|---|---|---|
| ZeusyxaTokenV2 | `0x6d089d25035868358952b4d3644f8dAdcCc3295a` | Yes |
| ZeusyxaVestingWallet | `0xDc1B7aB0e7aE57bbB66ead2d9998bDA9127A291D` | Yes |
| ZeusyxaTreasuryController | `0xb8D10Ba1839597c0c76a60455E231Ac2bA837901` | Yes |
| ZeusyxaRewardsDistributor | `0x3bED931A6A4F0246d152c2532BB9015850657446` | Yes |

- Network: Base Sepolia (84532)
- Compiler: Solc 0.8.24
- Verification: Sourcify exact_match on Blockscout

### V1.2 Contracts (Security Hardened)

| Contract | Address | Verified |
|---|---|---|
| ZeusyxaToken | `0xBfeC1E5574940E4132296819dd4953A3D990dA9a` | Yes |
| AIAgentRegistry | `0x37789b163F27a88e6B358c546C34e6d3d6CC6D0c` | Yes |
| AIPaymentChannel | `0x22B28618ef6424F253A4D76cEDF5ddD48C0c2EC8` | Yes |
| AIModelMarketplace | `0xBFE04AB65bEA3d0F0A2886C2eC06C5F7622884aA` | Yes |

- Network: Base Sepolia (84532)
- Compiler: Solc 0.8.24
- Verification: Sourcify exact_match on Blockscout

## Multisig

| Role | Address |
|---|---|
| Treasury Multisig | `0x1d6a9512fF4A98C192A99Adea934ac3f83035953` |
| Team Multisig | `0x1d6a9512fF4A98C192A99Adea934ac3f83035953` |
| Deployer / Current Owner | `0x2060378AF1916eCFB1A6734405d4f4a62f1560FC` |

## Ownership Status

- V1.2 contracts ownership transfer to multisig pending.
- V2 ownership controlled by deployer/maintainer flow; no immediate multisig handoff pending.
