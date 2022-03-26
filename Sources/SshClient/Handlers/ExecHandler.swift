import NIO
import NIOSSH

/// Handler for executing remote command on SSH child channel.
///
/// Executes a command remotely and reads stdout and stderr output
/// into a buffer. Reads will only be done if the number of bytes
/// stored in the buffer is less than ``bytesInBufferThreshold``.
/// The buffer contents must be regularly requested with the
/// getBuffer() function to make room for new data.
final class ExecHandler: ChannelDuplexHandler {
    typealias InboundIn = SSHChannelData
    typealias InboundOut = Never
    typealias OutboundIn = Never
    typealias OutboundOut = SSHChannelData

    enum BufferItem {
        case stdOutBytes(ByteBuffer)
        case stdErrBytes(ByteBuffer)
    }

    private var context: ChannelHandlerContext?
    private var exitCodePromise: EventLoopPromise<Int>?
    private let command: String

    private var buffer: [BufferItem] = []
    private var bytesInBuffer: Int = 0
    private let bytesInBufferThreshold = 64 * 1024
    private var bufferPromise: EventLoopPromise<[BufferItem]>?

    private var shouldFireRead = false
    private var inputIsClosed = false

    init(command: String, exitCodePromise: EventLoopPromise<Int>) {
        self.exitCodePromise = exitCodePromise
        self.command = command
    }

    func handlerAdded(context: ChannelHandlerContext) {
        self.context = context
        context.channel.setOption(ChannelOptions.allowRemoteHalfClosure, value: true).whenFailure { error in
            context.fireErrorCaught(error)
        }
    }

    func channelActive(context: ChannelHandlerContext) {
        let execRequest = SSHChannelRequestEvent.ExecRequest(command: self.command, wantReply: false)
        context.triggerUserOutboundEvent(execRequest).whenFailure { _ in
            context.close(promise: nil)
        }
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        switch event {
        case let event as SSHChannelRequestEvent.ExitStatus:
            if let promise = self.exitCodePromise {
                self.exitCodePromise = nil
                promise.succeed(event.exitStatus)
            }

        case ChannelEvent.inputClosed:
            self.inputIsClosed = true
            if self.bufferPromise != nil {
                fulfillBufferPromise()
            }

        default:
            context.fireUserInboundEventTriggered(event)
        }
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        if let promise = self.exitCodePromise {
            self.exitCodePromise = nil
            promise.fail(SshClientError.commandExecFailed)
        }

        self.context = nil
    }

    func read(context: ChannelHandlerContext) {
        if self.bytesInBuffer < bytesInBufferThreshold {
            context.read()
        } else {
            self.shouldFireRead = true
        }
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)

        guard case .byteBuffer(let bytes) = data.data else {
            fatalError("Unexpected read type")
        }

        switch data.type {
        case .channel:
            self.buffer.append(.stdOutBytes(bytes))
            self.bytesInBuffer += bytes.readableBytes

        case .stdErr:
            self.buffer.append(.stdErrBytes(bytes))
            self.bytesInBuffer += bytes.readableBytes

        default:
            fatalError("Unexpected message type")
        }

        if self.bufferPromise != nil {
            fulfillBufferPromise()
        }
    }

    func getBuffer(_ promise: EventLoopPromise<[BufferItem]>) {
        guard self.bufferPromise == nil else {
            fatalError("Only one buffer promise can be active")
        }

        self.bufferPromise = promise

        if !self.buffer.isEmpty || self.inputIsClosed {
            fulfillBufferPromise()
        }
    }

    func fulfillBufferPromise() {
        guard let promise = self.bufferPromise else {
            fatalError("No promise available")
        }

        self.bufferPromise = nil
        promise.succeed(self.buffer)
        self.buffer = []
        self.bytesInBuffer = 0

        if self.shouldFireRead,
           let context = self.context {
            self.shouldFireRead = false
            context.read()
        }
    }
}
