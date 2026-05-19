# 📖 Course 04: Reading a Smart Contract

**Audience**: Developers + advanced users
**Duration**: 90 minutes
**Prerequisites**: Basic Solidity knowledge helps

> Goal: Before interacting with any contract, be able to assess basic safety yourself.

## Module 1: Where to find contract code (10 min)

### Step 1: Get the contract address
- From official project documentation
- Cross-reference with multiple sources
- Verify same address across community

### Step 2: View on Etherscan/Basescan
```
https://basescan.org/address/0x...
```

Check for:
- [ ] ✅ **Verified contract** badge (green checkmark)
- [ ] Compiler version reasonable (0.8.x, not 0.4.x)
- [ ] License: MIT/Apache (open source)
- [ ] Constructor args make sense

### Step 3: Read the "Read Contract" tab
- View state variables for free
- Check `owner()` — who controls this?
- Check `paused()` — is it operational?
- Check `totalSupply()` — for tokens, sane?

### Step 4: Read the source code
- Tab "Contract" → scroll down to source
- Most projects have multiple files imported

## Module 2: Red flags to look for (30 min)

### 🚩 Red flag 1: Owner can do anything

```solidity
function withdrawAll(address recipient) external onlyOwner {
    payable(recipient).transfer(address(this).balance);
}
```

**Translation**: Owner can drain all user funds anytime. Run away.

### 🚩 Red flag 2: Mint without cap

```solidity
function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount); // no MAX_SUPPLY check
}
```

**Translation**: Owner can print infinite tokens, dump on market.

### 🚩 Red flag 3: Upgradeable + no timelock

```solidity
function upgradeTo(address newImplementation) external onlyOwner {
    // immediate upgrade, no delay
}
```

**Translation**: Owner can swap logic for malicious code instantly. No time to exit.

### 🚩 Red flag 4: Blacklist function

```solidity
function blacklist(address user) external onlyOwner {
    blacklisted[user] = true;
}
modifier notBlacklisted() { require(!blacklisted[msg.sender]); }
```

**Translation**: Owner can freeze YOUR funds anytime.

### 🚩 Red flag 5: Fee manipulation

```solidity
function setFee(uint256 newFee) external onlyOwner {
    fee = newFee; // can set to 100%
}
```

**Translation**: Owner can take 100% of trades.

### 🚩 Red flag 6: Hidden mint via library

```solidity
import "./MathLib.sol";
// Where MathLib.sol contains:
function calculate(...) external {
    QuantaToken.mint(attacker, 1e30); // hidden malicious call
}
```

**Translation**: Indirection hides backdoors. Read ALL imports.

### 🚩 Red flag 7: External call before state update

```solidity
function withdraw() external {
    payable(msg.sender).transfer(balance[msg.sender]);  // call first
    balance[msg.sender] = 0;                            // update after = REENTRANCY
}
```

**Translation**: Classic reentrancy bug. The DAO hack 2016 ($60M).

### 🚩 Red flag 8: No event emissions

```solidity
function transferOwnership(address newOwner) external {
    owner = newOwner; // no event
}
```

**Translation**: Hard to track changes off-chain. Suspicious.

## Module 3: Green flags (10 min)

### ✅ Green flag 1: OpenZeppelin imports

```solidity
import {ERC20} from "@openzeppelin/contracts/...";
import {Ownable2Step} from "@openzeppelin/contracts/...";
```

OZ contracts are heavily audited. Using them = safer.

### ✅ Green flag 2: Custom errors instead of strings

```solidity
error InsufficientBalance(uint256 requested, uint256 available);
// Better than: require(false, "InsufficientBalance");
```

Shows attention to detail + gas optimization.

### ✅ Green flag 3: ReentrancyGuard

```solidity
contract MyContract is ReentrancyGuard {
    function withdraw() external nonReentrant {
        // safe
    }
}
```

Active defense against reentrancy.

### ✅ Green flag 4: Pausable

```solidity
function transfer(...) external whenNotPaused {
```

Shows team thought about emergency response.

### ✅ Green flag 5: Caps and bounds

```solidity
uint16 public constant MAX_FEE_BPS = 100; // hard cap 1%
function setFee(uint16 newFee) external onlyOwner {
    require(newFee <= MAX_FEE_BPS, "exceeds cap");
}
```

Even if owner is malicious, bounded damage.

### ✅ Green flag 6: Multisig owner

Check `owner()` on Etherscan. If it's a Gnosis Safe (multiple owners), much safer than EOA.

### ✅ Green flag 7: Timelock

```solidity
import "@openzeppelin/contracts/governance/TimelockController.sol";
```

Owner changes wait N hours before taking effect.

## Module 4: Practical workflow (20 min)

### Step-by-step contract assessment (10 min per contract)

1. **(1 min) Verify contract is verified on Etherscan**
2. **(2 min) Check owner**: EOA / Multisig / DAO?
3. **(2 min) Scan for red flag functions**:
   - Search for: `onlyOwner`, `mint`, `withdraw`, `blacklist`, `upgrade`, `setFee`
4. **(2 min) Check key state variables**:
   - Read contract tab → `owner`, `totalSupply`, `paused`, `pendingUpgrade`
5. **(2 min) Check transaction history**:
   - Recent deploys? Frequent owner calls?
6. **(1 min) Cross-reference**:
   - Same address from official docs?
   - Community endorses?

### Pass-through checks (5 min per contract)

For most contracts you interact with daily:
- ✅ Has it been live > 6 months without incident?
- ✅ Used by other reputable protocols?
- ✅ Listed on Defi Llama?
- ✅ Has bug bounty on Immunefi?
- ✅ Has at least 1 public audit report?

If ≥3 yes → reasonable confidence.

### Deep dive for new contracts (1-2 hours)

For contracts you'll commit > $1000 to:
1. Read EVERY public function
2. Check ALL imports
3. Read audit reports (if any)
4. Check past exploits of similar protocols
5. Ask in Discord: anyone else use this?

## Module 5: Tools to help (10 min)

### Free tools

| Tool | Use case |
|------|----------|
| **Etherscan/Basescan** | View verified source |
| **DeFi Safety** | Pre-computed safety scores |
| **De.Fi Scanner** | Auto contract scan |
| **Tenderly** | Trace transactions |
| **Slither (local)** | Static analysis if you have source |
| **Surya** | Generate function graphs |
| **DethCrypto Storage Layout** | View storage layout (proxy concerns) |

### Paid tools (optional)

- **Tenderly Pro** ($50-500/mo): Real-time monitoring
- **OpenZeppelin Defender** (free tier exists): Operations + monitoring
- **Forta** (free for users): Real-time alerts

## TL;DR

1. **Verified source code** on Etherscan = minimum bar
2. **Check `owner()`** — is it a single EOA? Run away.
3. **Look for red flag functions**: mint without cap, upgrade without timelock, blacklist
4. **Look for green flags**: OZ imports, Pausable, ReentrancyGuard, bounded admin powers
5. **Cross-reference** with community, audit reports, transaction history
6. **For > $1K commitment, deep dive**

**You can never be 100% safe.** But basic contract reading filters out 80% of scams.
