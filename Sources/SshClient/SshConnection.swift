import NIO
import NIOSSH

/// SSH connection.
///
/// An SSH connection can be created with an instance of ``SshClient/SshClient``.
///
/// An SSH connection can be used to execute commands remotely:
/// ```swift
/// let remoteCommand = try await sshConnection.execute("ls")
/// ```
///
/// The execute function returns a ``RemoteProcess`` object.
public final class SshConnection {
    private let sshClient: SshClient    // Keep sshClient.eventLoopGroup alive
    private let channel: Channel

    init(sshClient: SshClient, channel: Channel) {
        self.sshClient = sshClient
        self.channel = channel
    }

    /// Execute a command remotely.
    ///
    /// - Parameter command: The command to execute remotely.
    /// - Returns: The remote process.
    public func execute(_ command: String) async throws -> RemoteProcess {
        let exitCodePromise = channel.eventLoop.makePromise(of: Int.self)
        let processChannel: Channel = try await channel.pipeline.handler(type: NIOSSHHandler.self).flatMap { sshHandler in
            let promise = self.channel.eventLoop.makePromise(of: Channel.self)
            sshHandler.createChannel(promise) { childChannel, channelType in
                guard channelType == .session else {
                    return self.channel.eventLoop.makeFailedFuture(SshClientError.invalidChannelType)
                }
                return childChannel.pipeline.addHandlers([
                    ExecHandler(command: command, exitCodePromise: exitCodePromise),
                    ErrorHandler()
                ])
            }
            return promise.futureResult
        }.get()

        return RemoteProcess(sshConnection: self,
                             channel: processChannel,
                             exitCodeFuture: exitCodePromise.futureResult)
    }

    /// Deinitialize
    deinit {
        Task { [sshClient, channel] in
            let promise = channel.eventLoop.makePromise(of: Void.self)
            channel.close(promise: promise)
            try await promise.futureResult.get()
            withExtendedLifetime(sshClient) {}  // Keep sshClient.eventLoopGroup alive
        }
    }
}
