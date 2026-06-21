#!/bin/bash
# deploy-multisig.sh — Deploy Gnosis Safe on Base Sepolia + transfer ownership
#
# Usage:
#   export DEPLOYER_KEY="0x..."
#   ./contracts/deploy-multisig.sh
#
# Safe v1.3.0 on Base Sepolia:
#   ProxyFactory: 0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC
#   Singleton:     0x69f4D1788e39c87893C980c06EdF4b7f686e2938

set -euo pipefail

RPC="https://sepolia.base.org"
FACTORY="0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC"
SINGLETON="0x69f4D1788e39c87893C980c06EdF4b7f686e2938"

# QUANTA contract addresses (Base Sepolia)
TOKEN="0x312137fb6943F8f89F5eF0f221aA102035a16625"
REGISTRY="0x10aE5f83F1CF20331186Ea1aD089D8fd3EbA5EEB"
CHANNEL="0xF146e95b97fce1d1800F5F922AE99155711A4314"
MARKETPLACE="0xFf584b30b2D00Bf0aB694683F06dC7E701fdfd49"

if [ -z "${DEPLOYER_KEY:-}" ]; then
    echo "ERROR: DEPLOYER_KEY not set."
    echo '  export DEPLOYER_KEY="0x..."'
    exit 1
fi

DEPLOYER=$(cast wallet address "$DEPLOYER_KEY" 2>/dev/null)
echo "Deployer: $DEPLOYER"
echo "Balance:  $(cast balance "$DEPLOYER" --rpc-url "$RPC" 2>/dev/null)"
echo ""

# Step 1: Deploy Gnosis Safe (1-of-1)
echo "=== Step 1: Deploy Gnosis Safe ==="

SETUP_DATA=$(cast abi-encode "setup(address[],uint256,address,bytes,address,uint256,address,uint256)" \
    "[$DEPLOYER]" 1 "0x0000000000000000000000000000000000000000" "0x" \
    "0x0000000000000000000000000000000000000000" 0 \
    "0x0000000000000000000000000000000000000000" 0)

SALT=$(cast keccak "$(date +%s%N)")
SAFE_TX=$(cast send "$FACTORY" \
    "createProxyWithOwners(address,bytes)" \
    "$SINGLETON" "$SETUP_DATA" \
    --rpc-url "$RPC" \
    --private-key "$DEPLOYER_KEY" \
    --json 2>/dev/null)

# Extract Safe address from event log
SAFE_ADDRESS=$(echo "$SAFE_TX" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for log in d.get('logs', []):
    if 'ProxyCreated' in log.get('topics', [''])[0] or 'address' in log:
        # ProxyCreated event returns the proxy address as the last topic
        topics = log.get('topics', [])
        if len(topics) >= 2:
            print('0x' + topics[1][-40:])
            break
" 2>/dev/null || echo "")

# Fallback: try to get from logs[0].address
if [ -z "$SAFE_ADDRESS" ] || [ "$SAFE_ADDRESS" = "0x" ]; then
    SAFE_ADDRESS=$(echo "$SAFE_TX" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for log in d.get('logs', []):
    addr = log.get('address', '')
    if addr and addr != '$FACTORY' and addr != '$SINGLETON':
        print(addr)
        break
" 2>/dev/null || echo "")
fi

if [ -z "$SAFE_ADDRESS" ] || [ "$SAFE_ADDRESS" = "0x" ]; then
    echo "Could not extract Safe address automatically."
    echo "Raw tx output:"
    echo "$SAFE_TX"
    echo ""
    echo "Check the ProxyCreated event in the tx receipt."
    exit 1
fi

echo "✓ Gnosis Safe deployed at: $SAFE_ADDRESS"
echo "  Threshold: 1-of-1 (owner: $DEPLOYER)"
echo "  UI: https://app.safe.global/home?safe=sep:$SAFE_ADDRESS"
echo ""

# Step 2: Propose ownership transfer
echo "=== Step 2: Propose ownership transfer ==="

for INFO in \
    "QuantaToken|$TOKEN" \
    "AIAgentRegistry|$REGISTRY" \
    "AIPaymentChannel|$CHANNEL" \
    "AIModelMarketplace|$MARKETPLACE"; do
    
    NAME=$(echo "$INFO" | cut -d'|' -f1)
    ADDR=$(echo "$INFO" | cut -d'|' -f2)
    
    echo "  $NAME ($ADDR)..."
    TX=$(cast send "$ADDR" \
        "transferOwnership(address)" "$SAFE_ADDRESS" \
        --rpc-url "$RPC" \
        --private-key "$DEPLOYER_KEY" \
        --json 2>/dev/null)
    
    HASH=$(echo "$TX" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transactionHash','FAILED'))" 2>/dev/null)
    echo "    ✓ tx: $HASH"
done

echo ""
echo "=== DONE ==="
echo ""
echo "Next: Open Safe UI and call acceptOwnership() on each contract:"
echo "  https://app.safe.global/home?safe=sep:$SAFE_ADDRESS"
echo ""
echo "Contracts to accept:"
echo "  QuantaToken:        $TOKEN"
echo "  AIAgentRegistry:    $REGISTRY"
echo "  AIPaymentChannel:   $CHANNEL"
echo "  AIModelMarketplace: $MARKETPLACE"
echo ""
echo "Security: unset DEPLOYER_KEY now"
