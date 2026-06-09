# SKILLS.md — Task-Specific Workflows

---

## Deploy Contracts
1. source ~/.env
2. cd ~/quanta/contracts && forge build && forge test
3. forge script script/DeployV11.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast
4. Update: sdk/src/types.ts, DEPLOYMENTS.md, PROJECT_CONTEXT.md
5. Verify (see below)

## Verify Contracts (Sourcify)
1. cd ~/quanta/contracts
2. unset ETHERSCAN_API_KEY BASESCAN_API_KEY
3. forge verify-contract --chain-id 84532 --verifier sourcify ADDRESS src-v1.1/FILE.sol:NAME
4. Check: curl -s "https://sourcify.dev/server/v2/contract/84532/ADDRESS"

## Run SDK Demo
1. cd ~/quanta/sdk && npm install
2. echo "PRIVATE_KEY=0x..." > .env
3. Manual approve (if needed):
   cast send 0x312137fb6943F8f89F5eF0f221aA102035a16625 "approve(address,uint256)" 0xF146e95b97fce1d1800F5F922AE99155711A4314 1000000000000000000 --rpc-url https://sepolia.base.org --private-key $DEPLOYER_KEY
4. npx tsx examples/autonomous-agent.ts

## Update Addresses (after redeploy)
Update ALL: sdk/src/types.ts, DEPLOYMENTS.md, PROJECT_CONTEXT.md, MEMORY.md

## Mainnet Prep Checklist
- [ ] Professional audit (Slither, Mythril, manual)
- [ ] 100% test coverage (forge coverage)
- [ ] Fuzz testing (forge test --profile fuzz)
- [ ] Multi-sig owner (not single key)
- [ ] Emergency procedures documented
- [ ] SDK tested on mainnet fork
