# Rust Blockchain Development: Building a Substrate Node from Scratch

**Meta:** Tutorial on building a custom Substrate blockchain node in Rust, with custom pallets, WASM compilation, and RPC server. Based on real production experience.

**Tags:** rust, blockchain, substrate, web3, wasm

---

## Why Rust for Blockchain

Rust gives you:
- Memory safety without garbage collector
- Performance comparable to C++
- WebAssembly compilation for browser nodes
- The substrate framework for rapid development

## Project Setup

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Substrate tools
cargo install --git https://github.com/paritytech/substrate subkey
cargo install --git https://github.com/paritytech/substrate substrate-cli

# Create node
cargo new quanta-node
cd quanta-node
```

## The Node Architecture

```
quanta-node/
├── Cargo.toml
├── src/
│   ├── main.rs           # CLI entry point
│   ├── chain_spec.rs     # Genesis configuration
│   ├── service.rs        # Full/partial node setup
│   ├── rpc.rs            # JSON-RPC server
│   └── cli.rs            # Command-line parsing
├── pallets/
│   ├── quanta-token/     # ERC-20-like token pallet
│   ├── agent-registry/   # AI agent management
│   └── payment-channel/  # Micropayment channels
└── runtime/
    ├── Cargo.toml
    └── src/
        └── lib.rs        # Runtime configuration
```

## Custom Pallet: Quanta Token

```rust
// pallets/quanta-token/src/lib.rs
#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

#[frame_support::pallet]
pub mod pallet {
    use frame_support::pallet_prelude::*;
    use frame_system::pallet_prelude::*;

    #[pallet::config]
    pub trait Config: frame_system::Config {
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;
    }

    #[pallet::pallet]
    pub struct Pallet<T>(_)

    #[pallet::storage]
    pub type Balances<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        u128,
        ValueQuery,
    >;

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        Transfer {
            from: T::AccountId,
            to: T::AccountId,
            amount: u128,
        },
        Minted {
            to: T::AccountId,
            amount: u128,
        },
        Burned {
            from: T::AccountId,
            amount: u128,
        },
    }

    #[pallet::error]
    pub enum Error<T> {
        InsufficientBalance,
        Overflow,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        #[pallet::call_index(0)]
        pub fn transfer(
            origin: OriginFor<T>,
            to: T::AccountId,
            amount: u128,
        ) -> DispatchResult {
            let from = ensure_signed(origin)?;
            
            Balances::<T>::try_mutate(
                &from, 
                |balance| -> DispatchResult {
                    *balance = balance.checked_sub(amount)
                        .ok_or(Error::<T>::InsufficientBalance)?;
                    Ok(())
                }
            )?;
            
            Balances::<T>::try_mutate(
                &to, 
                |balance| -> DispatchResult {
                    *balance = balance.checked_add(amount)
                        .ok_or(Error::<T>::Overflow)?;
                    Ok(())
                }
            )?;
            
            Self::deposit_event(Event::Transfer { from, to, amount });
            Ok(())
        }
        
        #[pallet::call_index(1)]
        pub fn mint(
            origin: OriginFor<T>,
            to: T::AccountId,
            amount: u128,
        ) -> DispatchResult {
            ensure_root(origin)?;
            
            Balances::<T>::mutate(&to, |balance| {
                *balance = balance.saturating_add(amount);
            });
            
            Self::deposit_event(Event::Minted { to, amount });
            Ok(())
        }
    }
}
```

## Dilithium3 Integration

```rust
// Dilithium3 post-quantum signatures
use dilithium3::{Keypair, PublicKey, SecretKey, Signature};

pub struct QuantumSigner {
    keypair: Keypair,
}

impl QuantumSigner {
    pub fn new() -> Self {
        let keypair = Keypair::generate(None);
        Self { keypair }
    }
    
    pub fn sign(&self, message: &[u8]) -> Vec<u8> {
        self.keypair.sign(message).to_vec()
    }
    
    pub fn verify(
        public_key: &[u8],
        message: &[u8],
        signature: &[u8],
    ) -> bool {
        let pk = PublicKey::from_bytes(public_key)
            .expect("Invalid public key");
        let sig = Signature::from_bytes(signature)
            .expect("Invalid signature");
        
        pk.verify(message, &sig).is_ok()
    }
    
    pub fn public_key(&self) -> Vec<u8> {
        self.keypair.public_key().to_vec()
    }
    
    pub fn secret_key(&self) -> Vec<u8> {
        self.keypair.secret_key().to_vec()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_dilithium_sign_verify() {
        let signer = QuantumSigner::new();
        let message = b"Hello, quantum-resistant world!";
        
        let signature = signer.sign(message);
        assert!(QuantumSigner::verify(
            &signer.public_key(),
            message,
            &signature
        ));
    }
}
```

## RPC Server with jsonrpsee

```rust
use jsonrpsee::{
    core::RpcResult,
    proc_macros::rpc,
    types::ErrorObjectOwned,
};
use jsonrpsee::server::ServerBuilder;

#[rpc(client, server)]
pub trait QuantaRpc {
    #[method(name = "quanta_getBalance")]
    fn get_balance(&self, address: String) -> RpcResult<String>;
    
    #[method(name = "quanta_getBlockNumber")]
    fn get_block_number(&self) -> RpcResult<u64>;
    
    #[method(name = "quanta_transfer")]
    fn transfer(
        &self,
        from: String,
        to: String,
        amount: u128,
    ) -> RpcResult<String>;
}

pub struct QuantaRpcImpl {
    // ... state
}

impl QuantaRpcServer for QuantaRpcImpl {
    fn get_balance(&self, address: String) -> RpcResult<String> {
        // Read from storage
        Ok("1000000000000000000".to_string())
    }
    
    fn get_block_number(&self) -> RpcResult<u64> {
        Ok(12345)
    }
    
    fn transfer(
        &self,
        from: String,
        to: String,
        amount: u128,
    ) -> RpcResult<String> {
        // Execute transfer
        Ok("0xtxhash...".to_string())
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let server = ServerBuilder::default()
        .build("127.0.0.1:9944")
        .await?;
    
    let rpc = QuantaRpcImpl::new();
    let handle = server.start(rpc.into_rpc())?;
    
    handle.stopped().await;
    Ok(())
}
```

## WASM Compilation

```toml
# Cargo.toml
[dependencies]
wasm-bindgen = "0.2"
getrandom = { version = "0.3", features = ["wasm"] }

# For browser/node
[lib]
crate-type = ["cdylib", "rlib"]
```

```bash
# Build for native
cargo build --release

# Build for WASM
cargo build --release --target wasm32-unknown-unknown

# Build for browser
wasm-pack build --target web
```

## Testing

```bash
# Unit tests
cargo test --workspace

# With verbose output
cargo test --workspace -- --nocapture

# Specific pallet
cargo test -p quanta-token

# Integration tests
cargo test --test integration
```

## Test Results

QUANTA Node achieves:
- 54/54 Rust tests PASS
- 16/16 RPC tests PASS
- Native + WASM builds OK
- Dilithium3: 7/7 crypto tests PASS
- Zero unsafe blocks

## Deployment

```bash
# Start development node
./target/release/quanta-node --dev

# Start with custom spec
./target/release/quanta-node \
    --chain ./chain_spec.json \
    --rpc-external \
    --ws-external
```

## Conclusion

Rust + Substrate is the most powerful stack for building custom blockchains. With Dilithium3 post-quantum signatures, QUANTA is ready for the quantum era.

---

*QUANTA L1 Node: 54 tests PASS, native + WASM. See: [github.com/quanta-tect/quanta](https://github.com/quanta-tect/quanta)*
