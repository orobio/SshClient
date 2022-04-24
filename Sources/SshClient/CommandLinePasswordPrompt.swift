// Linux
#if canImport(Glibc)
import Glibc
#endif

// macOS
#if canImport(Darwin)
import Darwin
#endif

/// Command line password prompt.
public struct CommandLinePasswordPrompt: PasswordPrompt {
    /// Initialize.
    public init() {}

    /// Display a password prompt on the command line and get user input.
    ///
    /// - Returns: The password provided by the user.
    public func getPassword() -> String {
#if os(Windows)
        print("Password: ", terminator: "")
        return readLine() ?? ""
#else
        return String(cString: getpass("Password: "))
#endif
    }
}
