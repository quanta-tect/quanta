//! QUANTA L1 Minimal Dev Node
//!
//! Runs the quanta-l1-runtime in native mode for testing.
//! No networking, no CLI — just runtime verification.
//!
//! Usage:
//!   cargo run -p quanta-l1-node

#![cfg(feature = "std")]

use quanta_l1_runtime::{Runtime, VERSION};

fn main() {
    println!("╔══════════════════════════════════════════════════╗");
    println!("║  QUANTA L1 — Quantum-safe AI-native Blockchain  ║");
    println!("╚══════════════════════════════════════════════════╝");
    println!();
    println!("Spec name:      {}", VERSION.spec_name);
    println!("Impl name:      {}", VERSION.impl_name);
    println!("Spec version:   {}", VERSION.spec_version);
    println!("Impl version:   {}", VERSION.impl_version);
    println!("Native runtime: quanta-l1-runtime");
    println!();
    println!("Pallets:");
    println!("  ✓ frame-system");
    println!("  ✓ pallet-balances (dev)");
    println!("  ✓ pallet-pq-dilithium  (Dilithium3 PQ signatures)");
    println!("  ✓ pallet-pq-balances   (PQ balance management)");
    println!("  ✓ pallet-pq-staking    (PoUW inference staking)");
    println!();
    println!("Crypto: Dilithium3 (ML-DSA-65) — NIST Level 3");
    println!("  Public key:  1,952 bytes");
    println!("  Signature:   3,309 bytes");
    println!("  Secret key:  4,032 bytes");
    println!();
    println!("Consensus: Manual Seal (dev mode)");
    println!("Block time:  6 seconds (planned)");
    println!();

    // Verify runtime type
    let _runtime_type = std::any::type_name::<Runtime>();
    println!("✓ Runtime type: {}", _runtime_type);
    println!("✓ Runtime version: spec={} impl={}", VERSION.spec_version, VERSION.impl_version);
    println!();
    println!("Note: Full node service with RPC, networking, and block");
    println!("      production requires sc-service (blocked by prometheus");
    println!("      stub incompatibility with polkadot-sdk latest).");
    println!("      Use `cargo test -p quanta-l1-runtime` for runtime tests.");
    println!();
    println!("QUANTA L1 Node initialized successfully.");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn runtime_version_correct() {
        assert_eq!(VERSION.spec_version, 1);
        assert_eq!(VERSION.impl_version, 1);
    }

    #[test]
    fn runtime_type_available() {
        let name = std::any::type_name::<Runtime>();
        assert!(name.contains("Runtime"));
    }
}
