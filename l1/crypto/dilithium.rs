// ================================================================
// 🔐 Dilithium Wrapper — REAL CRYPTO using pqc-combo (v2)
// ================================================================

#![cfg_attr(not(feature = "std"), no_std)]

extern crate alloc;
use alloc::vec::Vec;
use core::cmp::min;

use codec::{Decode, Encode, MaxEncodedLen};
use scale_info::TypeInfo;
use sp_runtime::traits::{IdentifyAccount, Verify};

// ================================================================
// CONSTANTS — Dilithium3 (ML-DSA-65) | NIST Level 3
// ================================================================
pub const DILITHIUM_PUBLIC_KEY_LEN: usize = 1952;
pub const DILITHIUM_SECRET_KEY_LEN: usize = 4032;
pub const DILITHIUM_SIGNATURE_LEN: usize = 3309;

// ================================================================
// TYPES
// ================================================================

/// Dilithium3 Public Key (1,952 bytes)
#[derive(Clone, Eq, PartialEq, Debug, Encode, Decode, TypeInfo, MaxEncodedLen)]
pub struct DilithiumPublicKey(pub [u8; DILITHIUM_PUBLIC_KEY_LEN]);

/// Dilithium3 Signature (3,309 bytes)
#[derive(Clone, Eq, PartialEq, Debug, Encode, Decode, TypeInfo, MaxEncodedLen)]
pub struct DilithiumSignature(pub [u8; DILITHIUM_SIGNATURE_LEN]);

/// Dilithium Secret Key (4,032 bytes) — CHỈ dùng ngoài runtime, KHÔNG lưu on-chain
/// Cố tình KHÔNG derive Encode/Decode để compiler báo lỗi nếu ai cố serialize
#[derive(Clone, Debug)]
pub struct DilithiumSecretKey(pub [u8; DILITHIUM_SECRET_KEY_LEN]);

/// Key pair
#[derive(Clone, Debug)]
pub struct DilithiumKeyPair {
    pub public: DilithiumPublicKey,
    pub secret: DilithiumSecretKey,
}

// ================================================================
// DEFAULT IMPLEMENTATIONS
// ================================================================

impl Default for DilithiumPublicKey {
    fn default() -> Self { Self([0u8; DILITHIUM_PUBLIC_KEY_LEN]) }
}
impl Default for DilithiumSignature {
    fn default() -> Self { Self([0u8; DILITHIUM_SIGNATURE_LEN]) }
}
impl Default for DilithiumSecretKey {
    fn default() -> Self { Self([0u8; DILITHIUM_SECRET_KEY_LEN]) }
}

// ================================================================
// SUBSTRATE TRAITS
// ================================================================

impl Verify for DilithiumSignature {
    type Signer = DilithiumPublicKey;

    fn verify<L: sp_runtime::traits::Lazy<[u8]>>(
        &self,
        mut msg: L,
        signer: &Self::Signer,
    ) -> bool {
        let message = msg.get();
        verify_dilithium_signature(message, &self.0, &signer.0)
    }
}

impl IdentifyAccount for DilithiumPublicKey {
    type AccountId = Self;
    fn into_account(self) -> Self::AccountId { self }
}

// ================================================================
// CORE FUNCTIONS — Dùng pqc-combo THẬT
// ================================================================

/// Tạo key pair Dilithium3
pub fn generate_keypair() -> DilithiumKeyPair {
    let (pk_vec, sk_vec) = pqc_combo::generate_dilithium_keypair();
    let mut pk = [0u8; DILITHIUM_PUBLIC_KEY_LEN];
    let mut sk = [0u8; DILITHIUM_SECRET_KEY_LEN];
    let pk_len = min(pk_vec.len(), DILITHIUM_PUBLIC_KEY_LEN);
    let sk_len = min(sk_vec.len(), DILITHIUM_SECRET_KEY_LEN);
    pk[..pk_len].copy_from_slice(&pk_vec[..pk_len]);
    sk[..sk_len].copy_from_slice(&sk_vec[..sk_len]);
    DilithiumKeyPair { public: DilithiumPublicKey(pk), secret: DilithiumSecretKey(sk) }
}

/// Ký message
pub fn sign_message(message: &[u8], secret_key: &DilithiumSecretKey) -> DilithiumSignature {
    let sk_vec: Vec<u8> = secret_key.0.to_vec();
    let sig_vec = pqc_combo::sign_message(&sk_vec, message);
    let mut sig = [0u8; DILITHIUM_SIGNATURE_LEN];
    let len = min(sig_vec.len(), DILITHIUM_SIGNATURE_LEN);
    sig[..len].copy_from_slice(&sig_vec[..len]);
    DilithiumSignature(sig)
}

/// Verify signature
pub fn verify_dilithium_signature(
    message: &[u8],
    signature: &[u8; DILITHIUM_SIGNATURE_LEN],
    public_key: &[u8; DILITHIUM_PUBLIC_KEY_LEN],
) -> bool {
    let pk_vec: Vec<u8> = public_key.to_vec();
    let sig_vec: Vec<u8> = signature.to_vec();
    pqc_combo::verify_signature(&pk_vec, message, &sig_vec)
}

/// Tạo keypair từ seed — CHỈ dùng cho test
/// WARNING: pqc-combo chưa hỗ trợ deterministic keygen
pub fn keypair_from_seed(_seed: &[u8]) -> DilithiumKeyPair {
    generate_keypair()
}

// ================================================================
// ADDRESS ENCODING — Dạng QR + hex (sẽ cải tiến thành SS58 sau)
// ================================================================

pub fn dilithium_to_address(public_key: &DilithiumPublicKey) -> alloc::string::String {
    let hex: alloc::string::String = public_key.0.iter()
        .map(|b| alloc::format!("{:02x}", b))
        .collect();
    let end = if hex.len() > 40 { 40 } else { hex.len() };
    alloc::format!("QR{}", &hex[..end])
}

// ================================================================
// TESTS
// ================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keypair() {
        let kp = generate_keypair();
        assert_ne!(kp.public, DilithiumPublicKey::default());
    }

    #[test]
    fn test_sign_verify() {
        let kp = generate_keypair();
        let msg = b"QuantumResist Transfer";
        let sig = sign_message(msg, &kp.secret);
        assert!(verify_dilithium_signature(msg, &sig.0, &kp.public.0));
    }

    #[test]
    fn test_wrong_key_fails() {
        let kp1 = generate_keypair();
        let kp2 = generate_keypair();
        let sig = sign_message(b"test", &kp1.secret);
        assert!(!verify_dilithium_signature(b"test", &sig.0, &kp2.public.0));
    }

    #[test]
    fn test_tampered_message_fails() {
        let kp = generate_keypair();
        let sig = sign_message(b"original", &kp.secret);
        assert!(!verify_dilithium_signature(b"tampered", &sig.0, &kp.public.0));
    }

    #[test]
    fn test_address_format() {
        let kp = generate_keypair();
        let addr = dilithium_to_address(&kp.public);
        assert!(addr.starts_with("QR"));
        assert!(addr.len() > 2);
    }
}
