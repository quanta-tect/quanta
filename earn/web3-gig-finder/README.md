# web3-gig-finder

CLI tool to find Web3/Blockchain freelance jobs, audit bounties, and grants.

## Install

```bash
cd web3-gig-finder
pip install -e .
```

## Usage

```bash
# Scan all opportunities
web3gig scan

# Filter by skill
web3gig scan --skill solidity
web3gig scan --skill rust

# Sort by pay rate
web3gig scan --sort pay

# Export to CSV
web3gig scan --export results.csv

# Generate cover letter
web3gig cover --job "Solidity Developer" --company "Aave"

# List grant programs
web3gig grants

# List audit contests
web3gig audits
```

## Features

- Scan multiple job platforms (Upwork, Toptal, Replit)
- Filter by skills (Solidity, Rust, TypeScript, AI)
- Rank by pay rate
- Export results to JSON/CSV
- Generate cover letter templates
- Track applications
