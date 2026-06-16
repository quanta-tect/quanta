use crate as pallet_pq_dilithium;
use polkadot_sdk::frame_support::{construct_runtime, parameter_types, traits::{ConstU32, Everything}};
use polkadot_sdk::sp_runtime::{traits::{BlakeTwo256, IdentityLookup}, BuildStorage};
use polkadot_sdk::sp_core::H256;

type BlockNumber = u64;
type AccountId = u64;
type Hash = H256;
type Header = polkadot_sdk::sp_runtime::generic::Header<BlockNumber, BlakeTwo256>;
type Block = polkadot_sdk::sp_runtime::generic::Block<Header, polkadot_sdk::sp_runtime::testing::TestXt<RuntimeCall, ()>>;

construct_runtime!(
    pub enum Test
    {
        System: polkadot_sdk::frame_system,
        PqDilithium: pallet_pq_dilithium,
    }
);

parameter_types! {
    pub const BlockHashCount: u64 = 250;
    pub const MaxKeysPerAccount: u32 = 5;
    pub const KeyRegistrationDeposit: u128 = 100;
}

impl polkadot_sdk::frame_system::Config for Test {
    type BaseCallFilter = Everything;
    type BlockWeights = ();
    type BlockLength = ();
    type DbWeight = ();
    type RuntimeOrigin = RuntimeOrigin;
    type RuntimeCall = RuntimeCall;
    type RuntimeTask = ();
    type Nonce = u64;
    type Hash = Hash;
    type Hashing = BlakeTwo256;
    type AccountId = AccountId;
    type Lookup = IdentityLookup<Self::AccountId>;
    type Block = Block;
    type RuntimeEvent = RuntimeEvent;
    type BlockHashCount = BlockHashCount;
    type Version = ();
    type PalletInfo = PalletInfo;
    type AccountData = ();
    type OnNewAccount = ();
    type OnKilledAccount = ();
    type SystemWeightInfo = ();
    type ExtensionsWeightInfo = ();
    type SS58Prefix = ();
    type OnSetCode = ();
    type MaxConsumers = ConstU32<16>;
    type SingleBlockMigrations = ();
    type MultiBlockMigrator = ();
    type PreInherents = ();
    type PostInherents = ();
    type PostTransactions = ();
}

impl crate::Config for Test {
    type MaxKeysPerAccount = MaxKeysPerAccount;
    type KeyRegistrationDeposit = KeyRegistrationDeposit;
}

pub fn new_test_ext() -> polkadot_sdk::sp_io::TestExternalities {
    let t = polkadot_sdk::frame_system::GenesisConfig::<Test>::default().build_storage().unwrap();
    t.into()
}
