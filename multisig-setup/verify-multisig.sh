#!/bin/bash
# Verify multisig ownership transferred correctly
# Usage: bash verify-multisig.sh

set -e

: "${SAFE_ADDRESS:?SAFE_ADDRESS env var required}"
: "${BASE_RPC:?BASE_RPC env var required (e.g., https://mainnet.base.org)}"
: "${QUANTA_TOKEN:?QUANTA_TOKEN address required}"
: "${QUANTA_REGISTRY:?QUANTA_REGISTRY address required}"
: "${QUANTA_CHANNEL:?QUANTA_CHANNEL address required}"
: "${QUANTA_MARKET:?QUANTA_MARKET address required}"

CONTRACTS=(
  "QuantaToken:$QUANTA_TOKEN"
  "AIAgentRegistry:$QUANTA_REGISTRY"
  "AIPaymentChannel:$QUANTA_CHANNEL"
  "AIModelMarketplace:$QUANTA_MARKET"
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
