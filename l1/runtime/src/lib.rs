#![cfg_attr(not(feature = "std"), no_std)]
#![recursion_limit = "256"]

use codec::{Decode, Encode};
use frame_support::{
    construct_runtime, parameter_types,
    traits::{ConstU16, ConstU32, ConstU64, Everything, Nothing},
    weights::constants::WEIGHT_REF_TIME_PER_SECOND,
};
use sp_core::H256;
use sp_runtime::{
    generic,
    traits::{BlakeTwo256, Zero, IdentifyAccount, Verify},
    OpaqueExtrinsic, Perbill,
};

use quanta_l1_crypto::{DilithiumPublicKey, DilithiumSignature};

pub type BlockNumber = u32;
pub type Index = u32;
pub type Hash = H256;
pub type AccountId = DilithiumPublicKey;
pub type Signature = DilithiumSignature;
pub type Balance = u128;
pub type Header = generic::Header<BlockNumber, BlakeTwo256>;
pub type Block = generic::Block<Header, OpaqueExtrinsic>;
pub type UncheckedExtrinsic = generic::UncheckedExtrinsic<u32, RuntimeCall, Signature, SignedExtra>;

// Runtime Version
sp_version::runtime_version! {
    pub const VERSION: sp_version::RuntimeVersion = sp_version::RuntimeVersion {
        spec_name: sp_version::create_runtime_str!("quanta-l1"),
        impl_name: sp_version::create_runtime_str!("quanta-l1"),
        authoring_version: 1,
        spec_version: 1,
        impl_version: 1,
        transaction_version: 1,
        state_version: 1,
    };
}

parameter_types! {
    pub const BlockHashCount: BlockNumber = 2400;
    pub const MaxKeysPerAccount: u32 = 10;
    pub const ExistentialDeposit: Balance = 100_000_000_000_000_000_000;
    pub const MaxLocks: u32 = 50;
    pub const MaxBlockSize: u32 = 10 * 1024 * 1024;
    pub const KeyRegistrationDepositVal: Balance = 1_000_000_000_000_000_000_000;
}

impl frame_system::Config for Runtime {
    type BaseCallFilter = Everything;
    type BlockWeights = ();
    type BlockLength = frame_system::limits::BlockLength::max_with_normal_ratio(
        MaxBlockSize::get(), Perbill::from_percent(75),
    );
    type DbWeight = ();
    type RuntimeOrigin = RuntimeOrigin;
    type RuntimeCall = RuntimeCall;
    type Nonce = Index;
    type Hash = Hash;
    type Hashing = BlakeTwo256;
    type AccountId = AccountId;
    type Lookup = sp_runtime::traits::IdentityLookup<Self::AccountId>;
    type Block = Block;
    type RuntimeEvent = RuntimeEvent;
    type BlockHashCount = BlockHashCount;
    type Version = VERSION;
    type PalletInfo = PalletInfo;
    type AccountData = pallet_balances::AccountData<Balance>;
    type OnNewAccount = ();
    type OnKilledAccount = ();
    type SystemWeightInfo = ();
    type SS58Prefix = ConstU16<42>;
    type OnSetCode = ();
    type MaxConsumers = ConstU32<16>;
}

impl pallet_pq_dilithium::Config for Runtime {
    type RuntimeEvent = RuntimeEvent;
    type MaxKeysPerAccount = MaxKeysPerAccount;
    type KeyRegistrationDeposit = KeyRegistrationDepositVal;
}

impl pallet_pq_balances::Config for Runtime {
    type RuntimeEvent = RuntimeEvent;
    type Currency = Balances;
    type ExistentialDeposit = ExistentialDeposit;
}

impl pallet_balances::Config for Runtime {
    type MaxLocks = MaxLocks;
    type MaxReserves = ();
    type ReserveIdentifier = [u8; 8];
    type Balance = Balance;
    type DustRemoval = ();
    type RuntimeEvent = RuntimeEvent;
    type ExistentialDeposit = ExistentialDeposit;
    type AccountStore = System;
    type WeightInfo = ();
    type FreezeIdentifier = ();
    type MaxFreezes = ();
    type RuntimeHoldReason = ();
    type MaxHolds = ();
}

construct_runtime!(
    pub enum Runtime where
        Block = Block,
        NodeBlock = Block,
        UncheckedExtrinsic = UncheckedExtrinsic
    {
        System: frame_system,
        Balances: pallet_balances,
        PqDilithium: pallet_pq_dilithium,
        PqBalances: pallet_pq_balances,
    }
);
