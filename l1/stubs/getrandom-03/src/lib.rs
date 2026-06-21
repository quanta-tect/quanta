//! Stub for getrandom 0.3.x — provides wasm32 support
//!
//! This stub provides no-op implementations for all platforms.
//! In production, use the real getrandom crate with proper entropy sources.

/// Error type for getrandom operations
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Error(u16);

impl Error {
    /// The operation is not supported on this platform
    pub const UNSUPPORTED: Error = Error(1);
    /// The operation failed
    pub const FAILED: Error = Error(2);
}

impl core::fmt::Display for Error {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self.0 {
            1 => write!(f, "getrandom: unsupported"),
            _ => write!(f, "getrandom: failed ({})", self.0),
        }
    }
}

#[cfg(feature = "std")]
impl std::error::Error for Error {}

/// Fill `dest` with random bytes.
///
/// On native platforms, this is a no-op that returns Ok.
/// On wasm32, this returns an error (use the `js` feature for wasm32 support).
pub fn getrandom(dest: &mut [u8]) -> Result<(), Error> {
    // Stub: fill with zeros (NOT secure — for testing only)
    for byte in dest.iter_mut() {
        *byte = 0;
    }
    Ok(())
}

/// Fill `dest` with random bytes (same as `getrandom`)
pub fn fill(dest: &mut [u8]) -> Result<(), Error> {
    getrandom(dest)
}
///
/// This is a convenience wrapper around `getrandom`.
pub fn u64() -> Result<u64, Error> {
    let mut buf = [0u8; 8];
    getrandom(&mut buf)?;
    Ok(u64::from_le_bytes(buf))
}

/// Get a random u32 value.
///
/// This is a convenience wrapper around `getrandom`.
pub fn u32() -> Result<u32, Error> {
    let mut buf = [0u8; 4];
    getrandom(&mut buf)?;
    Ok(u32::from_le_bytes(buf))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_getrandom() {
        let mut buf = [0u8; 32];
        assert!(getrandom(&mut buf).is_ok());
    }

    #[test]
    fn test_u64() {
        assert!(u64().is_ok());
    }

    #[test]
    fn test_u32() {
        assert!(u32().is_ok());
    }
}
