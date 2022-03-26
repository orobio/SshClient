import NIOSSH

/// Protocol for password prompts.
public protocol PasswordPrompt {
    /// Prompt for a password.
    ///
    /// - Returns:  The password.
    func getPassword() -> String
}
