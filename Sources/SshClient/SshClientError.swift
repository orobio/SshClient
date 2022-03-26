/// SSH client errors.
public enum SshClientError: Swift.Error {
    case invalidHostKey
    case authenticationFailed
    case authenticatedStateNotReached
    case invalidChannelType
    case noChannelAvailable
    case commandExecFailed
}
