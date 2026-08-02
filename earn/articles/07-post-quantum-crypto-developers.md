# Post-Quantum Cryptography for Developers: A Practical Guide

**Meta:** Developer-friendly guide to post-quantum cryptography. Learn Dilithium3, Kyber, and how to implement quantum-resistant signatures in Rust and Solidity.

**Tags:** post-quantum, cryptography, dilithium, rust, security

---

## Why You Should Care

Quantum computers will break:
- **RSA** (2048-bit) → broken in hours
- **ECDSA** (secp256k1, used by Bitcoin/Ethereum) → broken in minutes
- **Ed25519** (used by Solana) → broken in hours

Timeline: 5-15 years. NIST standardized post-quantum algorithms in August 2024.

## The NIST Standards

| Algorithm | Type | Use Case | Standard |
|-----------|------|----------|----------|
| **Dilithium** | Digital signature | Transactions, auth | FIPS 204 |
| **Kyber** | Key exchange | Encryption, TLS | FIPS 203 |
| **SPHINCS+** | Hash signature | Backup, archival | FIPS 205 |

## Dilithium3 in Rust

### Installation

```toml
# Cargo.toml
[dependencies]
dilithium3 = "0.2"
```

### Basic Usage

```rust
use dilithium3::{Keypair, PublicKey, Signature};

// Generate keypair
let keypair = Keypair::generate(None);

// Get keys
let public_key = keypair.public_key();  // 1,952 bytes
let secret_key = keypair.secret_key();  // 4,032 bytes

// Sign message
let message = b"Transfer 100 QTA to Alice";
let signature = keypair.sign(message);  // 3,293 bytes

// Verify signature
let pk = PublicKey::from_bytes(public_key.as_ref()).unwrap();
let sig = Signature::from_bytes(signature.as_ref()).unwrap();

assert!(pk.verify(message, &sig).is_ok());
```

### Size Comparison

| Property | ECDSA | Dilithium3 |
|----------|-------|------------|
| Public key | 33 bytes | 1,952 bytes |
| Signature | 64 bytes | 3,293 bytes |
| **Total** | **97 bytes** | **5,245 bytes** |

The trade-off: larger signatures, but quantum-resistant.

### Performance

```rust
use std::time::Instant;

let keypair = Keypair::generate(None);
let message = b"benchmark message";

// Sign: ~0.1ms
let start = Instant::now();
let signature = keypair.sign(message);
println!("Sign: {:?}", start.elapsed());

// Verify: ~0.1ms
let start = Instant::now();
keypair.public_key().verify(message, &signature);
println!("Verify: {:?}", start.elapsed());
```

## Kyber (Key Encapsulation)

```rust
use kyber::{keypair, encapsulate, decapsulate};

// Generate keypair
let (pk, sk) = keypair();

// Encapsulate (create shared secret)
let (ciphertext, shared_secret) = encapsulate(&pk);

// Decapsulate (recover shared secret)
let recovered_secret = decapsulate(&ciphertext, &sk);

assert_eq!(shared_secret, recovered_secret);
```

## Solidity Integration

Since Dilithium keys are too large for standard Ethereum, we use a hybrid approach:

```solidity
// Hybrid signature: ECDSA + Dilithium hash
contract HybridVerifier {
    // ECDSA for on-chain verification (fast, small)
    // Dilithium for off-chain verification (quantum-safe)
    
    mapping(address => bytes32) public dilithiumPubKeyHash;
    
    function registerKey(
        bytes32 ecdsaKey,
        bytes32 dilithiumHash
    ) external {
        dilithiumPubKeyHash[msg.sender] = dilithiumHash;
    }
    
    function verifyHybrid(
        address signer,
        bytes32 messageHash,
        bytes calldata ecdsaSig,
        bytes calldata dilithiumSig
    ) external view returns (bool) {
        // 1. Verify ECDSA (on-chain, fast)
        bytes32 ecdsaHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            messageHash
        ));
        address recovered = ecrecover(
            ecdsaHash, 
            uint8(ecdsaSig[64]), 
            bytes32(ecdsaSig[:32]), 
            bytes32(ecdsaSig[32:64])
        );
        
        if (recovered != signer) return false;
        
        // 2. Verify Dilithium hash (off-chain, quantum-safe)
        bytes32 dilithiumHash = keccak256(dilithiumSig);
        if (dilithiumHash != dilithiumPubKeyHash[signer]) {
            return false;
        }
        
        return true;
    }
}
```

## Migration Strategy

### Phase 1: Hybrid (Now)
Use ECDSA + Dilithium together. ECDSA for on-chain, Dilithium for off-chain.

### Phase 2: Dilithium-Only (When ready)
Replace ECDSA with Dilithium for all signatures.

### Phase 3: Full PQC (Mainnet)
All keys and signatures are post-quantum.

## QUANTA's Approach

QUANTA uses Dilithium3 for:
- Agent wallet signatures
- Payment channel signatures
- Model registry signatures

And ECDSA for:
- On-chain contract interactions (gas efficient)
- L2 transactions (Base Sepolia)

This hybrid approach gives quantum resistance without sacrificing performance.

## Testing Your Implementation

```bash
# Run Dilithium tests
cargo test -p dilithium3

# Benchmark
cargo bench -p dilithium3

# Fuzz testing
cargo fuzz run dilithium_sign
```

## Resources

- [NIST FIPS 204 (Dilithium)](https://csrc.nist.gov/publications/detail/fips/204/final)
- [NIST FIPS 203 (Kyber)](https://csrc.nist.gov/publications/detail/fips/203/final)
- [PQShield](https://pqshield.com/)
- [QUANTA Protocol](https://github.com/quanta-tect/quanta)

## Conclusion

Post-quantum cryptography isn't future — it's now. Start migrating your keys and signatures today. Your future self will thank you.

---

*QUANTA uses Dilithium3 (NIST FIPS 204) for all agent signatures. See: [github.com/quanta-tect/quanta](https://github.com/quanta-tect/quanta)*
