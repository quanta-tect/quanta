use crate::{mock::*, Error};
use polkadot_sdk::frame_support::{assert_noop, assert_ok};

#[test]
fn test_stake_ok() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 1_000_000_000_000_000_000));
        assert_eq!(PqStaking::stake_info(1), (1_000_000_000_000_000_000, true));
    });
}

#[test]
fn test_stake_too_low() {
    new_test_ext().execute_with(|| {
        assert_noop!(PqStaking::stake(RuntimeOrigin::signed(1), 100), Error::<Test>::InsufficientStake);
    });
}

#[test]
fn test_stake_already_staked() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 1_000_000_000_000_000_000));
        assert_noop!(PqStaking::stake(RuntimeOrigin::signed(1), 1_000_000_000_000_000_000), Error::<Test>::AlreadyStaked);
    });
}

#[test]
fn test_submit_inference_ok() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 1_000_000_000_000_000_000));
        let model = [1u8; 32];
        let input = [2u8; 32];
        assert_ok!(PqStaking::submit_inference(RuntimeOrigin::signed(1), model, input));
        assert_eq!(PqStaking::inference_count(1), 1);
        assert_eq!(PqStaking::pending_rewards(1), 10_000_000_000_000_000);
    });
}

#[test]
fn test_submit_inference_not_staked() {
    new_test_ext().execute_with(|| {
        let model = [1u8; 32];
        let input = [2u8; 32];
        assert_noop!(PqStaking::submit_inference(RuntimeOrigin::signed(1), model, input), Error::<Test>::NotStaked);
    });
}

#[test]
fn test_claim_reward_ok() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 1_000_000_000_000_000_000));
        let model = [1u8; 32];
        let input = [2u8; 32];
        assert_ok!(PqStaking::submit_inference(RuntimeOrigin::signed(1), model, input));
        assert_ok!(PqStaking::claim_reward(RuntimeOrigin::signed(1)));
        assert_eq!(PqStaking::pending_rewards(1), 0);
    });
}

#[test]
fn test_claim_nothing() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 1_000_000_000_000_000_000));
        assert_noop!(PqStaking::claim_reward(RuntimeOrigin::signed(1)), Error::<Test>::NothingToClaim);
    });
}

#[test]
fn test_unstake_ok() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 1_000_000_000_000_000_000));
        let model = [1u8; 32];
        let input = [2u8; 32];
        assert_ok!(PqStaking::submit_inference(RuntimeOrigin::signed(1), model, input));
        assert_ok!(PqStaking::unstake(RuntimeOrigin::signed(1)));
        assert_eq!(PqStaking::stake_info(1), (0, false));
        assert_eq!(PqStaking::inference_count(1), 0);
    });
}

#[test]
fn test_unstake_not_staked() {
    new_test_ext().execute_with(|| {
        assert_noop!(PqStaking::unstake(RuntimeOrigin::signed(1)), Error::<Test>::NotStaked);
    });
}
