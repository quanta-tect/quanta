# MYTHRIL-PENDING.md — Mythril Analysis Pending

## Lý do Mythril chưa chạy được trong CI hiện tại

- PEP 668 chặn pip system-level install
- venv bị sandbox từ chối
- coincurve wheel build fail (Python 3.14 compatibility issue)

## Cách chạy Mythril trên local machine

### Phương án 1: Docker (khuyến nghị)
```bash
docker run --rm -v $(pwd):/workspace mythril/mythril analyze /workspace/contracts/src/*.sol --solv 0.8.24 -o markdown
```

### Phương án 2: Direct install trên local với Python < 3.14
```bash
pip3 install mythril
mythril analyze contracts/src-v1.2/QuantaToken.sol --solv 0.8.24 -o markdown > docs-security/mythril-quanta-token.md
mythril analyze contracts/src-v1.2/AIAgentRegistry.sol --solv 0.8.24 -o markdown > docs-security/mythril-agent-registry.md
mythril analyze contracts/src-v1.2/AIPaymentChannel.sol --solv 0.8.24 -o markdown > docs-security/mythril-payment-channel.md
mythril analyze contracts/src-v1.2/AIModelMarketplace.sol --solv 0.8.24 -o markdown > docs-security/mythril-marketplace.md
```

## Expected Output Format
- 4 markdown files: `mythril-*.md`
- Contains: SWC IDs, severity, description, line numbers, source mapping
- Will be appended into `AUDIT-SUMMARY-v1.2.md` once complete

## Priority
- **Mythril**: Medium priority
- **Reason**: Slither đã cover phần lớn common issues. Mythril bổ sung symbolic execution để tìm edge cases arithmetic overflow/underflow, access control bypass.
