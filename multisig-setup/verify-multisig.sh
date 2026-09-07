#!/bin/bash
# Verify multisig ownership transferred correctly
# Usage: bash verify-multisig.sh

set -e

: "${SAFE_ADDRESS:?SAFE_ADDRESS env var required}"
: "${BASE_RPC:?BASE_RPC env var required (e.g., https://mainnet.base.org)}"
: "${ZYX_TOKEN:?ZYX_TOKEN address required}"
: "${ZYX_REGISTRY:?ZYX_REGISTRY address required}"
: "${ZYX_CHANNEL:?ZYX_CHANNEL address required}"
: "${ZYX_MARKET:?ZYX_MARKET address required}"

CONTRACTS=(
  "ZyxToken:$ZYX_TOKEN"
  "AIAgentRegistry:$ZYX_REGISTRY"
  "AIPaymentChannel:$ZYX_CHANNEL"
  "AIModelMarketplace:$ZYX_MARKET"
)

echo "Verifying ownership transfer to Safe: $SAFE_ADDRESS"
echo ""

ALL_OK=true
for entry in "${CONTRACTS[@]}"; do
  NAME="${entry%%:*}"
  ADDR="${entry##*:}"

  OWNER=$(cast call "$ADDR" "owner()(address)" --rpc-url "$BASE_RPC")

  if [ "${OWNER,,}" = "${SAFE_ADDRESS,,}" ]; then
    echo "✅ $NAME ($ADDR): owner = Safe"
  else
    echo "❌ $NAME ($ADDR): owner = $OWNER  (expected $SAFE_ADDRESS)"
    ALL_OK=false
  fi
done

echo ""
if [ "$ALL_OK" = "true" ]; then
  echo "🎉 All contracts owned by multisig. Safe to launch."
  exit 0
else
  echo "🚨 Some contracts NOT owned by multisig. DO NOT launch yet."
  echo "   Likely cause: Safe hasn't called acceptOwnership() yet."
  echo "   Action: Go to app.safe.global → propose acceptOwnership() on each."
  exit 1
fi
