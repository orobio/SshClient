import NIOSSH

/// Host key validator that accepts any key for any host.
public struct AllowAnyHostKey: HostKeyValidator {
    /// If true, print a warning to stderr for every host key validation.
    public let printWarning: Bool

    /// Initialize host key validator.
    ///
    /// - Parameter printWarning:   If true, the validator will print a warning to stderr
    ///                             every time a host key is validated.
    public init(printWarning: Bool = true) {
        self.printWarning = printWarning
    }

    /// Validate any key for any host.
    ///
    /// Always returns true.
    ///
    /// If ``printWarning`` is true, a warning will be printed to stderr.
    public func isValidKey(_: NIOSSHPublicKey, for host: String) -> Bool {
        if printWarning {
            print("warning: not validating host key", to: &StdErr.stream)
        }
        return true
    }
}
