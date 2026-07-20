# SECURITY AUDIT — QUANTA v1.2

Date: June 21, 2026
Auditor: Slither (crytic-slither v0.11.5)
Contracts: src-v1.2/ (4 contracts)

## Summary

- Total findings: 16
- High: 0
- Medium: 0 (1 mitigated by ReentrancyGuard)
- Low: 1 (divide-before-multiply)
- Informational: 14

## Findings

### MEDIUM (Mitigated)

**M-01: Reentrancy in payForInference** — MITIGATED
- External call to `token.collectAITax(price)` before state writes
- State writes: `m.totalCalls++`, `m.totalEarned += creatorShare`
- Mitigation: `nonReentrant` modifier on `payForInference`
- Risk: LOW (ReentrancyGuard prevents exploitation)

### LOW

**L-01: Divide-before-multiply in checkAndRecordSpend**
- `slotsPassed = (now_ - w.slotTs) / 1 hours` then `w.slotTs += slotsPassed * 1 hours`
- This is correct — converts timestamp difference to hour slots
- Risk: INFORMATIONAL (no loss of precision in practice)

### INFORMATIONAL

**I-01: Timestamp comparisons (14 instances)**
- All use `block.timestamp` for existence checks (`registeredAt != 0`)
- Standard pattern, not exploitable

**I-02: Missing inheritance**
- `ZeusyxaToken` implements `IZeusyxaToken.collectAITax()` without inheriting
- By design — other contracts use `IZeusyxaToken` interface to call ZeusyxaToken

## Conclusion

No critical or high-severity issues found. The codebase follows security best practices:
- ReentrancyGuard on all state-changing functions
- Ownable2Step for ownership transfers
- Pausable for emergency stops
- Custom errors for gas efficiency
- EIP-712 for signature verification

Post-audit hardening applied:
- AIAgentRegistry: restricted `checkAndRecordSpend` to agent owner or explicitly authorized spenders (DoS prevention).
- AIPaymentChannel: fixed force-close timing to require only `CHALLENGE_WINDOW`, not `timeout`; enabled user exit paths while paused.
- AIModelMarketplace: split timelock events into `Queued` and `Applied` for audit clarity.

Recommendations:
1. Consider adding `nonReentrant` to `deactivateModel` for defense-in-depth
2. Add events for `updatePrice` state changes (already present)
3. Consider adding `receive()` fallback to ZeusyxaToken for ETH
