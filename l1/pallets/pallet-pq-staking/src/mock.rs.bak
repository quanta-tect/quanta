use crate as pallet_pq_staking;
use polkadot_sdk::frame_support::construct_runtime;
use polkadot_sdk::frame_support::traits::Everything;
use polkadot_sdk::sp_runtime::BuildStorage;
use polkadot_sdk::frame_support::traits::ConstU32;

type Block = polkadot_sdk::frame_system::mocking::MockBlock<Test>;

construct_runtime!(
    pub enum Test
    {
        System: polkadot_sdk::frame_system,
        PqStaking: pallet_pq_staking,
    }
);

impl polkadot_sdk::frame_system::Config for Test {
    type BaseCallFilter = Everything;
    type BlockWeights = ();
    type BlockLength = ();
    type DbWeight = ();
    type RuntimeOrigin = RuntimeOrigin;
    type RuntimeCall = RuntimeCall;
    type RuntimeTask = ();
    type Nonce = u64;
    type Hash = polkadot_sdk::sp_core::H256;
    type Hashing = polkadot_sdk::sp_runtime::traits::BlakeTwo256;
    type AccountId = u64;
    type Lookup = polkadot_sdk::sp_runtime::traits::IdentityLookup<Self::AccountId>;
    type Block = Block;
    type RuntimeEvent = RuntimeEvent;
    type BlockHashCount = ConstU32<250>;
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
    type MinStake = polkadot_sdk::frame_support::traits::ConstU128<1000000000000000000>;
    type RewardPerInference = polkadot_sdk::frame_support::traits::ConstU128<10000000000000000>;
}

pub fn new_test_ext() -> polkadot_sdk::sp_io::TestExternalities {
    let t = polkadot_sdk::frame_system::GenesisConfig::<Test>::default().build_storage().unwrap();
    t.into()
}
