#!/usr/bin/env python3
"""
QUANTA Bounty Scanner — Daily scan for Web3 bounties, grants, freelance jobs.
Runs via cron, outputs formatted summary.
"""

import json
import subprocess
import sys
from datetime import datetime

def search_web(query, limit=5):
    """Search web using hermes web_search via subprocess."""
    # This script is called by cron job which has web_search available
    # Output format: just print results for the agent to read
    return query

# Categories to scan
SCANS = [
    {
        "name": "🔥 Smart Contract Audits (Code4rena/Sherlock)",
        "queries": [
            "code4rena active contests 2026",
            "sherlock audit contest upcoming",
            "immunefi bounties open"
        ]
    },
    {
        "name": "💼 Solidity/Rust Freelance Jobs",
        "queries": [
            "upwork solidity developer jobs",
            "web3 rust developer freelance",
            "ethereum smart contract developer remote"
        ]
    },
    {
        "name": "🏆 Hackathon Prizes",
        "queries": [
            "ethglobal hackathon 2026",
            "web3 hackathon prizes upcoming",
            "blockchain hackathon rewards"
        ]
    },
    {
        "name": "💰 Grant Programs Open",
        "queries": [
            "base builder grant apply 2026",
            "optimism retrofunding apply",
            "arbitrum grant program open",
            "gitcoin grants round"
        ]
    },
    {
        "name": "📝 Technical Writing Paid",
        "queries": [
            "hackernoon write earn",
            "dev.to paid articles web3",
            "web3 technical writer jobs"
        ]
    }
]

def format_output(results):
    """Format scan results."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    output = f"🔍 QUANTA Daily Bounty Scan — {now}\n"
    output += "=" * 50 + "\n\n"
    
    for category, items in results.items():
        output += f"{category}\n"
        output += "-" * 40 + "\n"
        if items:
            for item in items:
                output += f"  • {item}\n"
        else:
            output += "  (No new results today)\n"
        output += "\n"
    
    output += "=" * 50 + "\n"
    output += "💡 Action: Pick 1-2 opportunities and apply today!\n"
    output += "GitHub: github.com/quanta-tect/quanta\n"
    
    return output

if __name__ == "__main__":
    # When run by cron, this outputs search queries for the agent
    # The cron job agent will execute these searches and format results
    print("BOUNTY_SCANNER_QUERIES")
    for scan in SCANS:
        print(f"\n### {scan['name']}")
        for q in scan["queries"]:
            print(f"SEARCH: {q}")
