#![cfg_attr(not(feature = "std"), no_std)]

extern crate alloc;
use core::cmp::min;

use codec::{Decode, Encode, MaxEncodedLen};
use scale_info::TypeInfo;

use sp_runtime::traits::{IdentifyAccount, Verify, Lazy};
use codec::DecodeWithMemTracking;

use pqcrypto_dilithium::dilithium3::{PublicKey, SecretKey, SignedMessage, keypair, sign, open};
use pqcrypto_traits::sign::PublicKey as PubT;
use pqcrypto_traits::sign::SecretKey as SecT;
use pqcrypto_traits::sign::SignedMessage as SigT;

pub const DILITHIUM_PUBLIC_KEY_LEN: usize = 1952;
pub const DILITHIUM_SECRET_KEY_LEN: usize = 4032;
pub const DILITHIUM_SIGNATURE_LEN: usize = 3309;

#[derive(Clone, Eq, PartialEq, PartialOrd, Ord, Debug, Encode, Decode, TypeInfo, MaxEncodedLen, DecodeWithMemTracking)]
pub struct DilithiumPublicKey(pub [u8; DILITHIUM_PUBLIC_KEY_LEN]);

#[derive(Clone, Eq, PartialEq, Debug, Encode, Decode, TypeInfo, MaxEncodedLen, DecodeWithMemTracking)]
pub struct DilithiumSignature(pub [u8; DILITHIUM_SIGNATURE_LEN]);

impl serde::Serialize for DilithiumPublicKey {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_bytes(&self.0)
    }
}

impl<'de> serde::Deserialize<'de> for DilithiumPublicKey {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let bytes = Vec::<u8>::deserialize(deserializer)?;
        if bytes.len() != DILITHIUM_PUBLIC_KEY_LEN {
            return Err(serde::de::Error::custom("invalid public key length"));
        }
        let mut arr = [0u8; DILITHIUM_PUBLIC_KEY_LEN];
        arr.copy_from_slice(&bytes);
        Ok(DilithiumPublicKey(arr))
    }
}

#[derive(Clone, Debug)]
pub struct DilithiumSecretKey(pub [u8; DILITHIUM_SECRET_KEY_LEN]);

#[derive(Clone, Debug)]
pub struct DilithiumKeyPair {
    pub public: DilithiumPublicKey,
    pub secret: DilithiumSecretKey,
}

impl core::fmt::Display for DilithiumPublicKey {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(f, "{:?}", self.0)
    }
}

impl Default for DilithiumPublicKey { fn default() -> Self { Self([0u8; DILITHIUM_PUBLIC_KEY_LEN]) } }
impl Default for DilithiumSignature { fn default() -> Self { Self([0u8; DILITHIUM_SIGNATURE_LEN]) } }
impl Default for DilithiumSecretKey { fn default() -> Self { Self([0u8; DILITHIUM_SECRET_KEY_LEN]) } }

impl Verify for DilithiumSignature {
    type Signer = DilithiumPublicKey;
    fn verify<L: Lazy<[u8]>>(&self, mut msg: L, signer: &Self::Signer) -> bool {
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
    let sig_only = &sb[..DILITHIUM_SIGNATURE_LEN];
    let mut sig = [0u8; DILITHIUM_SIGNATURE_LEN];
    sig.copy_from_slice(sig_only);
    DilithiumSignature(sig)
}

pub fn verify_dilithium_signature(
    message: &[u8],
    signature: &[u8; DILITHIUM_SIGNATURE_LEN],
    public_key: &[u8; DILITHIUM_PUBLIC_KEY_LEN],
) -> bool {
    let pk = match <PublicKey as PubT>::from_bytes(public_key) { Ok(p) => p, Err(_) => return false };
    let mut sm_bytes = Vec::with_capacity(DILITHIUM_SIGNATURE_LEN + message.len());
    sm_bytes.extend_from_slice(signature);
    sm_bytes.extend_from_slice(message);
    let sm = match <SignedMessage as SigT>::from_bytes(&sm_bytes) { Ok(s) => s, Err(_) => return false };
    open(&sm, &pk).is_ok()
}

pub fn dilithium_to_address(pk: &DilithiumPublicKey) -> alloc::string::String {
    let hex: alloc::string::String = pk.0.iter().map(|b| alloc::format!("{:02x}", b)).collect();
    let end = if hex.len() > 40 { 40 } else { hex.len() };
    alloc::format!("QR{}", &hex[..end])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keypair_generation() {
        let kp = generate_keypair();
        assert_eq!(kp.public.0.len(), DILITHIUM_PUBLIC_KEY_LEN);
        assert_eq!(kp.secret.0.len(), DILITHIUM_SECRET_KEY_LEN);
        assert_ne!(kp.public.0, [0u8; DILITHIUM_PUBLIC_KEY_LEN]);
    }

    #[test]
    fn test_sign_and_verify() {
        let kp = generate_keypair();
        let msg = b"hello quanta l1";
        let sig = sign_message(msg, &kp.secret);
        assert!(verify_dilithium_signature(msg, &sig.0, &kp.public.0));
    }

    #[test]
    fn test_verify_wrong_signature_fails() {
        let kp = generate_keypair();
        let msg = b"hello quanta l1";
        let bad_sig = DilithiumSignature([0u8; DILITHIUM_SIGNATURE_LEN]);
        assert!(!verify_dilithium_signature(msg, &bad_sig.0, &kp.public.0));
    }

    #[test]
    fn test_verify_wrong_message_fails() {
        let kp = generate_keypair();
        let msg = b"hello quanta l1";
        let sig = sign_message(msg, &kp.secret);
        let wrong_msg = b"tampered message";
        assert!(!verify_dilithium_signature(wrong_msg, &sig.0, &kp.public.0));
    }

    #[test]
    fn test_address_generation() {
        let kp = generate_keypair();
        let addr = dilithium_to_address(&kp.public);
        assert!(addr.starts_with("QR"));
        assert_eq!(addr.len(), 42);
    }

    #[test]
    fn test_serde_serialize() {
        let kp = generate_keypair();
        let s = format!("{}", kp.public);
        assert!(s.starts_with("["));
    }

    #[test]
    fn test_signature_length() {
        let kp = generate_keypair();
        let msg_empty = b"";
        let sk = <SecretKey as SecT>::from_bytes(&kp.secret.0).expect("Invalid SK");
        let sm_empty = sign(msg_empty, &sk);
        let sb = <SignedMessage as SigT>::as_bytes(&sm_empty);
        assert_eq!(DILITHIUM_SIGNATURE_LEN, sb.len(), "signature length mismatch: expected {} got {}", DILITHIUM_SIGNATURE_LEN, sb.len());
    }

    #[test]
    fn test_verify_trait() {
        let kp = generate_keypair();
        let msg = b"test verify trait";
        let sig = sign_message(msg, &kp.secret);
        assert!(sig.verify(&msg[..], &kp.public));
    }

    #[test]
    fn test_identify_account() {
        let kp = generate_keypair();
        let account: DilithiumPublicKey = kp.public.clone().into_account();
        assert_eq!(kp.public.0.to_vec(), account.0.to_vec());
    }
}
