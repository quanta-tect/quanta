//! QUANTA L1 Dev Storage
//!
//! Manages the in-memory storage for the dev node.
//! In production, this would use RocksDB via sc-client-db.

use std::collections::BTreeMap;

/// Dev storage backend
pub struct DevStorage {
    data: BTreeMap<Vec<u8>, Vec<u8>>,
}

impl DevStorage {
    /// Create new dev storage with genesis state
    pub fn new() -> Self {
        let mut data = BTreeMap::new();

        // Insert genesis timestamp
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;

        // Timestamp storage key (frame_support::storage::storage_prefix)
        let timestamp_key = [
            &b"Timestamp"[..],
            &b"Now"[..],
        ]
        .concat();

        data.insert(timestamp_key, now.to_le_bytes().to_vec());

        // Insert some dev account balances
        // In a real chain, this would come from chain_spec.json
        let dev_accounts: Vec<(&str, u128)> = vec![
            ("//Alice", 1_000_000_000_000_000_000u128),
            ("//Bob", 1_000_000_000_000_000_000u128),
            ("//Charlie", 500_000_000_000_000_000u128),
        ];

        for (name, balance) in dev_accounts {
            let mut key = b"System".to_vec();
            key.extend_from_slice(b"Account");
            key.extend_from_slice(name.as_bytes());
            // Simplified account data (nonce, balance, etc.)
            let mut value = Vec::new();
            value.extend_from_slice(&0u32.to_le_bytes()); // nonce
            value.extend_from_slice(&balance.to_le_bytes()); // free balance
            data.insert(key, value);
        }

        Self { data }
    }

    /// Get value by key
    pub fn get(&self, key: &[u8]) -> Option<&Vec<u8>> {
        self.data.get(key)
    }

    /// Insert key-value pair
    pub fn insert(&mut self, key: Vec<u8>, value: Vec<u8>) {
        self.data.insert(key, value);
    }

    /// Get number of top-level entries
    pub fn top_count(&self) -> usize {
        self.data.len()
    }

    /// Get all keys
    pub fn keys(&self) -> impl Iterator<Item = &Vec<u8>> {
        self.data.keys()
    }
}

impl Default for DevStorage {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dev_storage_creates() {
        let storage = DevStorage::new();
        assert!(storage.top_count() > 0);
    }

    #[test]
    fn dev_storage_timestamp() {
        let storage = DevStorage::new();
        let key = [&b"Timestamp"[..], &b"Now"[..]].concat();
        assert!(storage.get(&key).is_some());
    }

    #[test]
    fn dev_storage_insert() {
        let mut storage = DevStorage::new();
        storage.insert(b"test".to_vec(), b"value".to_vec());
        assert_eq!(storage.get(b"test").unwrap(), b"value");
    }
}
