#![cfg_attr(not(feature = "std"), no_std)]

extern crate alloc;
use core::cmp::min;

use codec::{Decode, Encode, MaxEncodedLen};
use scale_info::TypeInfo;

use polkadot_sdk::sp_runtime::traits::{IdentifyAccount, Verify};
use polkadot_sdk::polkadot_sdk_frame::prelude::DecodeWithMemTracking;

use pqcrypto_dilithium::dilithium3::{PublicKey, SecretKey, SignedMessage, keypair, sign, open};
use pqcrypto_traits::sign::PublicKey as PubT;
use pqcrypto_traits::sign::SecretKey as SecT;
use pqcrypto_traits::sign::SignedMessage as SigT;

pub const DILITHIUM_PUBLIC_KEY_LEN: usize = 1952;
pub const DILITHIUM_SECRET_KEY_LEN: usize = 4032;
pub const DILITHIUM_SIGNATURE_LEN: usize = 3309;

#[derive(Clone, Eq, PartialEq, Debug, Encode, Decode, TypeInfo, MaxEncodedLen, DecodeWithMemTracking)]
pub struct DilithiumPublicKey(pub [u8; DILITHIUM_PUBLIC_KEY_LEN]);

#[derive(Clone, Eq, PartialEq, Debug, Encode, Decode, TypeInfo, MaxEncodedLen, DecodeWithMemTracking)]
pub struct DilithiumSignature(pub [u8; DILITHIUM_SIGNATURE_LEN]);

#[derive(Clone, Debug)]
pub struct DilithiumSecretKey(pub [u8; DILITHIUM_SECRET_KEY_LEN]);

#[derive(Clone, Debug)]
pub struct DilithiumKeyPair {
    pub public: DilithiumPublicKey,
    pub secret: DilithiumSecretKey,
}

impl Default for DilithiumPublicKey { fn default() -> Self { Self([0u8; DILITHIUM_PUBLIC_KEY_LEN]) } }
impl Default for DilithiumSignature { fn default() -> Self { Self([0u8; DILITHIUM_SIGNATURE_LEN]) } }
impl Default for DilithiumSecretKey { fn default() -> Self { Self([0u8; DILITHIUM_SECRET_KEY_LEN]) } }

impl Verify for DilithiumSignature {
    type Signer = DilithiumPublicKey;
    fn verify<L: polkadot_sdk::sp_runtime::traits::Lazy<[u8]>>(&self, mut msg: L, signer: &Self::Signer) -> bool {
        verify_dilithium_signature(msg.get(), &self.0, &signer.0)
    }
}

impl IdentifyAccount for DilithiumPublicKey {
    type AccountId = Self;
    fn into_account(self) -> Self::AccountId { self }
}

pub fn generate_keypair() -> DilithiumKeyPair {
    let (pk, sk) = keypair();
    let pk_b = <PublicKey as PubT>::as_bytes(&pk);
    let sk_b = <SecretKey as SecT>::as_bytes(&sk);
    let mut pk_arr = [0u8; DILITHIUM_PUBLIC_KEY_LEN];
    let mut sk_arr = [0u8; DILITHIUM_SECRET_KEY_LEN];
    let pke = min(pk_b.len(), DILITHIUM_PUBLIC_KEY_LEN);
    let ske = min(sk_b.len(), DILITHIUM_SECRET_KEY_LEN);
    pk_arr[..pke].copy_from_slice(&pk_b[..pke]);
    sk_arr[..ske].copy_from_slice(&sk_b[..ske]);
    DilithiumKeyPair { public: DilithiumPublicKey(pk_arr), secret: DilithiumSecretKey(sk_arr) }
}

pub fn sign_message(message: &[u8], secret: &DilithiumSecretKey) -> DilithiumSignature {
    let sk = <SecretKey as SecT>::from_bytes(&secret.0).expect("Invalid SK");
    let sm = sign(message, &sk);
    let sb = <SignedMessage as SigT>::as_bytes(&sm);
    let mut sig = [0u8; DILITHIUM_SIGNATURE_LEN];
    let e = min(sb.len(), DILITHIUM_SIGNATURE_LEN);
    sig[..e].copy_from_slice(&sb[..e]);
    DilithiumSignature(sig)
}

pub fn verify_dilithium_signature(
    _message: &[u8],
    signature: &[u8; DILITHIUM_SIGNATURE_LEN],
    public_key: &[u8; DILITHIUM_PUBLIC_KEY_LEN],
) -> bool {
    let pk = match <PublicKey as PubT>::from_bytes(public_key) { Ok(p) => p, Err(_) => return false };
    let sm = match <SignedMessage as SigT>::from_bytes(signature) { Ok(s) => s, Err(_) => return false };
    open(&sm, &pk).is_ok()
}

pub fn dilithium_to_address(pk: &DilithiumPublicKey) -> alloc::string::String {
    let hex: alloc::string::String = pk.0.iter().map(|b| alloc::format!("{:02x}", b)).collect();
    let end = if hex.len() > 40 { 40 } else { hex.len() };
    alloc::format!("QR{}", &hex[..end])
}
