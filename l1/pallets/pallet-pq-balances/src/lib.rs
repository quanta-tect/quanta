#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

#[polkadot_sdk::polkadot_sdk_frame::prelude::frame_support::pallet]
pub mod pallet {
    use polkadot_sdk::polkadot_sdk_frame::prelude::frame_support::pallet_prelude::*;
    use polkadot_sdk::polkadot_sdk_frame::prelude::frame_system::pallet_prelude::*;
    use polkadot_sdk::polkadot_sdk_frame::prelude::frame_support::traits::{Currency, ReservableCurrency, Get};
    use polkadot_sdk::sp_runtime::traits::{StaticLookup, Zero, CheckedAdd, CheckedSub};
    use polkadot_sdk::sp_std::prelude::*;

    use quanta_l1_crypto::{DilithiumPublicKey, DilithiumSignature, verify_dilithium_signature};

    pub type BalanceOf<T> = <<T as Config>::Currency as Currency<
        <T as frame_system::Config>::AccountId,
    >>::Balance;

    #[pallet::config]
    pub trait Config: frame_system::Config<AccountId = DilithiumPublicKey> {
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;
        type Currency: ReservableCurrency<Self::AccountId>;
        #[pallet::constant]
        type ExistentialDeposit: Get<BalanceOf<Self>>;
    }

    #[pallet::pallet]
    #[pallet::without_storage_info]
    pub struct Pallet<T>(PhantomData<T>);

    #[pallet::storage]
    pub type Account<T: Config> = StorageMap<
        _, Blake2_128Concat, T::AccountId, AccountInfo<BalanceOf<T>>,
    >;

    #[derive(Clone, Eq, PartialEq, Debug, Encode, Decode, TypeInfo, MaxEncodedLen)]
    pub struct AccountInfo<Balance> {
        pub nonce: u32,
        pub free: Balance,
        pub reserved: Balance,
    }

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        Transfer { from: T::AccountId, to: T::AccountId, amount: BalanceOf<T> },
    }

    #[pallet::error]
    pub enum Error<T> {
        InsufficientBalance,
        AccountNotFound,
        ZeroTransfer,
        InvalidSignature,
        InvalidNonce,
        SelfTransfer,
        Overflow,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        #[pallet::call_index(0)]
        #[pallet::weight(200_000)]
        pub fn transfer(
            origin: OriginFor<T>,
            dest: <T::Lookup as StaticLookup>::Source,
            #[pallet::compact] value: BalanceOf<T>,
            signature: DilithiumSignature,
            nonce: u32,
        ) -> DispatchResult {
            let sender = ensure_signed(origin)?;
            let dest = T::Lookup::lookup(dest)?;
            ensure!(sender != dest, Error::<T>::SelfTransfer);
            ensure!(value > Zero::zero(), Error::<T>::ZeroTransfer);

            let msg = Self::construct_message(&sender, &dest, &value, &nonce);
            ensure!(
                verify_dilithium_signature(&msg, &signature.0, &sender.0),
                Error::<T>::InvalidSignature
            );
            Ok(())
        }
    }

    impl<T: Config> Pallet<T> {
        fn construct_message(
            from: &T::AccountId,
            to: &T::AccountId,
            value: &BalanceOf<T>,
            nonce: &u32,
        ) -> Vec<u8> {
            let mut msg = Vec::new();
            msg.extend_from_slice(b"pq-balances:transfer:");
            msg.extend_from_slice(&from.encode());
            msg.extend_from_slice(&to.encode());
            msg.extend_from_slice(&value.encode());
            msg.extend_from_slice(&nonce.encode());
            msg
        }
    }
}
