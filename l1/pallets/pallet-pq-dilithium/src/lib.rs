#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

#[polkadot_sdk::polkadot_sdk_frame::prelude::frame_support::pallet]
pub mod pallet {
    use polkadot_sdk::polkadot_sdk_frame::prelude::frame_support::pallet_prelude::*;
    use polkadot_sdk::polkadot_sdk_frame::prelude::frame_system::pallet_prelude::*;
    use polkadot_sdk::sp_std::prelude::*;

    pub const PK_LEN: usize = 1952;

    #[pallet::config]
    pub trait Config: frame_system::Config {
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;
        #[pallet::constant]
        type MaxKeysPerAccount: Get<u32>;
        #[pallet::constant]
        type KeyRegistrationDeposit: Get<u128>;
    }

    #[pallet::pallet]
    #[pallet::without_storage_info]
    pub struct Pallet<T>(PhantomData<T>);

    #[pallet::storage]
    #[pallet::getter(fn public_keys)]
    pub type PublicKeys<T: Config> = StorageMap<
        _, Blake2_128Concat, T::AccountId, Vec<[u8; PK_LEN]>, ValueQuery,
    >;

    #[pallet::storage]
    #[pallet::getter(fn total_keys)]
    pub type TotalKeys<T: Config> = StorageValue<_, u64, ValueQuery>;

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
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
            Self::deposit_event(Event::KeyRegistered { who });
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
            Self::deposit_event(Event::KeyRevoked { who });
            Ok(())
        }
    }
}
