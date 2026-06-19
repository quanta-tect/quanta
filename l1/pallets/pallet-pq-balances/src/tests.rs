use crate::{mock::*, Error};
use polkadot_sdk::frame_support::{assert_noop, assert_ok};

#[test]
fn test_transfer() {
    new_test_ext().execute_with(|| {
        // Setup initial balance
        crate::Balance::<Test>::insert(1, 500);

        // Transfer from 1 to 2
        assert_ok!(PqBalances::transfer(RuntimeOrigin::signed(1), 2, 100));
        assert_eq!(crate::Balance::<Test>::get(1), 400);
        assert_eq!(crate::Balance::<Test>::get(2), 100);
    });
}

#[test]
fn test_self_transfer_fails() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            PqBalances::transfer(RuntimeOrigin::signed(1), 1, 100),
            Error::<Test>::SelfTransfer
        );
    });
}

#[test]
fn test_zero_transfer_fails() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            PqBalances::transfer(RuntimeOrigin::signed(1), 2, 0),
            Error::<Test>::ZeroTransfer
        );
    });
}

#[test]
fn test_insufficient_balance_fails() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            PqBalances::transfer(RuntimeOrigin::signed(1), 2, 100),
            Error::<Test>::InsufficientBalance
        );
    });
}
