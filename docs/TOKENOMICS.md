# QUANTA Tokenomics

## 1. Supply & Symbol

- **Symbol**: QTA
- **Smallest unit**: 1 quark = 10⁻¹⁸ QTA (like wei)
- **Max total supply**: 1,000,000,000 QTA (1 billion — fixed cap, no further minting)
- **Genesis supply**: 300,000,000 QTA (30%)
- **Remaining**: 700,000,000 QTA emitted gradually via mining/staking over 50 years

## 2. Genesis Distribution (300M QTA)

| Allocation             | %    | Amount    | Vesting                                  |
|------------------------|------|-----------|------------------------------------------|
| Community Airdrop      | 15%  | 45M       | 25% TGE, 75% linear 12 months           |
| Ecosystem Fund         | 20%  | 60M       | 4 years linear, multisig 5/9            |
| Team & Founders        | 15%  | 45M       | 1 year cliff + 4 years linear           |
| Early Investors        | 10%  | 30M       | 6 month cliff + 3 years linear          |
| AI Research Grants     | 10%  | 30M       | By proposal, DAO approval               |
| Liquidity Provision    | 8%   | 24M       | Locked LP 4 years                       |
| Public Sale            | 7%   | 21M       | Unlocked at TGE                         |
| Validator Bootstrap    | 10%  | 30M       | Distributed to 100 genesis validators   |
| **Treasury (DAO)**     | 5%   | 15M       | DAO controlled                          |

## 3. Emission Schedule — 700M QTA

Half-life every 6 years (similar to Bitcoin but softer):

```
Year 1-6:    100M QTA (16.67M/year)
Year 7-12:    50M QTA
Year 13-18:   25M QTA
...
Total to year 50 ≈ 700M
```

Distribution per block reward:
- 60% → Validators (PoUW work)
- 25% → Stakers (delegators)
- 10% → AI Research Treasury
- 5% → Burn (deflationary pressure)

## 4. Burn Mechanism (Deflationary)

QTA is **deflationary** through multiple mechanisms:

1. **Base fee burn**: 50% of transaction fees burned (EIP-1559 style)
2. **AI inference fee**: 30% of inference fees on marketplace burned
3. **Slashing burn**: 100% of slashed stake → burned
4. **Naming burn**: registering `.qta` names burns lifetime fee

**Simulation**: When network reaches 1M tx/day + 10M AI inference/day, expected burn ~50K QTA/day, exceeding emission by year 8 → net deflationary.

## 5. Staking & Yield

| Role                 | Target APY    | Requirements                     |
|----------------------|---------------|----------------------------------|
| Solo validator       | 12-18%        | 10,000 QTA + GPU ≥ RTX 4090      |
| Delegator            | 6-9%          | Any amount                       |
| Liquid staking (qQTA)| 5-7%          | Receive qQTA usable in DeFi      |
| AI Compute Provider  | 15-25%        | Stake + provide GPU 24/7         |
| Long-term lock 4 years| +50% boost  | Locked, no withdrawal           |

Effective inflation ≈ 3-5%/year, after burn ≈ 0% to -2%/year when network matures.

## 6. Fee Model

```
total_fee = base_fee + priority_tip + storage_fee + compute_fee

base_fee     : dynamic per congestion (EIP-1559), burned
priority_tip : user-set, goes to validator
storage_fee  : if tx creates new state (NFT, contract deploy)
compute_fee  : if calling AI opcode (LLM_INFER, IMAGE_GEN, ZK_VERIFY)
```

Example real-world costs (estimated at steady state):

| Action                          | Fee (QTA)   | Fee ($) @ $1/QTA |
|---------------------------------|-------------|-------------------|
| Standard transfer               | 0.001       | $0.001            |
| Smart contract call             | 0.005       | $0.005            |
| AI inference (small LLM)        | 0.0001      | $0.0001           |
| Mint NFT model                  | 0.5         | $0.50             |
| Micropayment channel (off-chain)| 0.000001    | $0.000001         |

## 7. Use Cases Driving QTA Demand

1. **Gas** for every transaction
2. **Stake** to run validator or delegate
3. **Pay-per-inference** on AI marketplace
4. **Buy compute** (cQTA) to train models
5. **Governance voting** (quadratic, requires token lock)
6. **Naming service** (qns: `vinh.qta`, `gpt5.qta`)
7. **Insurance pool** for AI agents (slashing protection)
8. **Bridge collateral** for cross-chain assets

## 8. Long-term Economic Model

Projections (optimistic adoption assumption):

| Year | Active wallets | AI agents | Daily tx | TVL    | Market cap |
|------|----------------|-----------|----------|--------|------------|
| 1    | 100K           | 10K       | 50K      | $50M   | $200M      |
| 3    | 5M             | 1M        | 5M       | $2B    | $10B       |
| 5    | 50M            | 100M      | 500M     | $50B   | $200B      |
| 10   | 500M           | 10B       | 50B      | $1T    | $3T        |

⚠️ **Note**: These are hypothetical simulations, not forecasts. Crypto is extremely risky.

## 9. Tokenomics Comparison

|                      | BTC      | ETH       | SOL    | **QTA**       |
|----------------------|----------|-----------|--------|---------------|
| Max supply           | 21M      | ∞         | ∞      | 1B            |
| Current inflation    | 1.7%     | -0.5%     | 5%     | -2% (target)  |
| Burn mechanism       | ❌       | ✅        | ❌     | ✅✅✅       |
| Staking yield        | -        | 3-4%      | 7%     | 6-25%         |
| Quantum-safe         | ❌       | ❌        | ❌     | ✅            |
| AI demand sink       | ❌       | ❌        | ❌     | ✅            |
