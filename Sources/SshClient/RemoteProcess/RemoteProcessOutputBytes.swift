import NIO

/// An AsyncSequence of single bytes, which are obtained from the ByteBuffer packets received by ``ExecHandler``.
final class RemoteProcessOutputBytes: AsyncSequence {
    enum Byte {
        case stdOut(UInt8)
        case stdErr(UInt8)
    }

    typealias Element = Byte

    private let channel: Channel
    private var data: ArraySlice<Byte>

    init(channel: Channel) {
        self.channel = channel
        self.data = [Byte]()[...]
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(remoteProcessOutputBytes: self)
    }

    struct AsyncIterator: AsyncIteratorProtocol {
        let remoteProcessOutputBytes: RemoteProcessOutputBytes

        mutating func next() async -> Byte? {
            if remoteProcessOutputBytes.data.isEmpty {
                let bufferFuture: EventLoopFuture<[ExecHandler.BufferItem]> =
                    remoteProcessOutputBytes.channel.pipeline.handler(type: ExecHandler.self).flatMap { [remoteProcessOutputBytes] execHandler in
                        let promise = remoteProcessOutputBytes.channel.eventLoop.makePromise(of: [ExecHandler.BufferItem].self)
                        execHandler.getBuffer(promise)
                        return promise.futureResult
                    }

                guard let buffer = try? await bufferFuture.get() else {
                    return nil
                }

                remoteProcessOutputBytes.data = [Byte]()[...]
                for bufferItem in buffer {
                    switch bufferItem {
                        case .stdOutBytes(let bytes): remoteProcessOutputBytes.data += Array(buffer: bytes).map { Byte.stdOut($0) }
                        case .stdErrBytes(let bytes): remoteProcessOutputBytes.data += Array(buffer: bytes).map { Byte.stdErr($0) }
                    }
                }
            }

            if let byte = remoteProcessOutputBytes.data.first {
                remoteProcessOutputBytes.data = remoteProcessOutputBytes.data.dropFirst()
                return byte
            } else {
                return nil
            }
        }
    }
}
