#!/bin/bash
# Run all security tools locally before pushing.
# Usage: cd contracts && bash run-security-tools.sh

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}🔐 QUANTA Security Tool Suite${NC}"
echo "================================="

# 1. Build
echo -e "\n${YELLOW}[1/5] Forge build${NC}"
forge build 2>&1 | tail -3

# 2. Tests
echo -e "\n${YELLOW}[2/5] Forge test (v1.1 security fixes)${NC}"
forge test --match-path "test-v1.1/**" -vv 2>&1 | tail -25

# 3. Coverage
echo -e "\n${YELLOW}[3/5] Coverage${NC}"
forge coverage --report summary --match-path "test-v1.1/**" 2>&1 | tail -10

# 4. Slither
echo -e "\n${YELLOW}[4/5] Slither static analysis${NC}"
if command -v slither &> /dev/null; then
    slither src-v1.1/ --config-file slither.config.json --exclude-informational 2>&1 | tail -30 || true
else
    echo -e "${RED}Slither not installed. Install: pip install slither-analyzer${NC}"
fi

# 5. Mythril (slow, optional)
echo -e "\n${YELLOW}[5/5] Mythril symbolic execution (optional, ~2 min)${NC}"
if command -v myth &> /dev/null; then
    if [ "$1" == "--with-mythril" ]; then
        myth analyze src-v1.1/QuantaToken.sol --solv 0.8.24 --execution-timeout 60 2>&1 | tail -20 || true
    else
        echo "Skipped (use --with-mythril to enable, ~2 min)"
    fi
else
    echo -e "${RED}Mythril not installed. Install: pip install mythril${NC}"
fi

# 6. Secret scan
echo -e "\n${YELLOW}[Bonus] Checking for accidentally committed secrets...${NC}"
if git ls-files | xargs grep -l "PRIVATE_KEY\s*=\s*0x[0-9a-fA-F]\{64\}" 2>/dev/null; then
    echo -e "${RED}⚠️  FOUND POTENTIAL PRIVATE KEY IN GIT! Audit immediately.${NC}"
    exit 1
else
    echo -e "${GREEN}✓ No private keys found in tracked files${NC}"
fi

echo -e "\n${GREEN}✅ Security scan complete.${NC}"
echo "Read SECURITY_AUDIT.md for full findings."
