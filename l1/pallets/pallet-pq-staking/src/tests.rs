use crate::{mock::*, Error};
use polkadot_sdk::frame_support::{assert_noop, assert_ok};

#[test]
fn test_stake() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 100));
        let (amount, active) = PqStaking::stake_info(1);
        assert_eq!(amount, 100);
        assert_eq!(active, true);
    });
}

#[test]
fn test_stake_below_minimum_fails() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            PqStaking::stake(RuntimeOrigin::signed(1), 5),
            Error::<Test>::InsufficientStake
        );
    });
}

#[test]
fn test_double_stake_fails() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 100));
        assert_noop!(
            PqStaking::stake(RuntimeOrigin::signed(1), 100),
            Error::<Test>::AlreadyStaked
        );
    });
}

#[test]
fn test_submit_inference() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 100));
        assert_ok!(PqStaking::submit_inference(RuntimeOrigin::signed(1), [1u8; 32], [2u8; 32]));
        assert_eq!(PqStaking::inference_count(1), 1);
        assert_eq!(PqStaking::pending_rewards(1), 5);
    });
}

#[test]
fn test_submit_inference_without_stake_fails() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            PqStaking::submit_inference(RuntimeOrigin::signed(1), [1u8; 32], [2u8; 32]),
            Error::<Test>::NotStaked
        );
    });
}

#[test]
fn test_claim_reward() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 100));
        assert_ok!(PqStaking::submit_inference(RuntimeOrigin::signed(1), [1u8; 32], [2u8; 32]));
        assert_ok!(PqStaking::claim_reward(RuntimeOrigin::signed(1)));
        assert_eq!(PqStaking::pending_rewards(1), 0);
    });
}

#[test]
fn test_unstake() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 100));
        assert_ok!(PqStaking::unstake(RuntimeOrigin::signed(1)));
        assert_eq!(PqStaking::stake_info(1), (0, false));
    });
}

#[test]
fn test_unstake_without_stake_fails() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            PqStaking::unstake(RuntimeOrigin::signed(1)),
            Error::<Test>::NotStaked
        );
    });
}

#[test]
fn test_full_workflow() {
    new_test_ext().execute_with(|| {
        assert_ok!(PqStaking::stake(RuntimeOrigin::signed(1), 100));
        for i in 0..3 {
            assert_ok!(PqStaking::submit_inference(RuntimeOrigin::signed(1), [i; 32], [i+1; 32]));
        }
        assert_eq!(PqStaking::inference_count(1), 3);
        assert_eq!(PqStaking::pending_rewards(1), 15);
        assert_ok!(PqStaking::claim_reward(RuntimeOrigin::signed(1)));
        assert_eq!(PqStaking::pending_rewards(1), 0);
    });
}
