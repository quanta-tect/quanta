#!/bin/bash
# QUANTA — One-shot setup script
# Run from quanta/ root: bash setup.sh

set -e

GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}⚛  QUANTA Setup${NC}"
echo "================================="

# --- 1. Python prototype ---
echo -e "\n${CYAN}[1/4] Testing Python prototype...${NC}"
cd prototype && python3 demo.py 2>&1 | tail -5 && cd ..
echo -e "${GREEN}✓ Prototype OK${NC}"

# --- 2. Tokenomics simulator ---
echo -e "\n${CYAN}[2/4] Running tokenomics simulator...${NC}"
cd simulator && python3 tokenomics_sim.py --scenario base 2>&1 | tail -10 && cd ..
echo -e "${GREEN}✓ Simulator OK${NC}"

# --- 3. Foundry setup (smart contracts) ---
echo -e "\n${CYAN}[3/4] Setting up Foundry...${NC}"
if ! command -v forge &> /dev/null; then
    echo "⚠️  Foundry not installed. Install with:"
    echo "    curl -L https://foundry.paradigm.xyz | bash && foundryup"
else
    cd contracts
    [ ! -d "lib/openzeppelin-contracts" ] && forge install OpenZeppelin/openzeppelin-contracts --no-commit
    [ ! -d "lib/forge-std" ] && forge install foundry-rs/forge-std --no-commit
    forge build 2>&1 | tail -5
    forge test 2>&1 | tail -10
    cd ..
    echo -e "${GREEN}✓ Contracts compiled + tested${NC}"
fi

# --- 4. SDK ---
echo -e "\n${CYAN}[4/4] Installing SDK...${NC}"
if command -v npm &> /dev/null; then
    cd sdk && npm install 2>&1 | tail -3 && cd ..
    echo -e "${GREEN}✓ SDK ready${NC}"
else
    echo "⚠️  npm not found, skip SDK install"
fi

echo -e "\n${PURPLE}🎉 Setup complete!${NC}\n"
echo "Try these:"
echo "  • Landing page:  open landing/index.html"
echo "  • Explorer:      open explorer/index.html"
echo "  • Python demo:   cd prototype && python3 demo.py"
echo "  • Deploy smart contracts:"
echo "      cd contracts && forge script script/Deploy.s.sol --rpc-url \$RPC --broadcast"
echo "  • SDK demo:      cd sdk && npm run demo:agent"
