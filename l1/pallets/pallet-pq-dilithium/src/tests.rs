use crate::{mock::*, Error};
use polkadot_sdk::frame_support::{assert_noop, assert_ok};

#[test]
fn test_register_key() {
    new_test_ext().execute_with(|| {
        let pk = [1u8; 1952];
        assert_ok!(PqDilithium::register_key(RuntimeOrigin::signed(1), pk));
        assert_eq!(PqDilithium::public_keys(1).len(), 1);
    });
}

#[test]
fn test_revoke_key() {
    new_test_ext().execute_with(|| {
        let pk = [1u8; 1952];
        assert_ok!(PqDilithium::register_key(RuntimeOrigin::signed(1), pk));
        assert_ok!(PqDilithium::revoke_key(RuntimeOrigin::signed(1), pk));
        assert_eq!(PqDilithium::public_keys(1).len(), 0);
    });
}

#[test]
fn test_duplicate_key_fails() {
    new_test_ext().execute_with(|| {
        let pk = [1u8; 1952];
        assert_ok!(PqDilithium::register_key(RuntimeOrigin::signed(1), pk));
        assert_noop!(
            PqDilithium::register_key(RuntimeOrigin::signed(1), pk),
            Error::<Test>::KeyAlreadyExists
        );
    });
}

#[test]
fn test_revoke_nonexistent_key_fails() {
    new_test_ext().execute_with(|| {
        let pk = [1u8; 1952];
        assert_noop!(
            PqDilithium::revoke_key(RuntimeOrigin::signed(1), pk),
            Error::<Test>::KeyNotFound
        );
    });
}

#[test]
fn test_max_keys_exceeded() {
    new_test_ext().execute_with(|| {
        for i in 0..5 {
            let pk: [u8; 1952] = [i as u8; 1952];
            assert_ok!(PqDilithium::register_key(RuntimeOrigin::signed(1), pk));
        }
        let pk = [5u8; 1952];
        assert_noop!(
            PqDilithium::register_key(RuntimeOrigin::signed(1), pk),
            Error::<Test>::MaxKeysExceeded
        );
    });
}
