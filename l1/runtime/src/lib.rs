#![cfg_attr(not(feature = "std"), no_std)]

// Make WASM binary available
#[cfg(feature = "std")]
include!(concat!(env!("OUT_DIR"), "/wasm_binary.rs"));

extern crate alloc;

use alloc::borrow::Cow;
use polkadot_sdk::frame_support::{construct_runtime, parameter_types, traits::{ConstU16, ConstU32, ConstU128, Everything}};
use polkadot_sdk::sp_core::H256;
use polkadot_sdk::sp_runtime::{generic, traits::{BlakeTwo256, IdentityLookup}, Perbill};
use polkadot_sdk::sp_version::RuntimeVersion;

use quanta_l1_crypto::{DilithiumPublicKey, DilithiumSignature};

pub type BlockNumber = u32;
pub type Index = u32;
pub type Hash = H256;
pub type AccountId = DilithiumPublicKey;
pub type Address = AccountId;
pub type Signature = DilithiumSignature;
pub type Balance = u128;
pub type Header = generic::Header<BlockNumber, BlakeTwo256>;
pub type SignedExtra = (
    polkadot_sdk::frame_system::CheckSpecVersion<Runtime>,
    polkadot_sdk::frame_system::CheckTxVersion<Runtime>,
    polkadot_sdk::frame_system::CheckGenesis<Runtime>,
    polkadot_sdk::frame_system::CheckEra<Runtime>,
    polkadot_sdk::frame_system::CheckNonce<Runtime>,
    polkadot_sdk::frame_system::CheckWeight<Runtime>,
);
pub type UncheckedExtrinsic = generic::UncheckedExtrinsic<Address, RuntimeCall, Signature, SignedExtra>;
pub type Block = generic::Block<Header, UncheckedExtrinsic>;

parameter_types! {
    pub const BlockHashCount: BlockNumber = 2400;
    pub const MaxKeysPerAccount: u32 = 10;
    pub const ExistentialDeposit: Balance = 100_000_000_000_000_000_000;
    pub const MaxLocks: u32 = 50;
    pub const MaxBlockSize: u32 = 10 * 1024 * 1024;
    pub const KeyRegistrationDepositVal: Balance = 1_000_000_000_000_000_000_000;
    pub RuntimeBlockLength: polkadot_sdk::frame_system::limits::BlockLength =
        polkadot_sdk::frame_system::limits::BlockLength::max_with_normal_ratio(
            MaxBlockSize::get(), Perbill::from_percent(75));
}

pub struct Version;
impl polkadot_sdk::sp_runtime::traits::Get<RuntimeVersion> for Version {
    fn get() -> RuntimeVersion {
        RuntimeVersion {
            spec_name: Cow::Borrowed("quanta-l1"),
            impl_name: Cow::Borrowed("quanta-l1"),
            authoring_version: 1,
            spec_version: 1,
            impl_version: 1,
            transaction_version: 1,
            system_version: 1,
            apis: alloc::vec![].into(),
        }
    }
}

construct_runtime!(
    pub enum Runtime where
        Block = Block,
        NodeBlock = Block,
        UncheckedExtrinsic = UncheckedExtrinsic
    {
        System: polkadot_sdk::frame_system,
        Balances: polkadot_sdk::pallet_balances,
        PqDilithium: pallet_pq_dilithium,
        PqBalances: pallet_pq_balances,
        PqStaking: pallet_pq_staking,
    }
);

impl polkadot_sdk::frame_system::Config for Runtime {
    type BaseCallFilter = Everything;
    type BlockWeights = ();
    type BlockLength = RuntimeBlockLength;
    type DbWeight = ();
    type RuntimeOrigin = RuntimeOrigin;
    type RuntimeCall = RuntimeCall;
    type RuntimeTask = ();
    type Nonce = Index;
    type Hash = Hash;
    type Hashing = BlakeTwo256;
    type AccountId = AccountId;
    type Lookup = IdentityLookup<Self::AccountId>;
    type Block = Block;
    type RuntimeEvent = RuntimeEvent;
    type BlockHashCount = BlockHashCount;
    type Version = Version;
    type PalletInfo = PalletInfo;
    type AccountData = polkadot_sdk::pallet_balances::AccountData<Balance>;
    type OnNewAccount = ();
    type OnKilledAccount = ();
    type SystemWeightInfo = ();
    type ExtensionsWeightInfo = ();
    type SS58Prefix = ConstU16<42>;
    type OnSetCode = ();
    type MaxConsumers = ConstU32<16>;
    type SingleBlockMigrations = ();
    type MultiBlockMigrator = ();
    type PreInherents = ();
    type PostInherents = ();
    type PostTransactions = ();
}

impl pallet_pq_dilithium::Config for Runtime {
    type MaxKeysPerAccount = MaxKeysPerAccount;
    type KeyRegistrationDeposit = KeyRegistrationDepositVal;
}

impl pallet_pq_balances::Config for Runtime {}

impl polkadot_sdk::pallet_balances::Config for Runtime {
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
    type RuntimeFreezeReason = ();
    type DoneSlashHandler = ();
}

impl pallet_pq_staking::Config for Runtime {
    type MinStake = ConstU128<1_000_000_000_000_000_000>;
    type RewardPerInference = ConstU128<10_000_000_000_000_000>;
}
