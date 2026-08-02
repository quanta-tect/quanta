Contributing to QUANTA
Thank you for considering contributing to QUANTA! 🎉
This document outlines how to contribute, what we're looking for, and how to get your contribution merged.
---
🎯 Ways to Contribute
💻 Code Contributions
We accept PRs in these areas:
Area	Languages	Difficulty
Smart contracts (Solidity)	Solidity 0.8.24	Advanced
SDK improvements	TypeScript	Intermediate
Python prototype	Python 3.10+	Beginner-friendly
Documentation	Markdown	Beginner-friendly
Tests (fuzz, formal)	Solidity, Halmos	Advanced
Security tooling	Bash, JavaScript	Intermediate
🐛 Bug Reports
Security issues: see SECURITY.md — DO NOT open public issues
Non-security bugs: open a GitHub Issue with bug template
💡 Feature Requests
Open a Discussion first
If community is supportive, convert to Issue
For major features, write a brief design doc
📚 Documentation
Fix typos: just send a PR
Translate to other languages: open Discussion first to coordinate
Improve guides: PRs welcome
---
🚀 Getting Started
1. Set up dev environment
```bash
# Clone the repo
git clone https://github.com/quanta-tect/quanta.git
cd quanta

# Set up Python prototype
cd prototype && python3 demo.py
# Should print: "Demo complete..."

# Set up smart contracts
cd ../contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
forge test --match-path "test-v1.1/**" -vv
# Should show: 13 tests passing

# Set up SDK
cd ../sdk
npm install
```
2. Find an issue to work on
Browse `good first issue` labels
Comment on the issue: "I'd like to work on this"
Wait for maintainer to assign you (avoids duplicate work)
3. Create your branch
```bash
git checkout -b feat/your-feature-name
# OR
git checkout -b fix/bug-description
# OR
git checkout -b docs/improve-section
```
4. Make your changes
Follow our conventions:
Solidity
Solidity 0.8.24 (pinned, not floating)
Use OpenZeppelin contracts where possible
100% NatSpec on public/external functions
Custom errors, not string reverts
ReentrancyGuard on all state-changing externals
Tests in `test-v1.1/` (security regressions) or `test-invariant/` (fuzz)
TypeScript
Strict mode enabled
Use `viem` for blockchain interactions (not `ethers.js`)
No `any` types (use `unknown` if needed)
Format with Prettier
Python
Python 3.10+
Type hints required
Format with `black`
5. Test your changes
```bash
# Smart contracts
cd contracts && forge test --match-path "test-v1.1/**" -vv
cd contracts && forge test --match-path "test-invariant/**" --fuzz-runs 10000

# SDK
cd sdk && npm test

# Python
cd prototype && python3 -m pytest
```
All tests must pass before submitting PR.
6. Commit your changes
Use Conventional Commits:
```bash
git commit -m "feat: add Hyperlane bridge integration"
git commit -m "fix: prevent reentrancy in payment channel close"
git commit -m "docs: clarify staking parameters"
git commit -m "test: add invariant for token cap"
git commit -m "chore: bump OpenZeppelin to v5.1"
```
Common prefixes:
`feat:` new feature
`fix:` bug fix
`docs:` documentation only
`test:` adding tests
`chore:` maintenance, deps, configs
`refactor:` code change that doesn't fix bug or add feature
`style:` formatting only
`perf:` performance improvement
7. Push and open PR
```bash
git push origin feat/your-feature-name
```
Then go to GitHub and:
Click "Compare & pull request"
Fill in the PR template
Link related issues with `Closes #123`
Wait for review
---
🔍 Code Review Process
What we look for:
✅ Code quality
Tests included and passing
Follows existing patterns
Well-commented
No security regressions
✅ Documentation
README updated if needed
NatSpec for Solidity
TypeDoc for TypeScript
✅ Backward compatibility
Doesn't break existing API
Or includes migration guide
Review timeline:
Initial response: within 72 hours
Full review: within 7 days
Merge after approval: usually within 24 hours
What might cause rejection:
❌ No tests
❌ Breaks existing tests
❌ Introduces security risk
❌ Out of scope
❌ Duplicates existing work
❌ Style violations (we can usually fix these for you)
---
🏆 Recognition
All contributors are recognized in:
CONTRIBUTORS.md — list of all contributors
Release notes — when their PR is included in a release
Hall of Fame — top 10 contributors get perm
