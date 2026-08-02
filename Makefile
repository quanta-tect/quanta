.PHONY: test build demo push approve balance check-verify

build:
	cd contracts && forge build

test:
	cd contracts && forge test -vvv

deploy:
	cd contracts && forge script script/Deploy.s.sol --rpc-url $(BASE_SEPOLIA_RPC) --broadcast

demo:
	cd sdk && npx tsx examples/autonomous-agent.ts

approve:
	cast send 0x312137fb6943F8f89F5eF0f221aA102035a16625 "approve(address,uint256)" 0xF146e95b97fce1d1800F5F922AE99155711A4314 115792089237316195423570985008687907853269984665640564039457584007913129639935 --rpc-url https://sepolia.base.org --private-key $(DEPLOYER_KEY)

balance:
	cast call 0x312137fb6943F8f89F5eF0f221aA102035a16625 "balanceOf(address)(uint256)" 0x288bc8d816f9C2E00af706fEBFeac9a7B149c110 --rpc-url https://sepolia.base.org

push:
	git add -A && git commit -m "$(MSG)" && git push

check-verify:
	@echo "=== QuantaToken ===" && curl -s "https://sourcify.dev/server/v2/contract/84532/0x312137fb6943F8f89F5eF0f221aA102035a16625" | grep -o '"match":"[^"]*"'
	@echo "=== AIAgentRegistry ===" && curl -s "https://sourcify.dev/server/v2/contract/84532/0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB" | grep -o '"match":"[^"]*"'
	@echo "=== AIPaymentChannel ===" && curl -s "https://sourcify.dev/server/v2/contract/84532/0xF146e95b97fce1d1800F5F922AE99155711A4314" | grep -o '"match":"[^"]*"'
	@echo "=== AIModelMarketplace ===" && curl -s "https://sourcify.dev/server/v2/contract/84532/0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49" | grep -o '"match":"[^"]*"'
