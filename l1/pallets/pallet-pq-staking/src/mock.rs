use crate as pallet_pq_staking;
use frame::testing_prelude::*;
use polkadot_sdk::polkadot_sdk_frame as frame;

construct_runtime!(
    pub enum Test
    {
        System: frame_system,
        PqStaking: pallet_pq_staking,
    }
);

#[derive_impl(frame_system::config_preludes::TestDefaultConfig)]
impl frame_system::Config for Test {
    type Block = MockBlock<Test>;
    type AccountId = u64;
}

impl crate::Config for Test {
    type MinStake = ConstU128<10>;
    type RewardPerInference = ConstU128<5>;
}

pub fn new_test_ext() -> sp_io::TestExternalities {
    let t = frame_system::GenesisConfig::<Test>::default().build_storage().unwrap();
    t.into()
}
