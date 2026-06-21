//! QUANTA L1 Node RPC module
//!
//! Provides JSON-RPC endpoints for interacting with the node.
//! In a full implementation, this would use jsonrpsee.

use quanta_l1_runtime::VERSION;

/// Node information response
#[derive(Debug, Clone)]
pub struct NodeInfo {
    pub spec_name: String,
    pub impl_name: String,
    pub spec_version: u32,
    pub impl_version: u32,
    pub chain_type: String,
}

impl NodeInfo {
    pub fn new() -> Self {
        Self {
            spec_name: VERSION.spec_name.to_string(),
            impl_name: VERSION.impl_name.to_string(),
            spec_version: VERSION.spec_version,
            impl_version: VERSION.impl_version,
            chain_type: "Development".to_string(),
        }
    }
}

/// System health response
#[derive(Debug, Clone)]
pub struct Health {
    pub is_syncing: bool,
    pub peers: u32,
    pub should_have_peers: bool,
}

impl Health {
    pub fn new() -> Self {
        Self {
            is_syncing: false,
            peers: 0,
            should_have_peers: false,
        }
    }
}

/// RPC server handle
pub struct NodeRpcServer;

impl NodeRpcServer {
    pub fn new() -> Self {
        Self
    }

    /// Get node system info
    pub fn system_info(&self) -> NodeInfo {
        NodeInfo::new()
    }

    /// Get system health
    pub fn system_health(&self) -> Health {
        Health::new()
    }

    /// Get the current block number (always 0 in dev mode)
    pub fn block_number(&self) -> u32 {
        0
    }

    /// Get chain name
    pub fn chain(&self) -> String {
        VERSION.spec_name.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn node_info_correct() {
        let info = NodeInfo::new();
        assert_eq!(info.spec_name, "quanta-l1");
        assert_eq!(info.impl_name, "quanta-l1");
        assert_eq!(info.spec_version, 1);
        assert_eq!(info.chain_type, "Development");
    }

    #[test]
    fn health_ok() {
        let health = Health::new();
        assert!(!health.is_syncing);
    }

    #[test]
    fn rpc_server_creates() {
        let server = NodeRpcServer::new();
        assert_eq!(server.block_number(), 0);
        assert_eq!(server.chain(), "quanta-l1");
    }
}
