import NIO
import NIOSSH

/// A remote process.
///
/// A remote process can be created by executing a command
/// remotely using an ``SshConnection``.
///
/// The stdout and/or stderr output lines of the remote process can
/// be obtained from one of: ``stdOutLines``, ``stdErrLines`` or
/// ``stdOutAndStdErrLines``
///
/// **Note:** No more than one of those properties can be used per process.
///
/// Example usage:
/// ```swift
/// for await line in remoteProcess.stdOutLines {
///     print(line)
/// }
public final class RemoteProcess {
    let sshConnection: SshConnection    // Keep the connection alive
    let channel: Channel
    let exitCodeFuture: EventLoopFuture<Int>

    /// Exit code of the remote process.
    public var exitCode: Int {
        get async throws {
            try await exitCodeFuture.get()
        }
    }

    /// An AsyncSequence with lines from stdout of the remote process.
    public private(set) lazy var stdOutLines = RemoteProcessSingleChannelOutputLines(channel: channel, outputChannel: .stdOut)

    /// An AsyncSequence with lines from stderr of the remote process.
    public private(set) lazy var stdErrLines = RemoteProcessSingleChannelOutputLines(channel: channel, outputChannel: .stdErr)

    /// An AsyncSequence with lines from stdout and stderr of the remote process.
    public private(set) lazy var stdOutAndStdErrLines = RemoteProcessOutputLines(channel: channel)

    init(sshConnection: SshConnection,
         channel: Channel,
         exitCodeFuture: EventLoopFuture<Int>) {
        self.sshConnection = sshConnection
        self.channel = channel
        self.exitCodeFuture = exitCodeFuture
    }
}
