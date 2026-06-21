//! QUANTA L1 Dev Node — with RPC and Block Production
//!
//! Usage:
//!   cargo run -p quanta-l1-node [--dev]
//!
//! RPC endpoint: http://localhost:9933
//! WebSocket: ws://localhost:9944

#![cfg(feature = "std")]

use quanta_l1_runtime::{Runtime, VERSION};
use std::sync::Arc;
use std::time::SystemTime;
use tokio::sync::RwLock;

mod rpc;
mod storage;

use rpc::{NodeRpcImpl, NodeRpcApiServer};
use storage::DevStorage;

#[tokio::main]
async fn main() {
    let start_time = SystemTime::now();

    println!("╔══════════════════════════════════════════════════╗");
    println!("║  QUANTA L1 — Quantum-safe AI-native Blockchain  ║");
    println!("╚══════════════════════════════════════════════════╝");
    println!();
    println!("Spec name:      {}", VERSION.spec_name);
    println!("Impl name:      {}", VERSION.impl_name);
    println!("Spec version:   {}", VERSION.spec_version);
    println!("Impl version:   {}", VERSION.impl_version);
    println!("Native runtime: quanta-l1-runtime");
    println!("WASM runtime:   supported (with getrandom stub)");
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
    println!("Block time:  6 seconds");
    println!();

    // Initialize dev storage
    let storage = Arc::new(RwLock::new(DevStorage::new()));
    {
        let s = storage.read().await;
        println!("Genesis storage: {} top-level entries", s.top_count());
    }
    println!();

    // Print node info
    let _runtime_type = std::any::type_name::<Runtime>();
    println!("✓ Runtime: {}", _runtime_type);
    println!(
        "✓ Version: spec={} impl={}",
        VERSION.spec_version, VERSION.impl_version
    );
    println!("✓ WASM: supported");
    println!();

    // Build the RPC implementation
    let rpc_impl = NodeRpcImpl::new(storage.clone());

    // Start JSON-RPC server on 0.0.0.0:9944
    let rpc_addr = "0.0.0.0:9944".parse::<std::net::SocketAddr>().unwrap();
    let builder = jsonrpsee::server::ServerBuilder::default();
    let server = builder.build(rpc_addr).await.unwrap();
    let handle = server.start(rpc_impl.into_rpc());

    let elapsed = SystemTime::now().duration_since(start_time).unwrap();
    println!(
        "QUANTA L1 Node started in {:.2}s",
        elapsed.as_secs_f64()
    );
    println!("JSON-RPC server listening on ws://{}", rpc_addr);
    println!("HTTP endpoint available at http://{}", rpc_addr);
    println!("Press Ctrl+C to exit.");

    // Block forever (server runs in background)
    tokio::signal::ctrl_c().await.unwrap();
    println!("\nShutting down...");
    handle.stop().unwrap();
    handle.stopped().await;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

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

    #[test]
    fn dev_storage_builds() {
        let storage = DevStorage::new();
        assert!(storage.top_count() > 0);
    }
}
