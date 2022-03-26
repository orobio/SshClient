import NIO
import NIOSSH

/// SSH client implementation for connecting with an SSH server.
///
/// Example usage:
/// ```swift
/// let sshConnection = try await SshClient().connect(host: "10.0.0.1", username: "username")
/// ```
///
/// By default SshClient uses:
/// - A host key validator that accepts any key, but prints a warning on stderr.
/// - A password prompt on the command line.
///
/// These can be customized upon initialization.
public final class SshClient {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private let hostKeyValidator: HostKeyValidator
    private let passwordPrompt: PasswordPrompt?

    /// Initialize SSH client.
    ///
    /// - Parameters:
    ///   - hostKeyValidator:   Host key validator. The default validator allows any host key
    ///                         and prints a warning to stderr.
    ///
    ///   - passwordPrompt:     Optional password prompt. By default a simple command line
    ///                         password prompt is used. If set to 'nil', the user must be
    ///                         able to login without a password, or the password must be
    ///                         provided to the ``connect(host:username:password:port:)`` function.
    public init(hostKeyValidator: HostKeyValidator = AllowAnyHostKey(printWarning: true),
                passwordPrompt: PasswordPrompt? = CommandLinePasswordPrompt()) {
        self.hostKeyValidator = hostKeyValidator
        self.passwordPrompt = passwordPrompt
    }

    /// Connect with SSH server.
    ///
    /// - Parameters:
    ///   - host:       Host to connect with.
    ///
    ///   - username:   Username to use for logging in.
    ///
    ///   - password:   Optional password for logging in. If not provided, a password prompt
    ///                 may be displayed if required. The password prompt provided upon
    ///                 SshClient initialization (or the default) is used.
    ///
    ///   - port:       TCP port to connect with.
    ///
    /// - Returns:      The connection.
    public func connect(host: String,
                        username: String,
                        password: String? = nil,
                        port: Int = 22) async throws -> SshConnection {
        let serverAuthenticator = ServerAuthenticator(host: host, hostKeyValidator: hostKeyValidator)
        let userAuthenticator = UserAuthenticator(username: username, password: password, passwordPrompt: passwordPrompt)
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([
                    NIOSSHHandler(
                        role: .client(.init(userAuthDelegate: userAuthenticator, serverAuthDelegate: serverAuthenticator)),
                        allocator: channel.allocator,
                        inboundChildChannelInitializer: nil
                    ),
                    EventHandler(),
                    ErrorHandler()
                ])
            }
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)

        let channel = try await bootstrap.connect(host: host, port: port).get()

        try await channel.pipeline.handler(type: EventHandler.self).flatMap { eventHandler -> EventLoopFuture<Void> in
            let promise = channel.eventLoop.makePromise(of: Void.self)
            eventHandler.requestAuthenticationResult(promise)
            return promise.futureResult
        }.get()

        return SshConnection(sshClient: self, channel: channel)
    }

    /// Deinitialize
    deinit {
        do {
            try eventLoopGroup.syncShutdownGracefully()
        } catch {
            fatalError("\(error)")
        }
    }
}
