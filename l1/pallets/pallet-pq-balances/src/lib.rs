#![cfg_attr(not(feature = "std"), no_std)]

use frame::prelude::*;
use polkadot_sdk::polkadot_sdk_frame as frame;

pub use pallet::*;

#[frame::pallet]
pub mod pallet {
    use super::*;

    #[pallet::config]
    pub trait Config: polkadot_sdk::frame_system::Config {}

    #[pallet::pallet]
    #[pallet::without_storage_info]
    pub struct Pallet<T>(_);

    #[pallet::storage]
    pub type Balance<T: Config> = StorageMap<_, Blake2_128Concat, T::AccountId, u128, ValueQuery>;

    #[pallet::event]
    pub enum Event<T: Config> {
        Transfer { from: T::AccountId, to: T::AccountId, amount: u128 },
    }

    #[pallet::error]
    pub enum Error<T> {
        InsufficientBalance,
        SelfTransfer,
        ZeroTransfer,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        #[pallet::call_index(0)]
        #[pallet::weight(200_000)]
        pub fn transfer(
            origin: OriginFor<T>,
            dest: <T::Lookup as StaticLookup>::Source,
            #[pallet::compact] value: u128,
        ) -> DispatchResult {
            let sender = ensure_signed(origin)?;
            let dest = T::Lookup::lookup(dest)?;
            ensure!(sender != dest, Error::<T>::SelfTransfer);
            ensure!(value > 0, Error::<T>::ZeroTransfer);

            Balance::<T>::try_mutate(&sender, |balance| -> DispatchResult {
                ensure!(*balance >= value, Error::<T>::InsufficientBalance);
                *balance -= value;
                Ok(())
            })?;

            Balance::<T>::mutate(&dest, |balance| {
                *balance += value;
            });

            Ok(())
        }
    }
}
