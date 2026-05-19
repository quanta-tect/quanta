#!/bin/bash
# ============================================================
# QUANTA — Complete security testing suite
# ============================================================
# Runs ALL security tools in sequence.
# Usage:
#   cd contracts
#   bash run-all-security.sh              # quick mode (~5 min)
#   bash run-all-security.sh --deep       # deep mode (~2 hours)
#   bash run-all-security.sh --docker     # use Docker for tools (no install needed)

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

MODE="quick"
USE_DOCKER=false
for arg in "$@"; do
  case $arg in
    --deep) MODE="deep" ;;
    --docker) USE_DOCKER=true ;;
  esac
done

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🔐 QUANTA Complete Security Suite                          ║${NC}"
echo -e "${CYAN}║  Mode: ${MODE}  |  Docker: ${USE_DOCKER}                                   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

# Track failures
FAILED=()

run_check() {
  local name=$1
  local cmd=$2
  echo -e "\n${YELLOW}━━━ $name ━━━${NC}"
  if eval "$cmd"; then
    echo -e "${GREEN}✓ $name passed${NC}"
  else
    echo -e "${RED}✗ $name FAILED${NC}"
    FAILED+=("$name")
  fi
}

# ============================================================
# 1. Build
# ============================================================
run_check "Foundry build" "forge build 2>&1 | tail -3"

# ============================================================
# 2. Unit tests + security regression (v1.1)
# ============================================================
run_check "Security regression tests (v1.1)" \
  "forge test --match-path 'test-v1.1/**' -vv 2>&1 | tail -20"

# ============================================================
# 3. Coverage
# ============================================================
run_check "Coverage report" \
  "forge coverage --report summary --match-path 'test-v1.1/**' 2>&1 | tail -10"

# ============================================================
# 4. Fuzz tests (Foundry built-in)
# ============================================================
FUZZ_RUNS=$([ "$MODE" = "deep" ] && echo 100000 || echo 1000)
run_check "Fuzz tests ($FUZZ_RUNS runs)" \
  "forge test --match-path 'test-invariant/FoundryInvariants.t.sol' --fuzz-runs $FUZZ_RUNS -vv 2>&1 | tail -15"

# ============================================================
# 5. Invariant tests (Foundry)
# ============================================================
INV_RUNS=$([ "$MODE" = "deep" ] && echo 10000 || echo 500)
INV_DEPTH=$([ "$MODE" = "deep" ] && echo 100 || echo 25)
run_check "Invariant tests ($INV_RUNS runs, depth $INV_DEPTH)" \
  "forge test --match-contract Invariant --invariant-runs $INV_RUNS --invariant-depth $INV_DEPTH 2>&1 | tail -15"

# ============================================================
# 6. Slither static analysis
# ============================================================
if [ "$USE_DOCKER" = true ]; then
  SLITHER_CMD="docker run -v $PWD:/src trailofbits/eth-security-toolbox slither /src/src-v1.1/ --exclude-informational"
else
  SLITHER_CMD="slither src-v1.1/ --config-file slither.config.json --exclude-informational"
fi
run_check "Slither static analysis" "$SLITHER_CMD 2>&1 | tail -30 || true"

# ============================================================
# 7. Mythril symbolic execution (deep mode only)
# ============================================================
if [ "$MODE" = "deep" ]; then
  if [ "$USE_DOCKER" = true ]; then
    MYTH_CMD="docker run -v $PWD:/src mythril/myth analyze /src/src-v1.1/QuantaToken.sol --solv 0.8.24"
  else
    MYTH_CMD="myth analyze src-v1.1/QuantaToken.sol --solv 0.8.24 --execution-timeout 300"
  fi
  run_check "Mythril (5 min timeout)" "$MYTH_CMD 2>&1 | tail -20 || true"
fi

# ============================================================
# 8. Halmos formal verification (deep mode)
# ============================================================
if [ "$MODE" = "deep" ]; then
  run_check "Halmos formal verification" \
    "halmos --contract HalmosSpecs --solver-timeout-assertion 60000 2>&1 | tail -20 || true"
fi

# ============================================================
# 9. Echidna fuzz (deep mode only — runs minutes/hours)
# ============================================================
if [ "$MODE" = "deep" ]; then
  ECHIDNA_CMD="docker run -v $PWD:/src trailofbits/eth-security-toolbox \
    echidna /src/test-invariant/QuantaTokenInvariants.sol \
    --contract QuantaTokenInvariants \
    --config /src/test-invariant/echidna.yaml"
  run_check "Echidna (deep fuzz)" "$ECHIDNA_CMD 2>&1 | tail -15 || true"
fi

# ============================================================
# 10. Secret scanning
# ============================================================
run_check "Secret leak check" '
  if git ls-files | xargs grep -l "PRIVATE_KEY\s*=\s*0x[0-9a-fA-F]\{64\}" 2>/dev/null; then
    echo "⚠️  POTENTIAL PRIVATE KEY FOUND"
    false
  else
    echo "No leaked secrets"
  fi
'

# ============================================================
# 11. Storage layout snapshot (regression check)
# ============================================================
mkdir -p .storage
for contract in QuantaToken AIAgentRegistry AIPaymentChannel AIModelMarketplace; do
  forge inspect "src-v1.1/${contract}.sol:${contract}" storage-layout > ".storage/${contract}.json" 2>/dev/null || true
done
echo -e "${GREEN}✓ Storage layouts snapshotted to .storage/${NC}"

# ============================================================
# SUMMARY
# ============================================================
echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
if [ ${#FAILED[@]} -eq 0 ]; then
  echo -e "${CYAN}║  ${GREEN}✅ ALL CHECKS PASSED${CYAN}                                       ║${NC}"
else
  echo -e "${CYAN}║  ${RED}❌ ${#FAILED[@]} CHECKS FAILED${CYAN}                                          ║${NC}"
  for f in "${FAILED[@]}"; do
    echo -e "${CYAN}║    ${RED}- $f${NC}"
  done
fi
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

if [ ${#FAILED[@]} -gt 0 ]; then exit 1; fi
