#![cfg_attr(not(feature = "std"), no_std)]

use frame::prelude::*;
use polkadot_sdk::polkadot_sdk_frame as frame;

pub use pallet::*;

#[frame::pallet]
pub mod pallet {
    use super::*;

    pub const PK_LEN: usize = 1952;

    #[pallet::config]
    pub trait Config: polkadot_sdk::frame_system::Config {
        #[pallet::constant]
        type MaxKeysPerAccount: Get<u32>;
        #[pallet::constant]
        type KeyRegistrationDeposit: Get<u128>;
    }

    #[pallet::pallet]
    #[pallet::without_storage_info]
    pub struct Pallet<T>(_);

    #[pallet::storage]
    #[pallet::getter(fn public_keys)]
    pub type PublicKeys<T: Config> = StorageMap<
        _, Blake2_128Concat, T::AccountId, Vec<[u8; PK_LEN]>, ValueQuery,
    >;

    #[pallet::storage]
    #[pallet::getter(fn total_keys)]
    pub type TotalKeys<T: Config> = StorageValue<_, u64, ValueQuery>;

    #[pallet::event]
    pub enum Event<T: Config> {
        KeyRegistered { who: T::AccountId },
        KeyRevoked { who: T::AccountId },
    }

    #[pallet::error]
    pub enum Error<T> {
        KeyAlreadyExists,
        KeyNotFound,
        MaxKeysExceeded,
        NoOwnershipProof,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        #[pallet::call_index(0)]
        #[pallet::weight(200_000)]
        pub fn register_key(
            origin: OriginFor<T>,
            public_key: [u8; PK_LEN],
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;
            PublicKeys::<T>::try_mutate(&who, |keys| -> DispatchResult {
                ensure!((keys.len() as u32) < T::MaxKeysPerAccount::get(), Error::<T>::MaxKeysExceeded);
                ensure!(!keys.contains(&public_key), Error::<T>::KeyAlreadyExists);
                keys.push(public_key);
                TotalKeys::<T>::mutate(|n| *n += 1);
                Ok(())
            })?;
            Ok(())
        }

        #[pallet::call_index(1)]
        #[pallet::weight(50_000)]
        pub fn revoke_key(origin: OriginFor<T>, public_key: [u8; PK_LEN]) -> DispatchResult {
            let who = ensure_signed(origin)?;
            PublicKeys::<T>::try_mutate(&who, |keys| -> DispatchResult {
                let pos = keys.iter().position(|k| *k == public_key).ok_or(Error::<T>::KeyNotFound)?;
                keys.remove(pos);
                TotalKeys::<T>::mutate(|n| *n = n.saturating_sub(1));
                Ok(())
            })?;
            Ok(())
        }
    }
}
