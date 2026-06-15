# Code Scaffold

## Cấu trúc thư mục
l1/
├── crypto/dilithium.rs        # Dilithium wrapper
├── pallets/
│   ├── pallet-pq-balances/    # Balances với PQ sig
│   ├── pallet-pq-dilithium/   # PQ crypto pallet
│   └── pallet-pq-staking/     # Staking với PQ sig
├── runtime/src/lib.rs         # Runtime
└── node/src/                  # Node service

## Dependencies
- Substrate (Polkadot SDK)
- qp-dilithium-crypto
- pqc-combo
