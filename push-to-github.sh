#!/bin/bash
# =============================================================================
# QUANTA — One-Shot GitHub Push Script
# =============================================================================
# Usage:
#   1. Edit the REPO_URL below
#   2. Run: bash push-to-github.sh
# =============================================================================

# ⚠️ EDIT THIS LINE with your actual repo URL:
REPO_URL="https://github.com/quanta-tect/quanta"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🚀 QUANTA — Push to GitHub                                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# --- Sanity check: are we in the right directory? ---
if [ ! -f "README.md" ] || [ ! -d "contracts" ]; then
  echo -e "${RED}❌ Error: Doesn't look like the QUANTA workspace.${NC}"
  echo "   Expected files: README.md, contracts/ folder"
  echo "   Current directory: $(pwd)"
  echo ""
  echo "   Run this script from inside the quanta/ folder."
  exit 1
fi

# --- Check REPO_URL was edited ---
if [[ "$REPO_URL" == *"YOUR_USERNAME"* ]]; then
  echo -e "${RED}❌ Error: You haven't edited REPO_URL in this script!${NC}"
  echo ""
  echo "   Open push-to-github.sh and change line 11:"
  echo "   REPO_URL=\"https://github.com/YOUR_USERNAME/YOUR_REPO.git\""
  echo ""
  echo "   Replace YOUR_USERNAME and YOUR_REPO with your actual GitHub info."
  exit 1
fi

# --- Verify .gitignore exists ---
if [ ! -f ".gitignore" ]; then
  echo -e "${RED}❌ Error: .gitignore is MISSING!${NC}"
  echo "   This is dangerous — refusing to push without it."
  echo "   The workspace should already have one. Did you delete it?"
  exit 1
fi

echo -e "${GREEN}✓${NC} In QUANTA workspace: $(pwd)"
echo -e "${GREEN}✓${NC} .gitignore exists"
echo -e "${GREEN}✓${NC} Target repo: $REPO_URL"
echo ""

# --- SECURITY SCAN: look for any obvious secrets ---
echo -e "${YELLOW}🔍 Scanning for sensitive files...${NC}"

found_sensitive=0
for pattern in ".env" "*.key" "*.pem" "id_rsa" "id_ed25519" ".quanta-deploy-seed.txt"; do
  matches=$(find . -name "$pattern" -not -name "*.example" -not -name "*.md" -not -path "./.git/*" 2>/dev/null)
  if [ -n "$matches" ]; then
    echo -e "${RED}   ⚠️  Found: $matches${NC}"
    found_sensitive=1
  fi
done

# Search for potential private keys in file contents
key_files=$(grep -rlE "PRIVATE_KEY\s*=\s*0x[a-fA-F0-9]{64}" . --include="*.env*" --include="*.txt" --include="*.json" --exclude-dir=.git 2>/dev/null | grep -v ".example")
if [ -n "$key_files" ]; then
  echo -e "${RED}   ⚠️  Possible private keys in: $key_files${NC}"
  found_sensitive=1
fi

if [ $found_sensitive -eq 1 ]; then
  echo ""
  echo -e "${RED}❌ STOPPING — sensitive files detected!${NC}"
  echo "   Move these files OUT of the workspace before pushing."
  echo "   Or add them to .gitignore."
  exit 1
fi

echo -e "${GREEN}   ✓ No sensitive files detected${NC}"
echo ""

# --- Initialize git if needed ---
if [ ! -d ".git" ]; then
  echo -e "${YELLOW}📦 Initializing git...${NC}"
  git init -q
  git branch -M main
  echo -e "${GREEN}   ✓ Git initialized${NC}"
else
  echo -e "${GREEN}✓ Git already initialized${NC}"
fi
echo ""

# --- Show what will be ignored ---
echo -e "${YELLOW}🚫 Files that will be IGNORED (good!):${NC}"
git status --ignored -s 2>/dev/null | grep "^!!" | head -10 | sed 's/^/   /'
echo "   (and others — see .gitignore for full list)"
echo ""

# --- Show what will be added ---
echo -e "${YELLOW}📝 Files to be added:${NC}"
total_files=$(git status --short 2>/dev/null | wc -l)
git status --short 2>/dev/null | head -15 | sed 's/^/   /'
if [ "$total_files" -gt 15 ]; then
  echo "   ... and $((total_files - 15)) more"
fi
echo ""
echo -e "   Total files to commit: ${GREEN}$total_files${NC}"
echo ""

# --- Confirm before proceeding ---
echo -e "${YELLOW}⏸  Pause: review the above output.${NC}"
echo ""
read -p "   Press Enter to commit and push, or Ctrl+C to cancel: "
echo ""

# --- Commit .gitignore first ---
echo -e "${YELLOW}📌 Step 1/3: Committing .gitignore first...${NC}"
git add .gitignore
git commit -q -m "chore: add .gitignore" --allow-empty 2>/dev/null
echo -e "${GREEN}   ✓ Done${NC}"

# --- Add everything else ---
echo -e "${YELLOW}📌 Step 2/3: Committing all project files...${NC}"
git add .
git commit -q -m "feat: initial release

- Whitepaper, tokenomics, roadmap
- Smart contracts v1.1 (security-hardened, 14 fixes applied)
- TypeScript SDK with AI agent + payment channel
- Python prototype with Merkle Signature Scheme
- Forta detection bot
- 7 security training courses
- 6 war game scenarios
- Audit applications (Code4rena, Sherlock, Immunefi)
- Bridge implementation (Hyperlane)
- 25+ tests pass (70k+ fuzz inputs)" --allow-empty 2>/dev/null
echo -e "${GREEN}   ✓ Done${NC}"

# --- Add remote and push ---
echo -e "${YELLOW}📌 Step 3/3: Pushing to GitHub...${NC}"
echo ""
echo -e "${BLUE}   (You may be asked for username/password.${NC}"
echo -e "${BLUE}    Use a Personal Access Token as password.${NC}"
echo -e "${BLUE}    Get one at: https://github.com/settings/tokens)${NC}"
echo ""

# Remove old remote if exists
git remote remove origin 2>/dev/null
git remote add origin "$REPO_URL"

# Push
if git push -u origin main; then
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✅ SUCCESS! Your project is now on GitHub!                  ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Visit your repo at: ${REPO_URL%.git}"
  echo "  2. Star your own repo (top right)"
  echo "  3. Edit description + add topics:"
  echo "     blockchain, cryptocurrency, quantum-resistant,"
  echo "     ai-agents, web3, solidity, base-chain, dilithium"
  echo "  4. Settings → Code security → enable:"
  echo "     - Dependabot alerts"
  echo "     - Secret scanning"
  echo "     - PUSH PROTECTION (most important!)"
  echo "  5. Tweet about it"
  echo "  6. Continue with LAUNCH_GUIDE_7_DAYS.md → Day 1"
else
  echo ""
  echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║   ❌ Push failed                                              ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Common causes:"
  echo "  • Wrong username/token — see PUSH_THIS_NOW.md"
  echo "  • Repo already has content (need to pull first)"
  echo "  • Wrong REPO_URL — verify in this script"
  echo ""
  echo "For details, see PUSH_THIS_NOW.md → Troubleshooting section"
  exit 1
fi
