use crate as pallet_pq_dilithium;
use frame::testing_prelude::*;
use polkadot_sdk::polkadot_sdk_frame as frame;

construct_runtime!(
    pub enum Test
    {
        System: frame_system,
        PqDilithium: pallet_pq_dilithium,
    }
);

#[derive_impl(frame_system::config_preludes::TestDefaultConfig)]
impl frame_system::Config for Test {
    type Block = MockBlock<Test>;
    type AccountId = u64;
}

parameter_types! {
    pub const MaxKeysPerAccount: u32 = 5;
    pub const KeyRegistrationDeposit: u128 = 100;
}

impl crate::Config for Test {
    type MaxKeysPerAccount = MaxKeysPerAccount;
    type KeyRegistrationDeposit = KeyRegistrationDeposit;
}

pub fn new_test_ext() -> sp_io::TestExternalities {
    let t = frame_system::GenesisConfig::<Test>::default().build_storage().unwrap();
    t.into()
}
