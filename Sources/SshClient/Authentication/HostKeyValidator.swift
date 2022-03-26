import NIOSSH

/// Protocol for host key validators.
public protocol HostKeyValidator {
    /// Verify a host key.
    ///
    /// - Parameters:
    ///   - key:    The key to verify.
    ///
    ///   - host:   The host to verify the key for.
    ///
    /// - Returns:  Whether the specified key is valid for the specified host.
    func isValidKey(_ key: NIOSSHPublicKey, for host: String) -> Bool
}
