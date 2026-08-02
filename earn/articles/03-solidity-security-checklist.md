# Solidity Security Audit Checklist: 15 Vulnerabilities to Check Before Mainnet

**Meta:** A practical checklist for Solidity smart contract security audits, covering reentrancy, access control, overflow, and post-quantum threats. Based on real audit experience.

**Tags:** solidity, security, smart-contracts, web3, auditing

---

## Why Most Audits Miss Things

I recently audited 4 smart contracts and found 20 issues using Slither + Mythril — but only 1 was a real concern (CEI pattern violation). The rest were informational. Here's what I learned about what actually matters.

## The 15-Point Checklist

### 1. Reentrancy (Critical)

```solidity
// ❌ VULNERABLE
function withdraw() external {
    uint256 bal = balances[msg.sender];
    (bool ok, ) = msg.sender.call{value: bal}("");
    require(ok);
    balances[msg.sender] = 0;  // State change AFTER external call
}

// ✅ FIXED (CEI Pattern)
function withdraw() external {
    uint256 bal = balances[msg.sender];
    balances[msg.sender] = 0;  // State change FIRST
    (bool ok, ) = msg.sender.call{value: bal}("");
    require(ok);
}
```

**Tool:** `slither --detect reentrancy-eth,reentrancy-no-eth`

### 2. Access Control

```solidity
// ❌ Missing onlyOwner
function emergencyWithdraw() external {
    // Anyone can drain funds!
    payable(msg.sender).transfer(address(this).balance);
}

// ✅ Fixed
function emergencyWithdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
}
```

### 3. Integer Overflow (Solidity 0.8+)

Solidity 0.8+ has built-in overflow checks. If you use `unchecked`, verify manually:

```solidity
// ⚠️ Dangerous if unchecked
unchecked {
    uint256 result = a - b;  // Underflow possible
}
```

### 4. Front-Running

```solidity
// ❌ Vulnerable to front-run
function buy(uint256 amount) external {
    uint256 price = getQuote(amount);
    token.transferFrom(msg.sender, address(this), price);
}

// ✅ Commit-reveal or slippage protection
function buy(
    uint256 amount, 
    uint256 maxPrice
) external {
    uint256 price = getQuote(amount);
    require(price <= maxPrice, "Slippage exceeded");
    token.transferFrom(msg.sender, address(this), price);
}
```

### 5. Signature Replay

```solidity
// ❌ No nonce tracking
function execute(
    address to, 
    uint256 amount, 
    bytes calldata sig
) external {
    bytes32 hash = keccak256(abi.encode(to, amount));
    // Same sig can be reused!
}

// ✅ Nonce-based
mapping(address => uint256) public nonces;

function execute(
    address to, 
    uint256 amount, 
    bytes calldata sig
) external {
    uint256 nonce = nonces[msg.sender]++;
    bytes32 hash = keccak256(
        abi.encode(to, amount, nonce)
    );
    // Each signature is unique
}
```

### 6. Unchecked Return Values

```solidity
// ❌ Transfer might fail silently
token.transfer(receiver, amount);

// ✅ Check return value
bool success = token.transfer(receiver, amount);
require(success, "Transfer failed");
```

### 7. Timestamp Dependence

Don't use `block.timestamp` for randomness or critical logic:

```solidity
// ❌ Miners can manipulate by ~15 seconds
uint256 random = uint256(keccak256(abi.encode(block.timestamp)));

// ✅ Use Chainlink VRF for randomness
```

### 8. Denial of Service

```solidity
// ❌ Array can grow unbounded
address[] public users;

function addUser(address user) external {
    users.push(user);  // Gas limit risk
}

// ✅ Use mapping for O(1) lookup
mapping(address => bool) public isUser;
```

### 9. Centralization Risk

```solidity
// ❌ Single point of failure
address public owner;
function changePrice(uint256 p) external {
    require(msg.sender == owner);
    price = p;
}

// ✅ Multisig + timelock
IMultisig public multisig;
ITimelock public timelock;
```

### 10. Flash Loan Attacks

```solidity
// ❌ Price oracle manipulation in single tx
function liquidate(address user) external {
    uint256 collateral = getOraclePrice(); // Can be manipulated
    // ...
}

// ✅ Use TWAP or multi-block oracle
```

### 11. Self-Destruct

```solidity
// ❌ Can destroy contract
selfdestruct(payable(msg.sender));

// ✅ Remove or guard with multisig + timelock
```

### 12. Delegatecall to Untrusted

```solidity
// ❌ Attacker contract can take over
address impl = userProvidedAddress;
impl.delegatecall(data);

// ✅ Only delegate to trusted contracts
```

### 13. ERC20 approve Race Condition

```solidity
// ❌ Race condition
token.approve(spender, 100);
// User changes to 50, but spender front-runs and spends both

// ✅ Increase/Decrease pattern
token.increaseAllowance(spender, 50);
```

### 14. Short Address Attack

Use proper ABI encoding — don't rely on raw calldata:

```solidity
// ✅ Solidity handles this automatically with typed params
function transfer(address to, uint256 amount) external;
```

### 15. Post-Quantum Threats

ECDSA signatures are vulnerable to quantum computers (Shor's algorithm). Consider:

```solidity
// Future-proof: Dilithium3 signatures
// Public key: 1,952 bytes
// Signature: 3,293 bytes
// Quantum-resistant: ✅
```

## Tools I Use

| Tool | Purpose | Cost |
|------|---------|------|
| Slither | Static analysis | Free |
| Mythril | Symbolic execution | Free |
| Foundry fuzz | Fuzz testing | Free |
| Echidna | Property-based testing | Free |
| Aderyn | Static analysis (Rust) | Free |

## Audit Report Template

```markdown
## Executive Summary
- Contracts audited: 4
- Total lines: 2,500
- Findings: 20 (0 critical, 0 high, 1 medium, 19 informational)

## Findings

### [M-01] CEI Pattern Violation in closeChannel
- Severity: Medium
- Location: AIPaymentChannel.sol:142
- Description: External call before state update
- Recommendation: Move state update before transfer
- Status: FIXED
```

## Conclusion

Security is a process, not a product. Use this checklist before every deployment. Run Slither + Mythril on every PR. And remember: the best audit is the one you do yourself first.

---

*QUANTA Protocol passed Slither (20 benign) + Mythril (0 issues). See: [github.com/quanta-tect/quanta](https://github.com/quanta-tect/quanta)*
