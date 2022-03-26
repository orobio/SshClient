import NIO

/// AsyncSequence of lines from stdout or stderr of a remote process.
public struct RemoteProcessSingleChannelOutputLines: AsyncSequence {
    enum OutputChannel {
        case stdOut
        case stdErr
    }

    public typealias Element = String

    private let remoteProcessOutputLines: RemoteProcessOutputLines
    private let outputChannel: OutputChannel

    init(channel: Channel, outputChannel: OutputChannel) {
        self.remoteProcessOutputLines = RemoteProcessOutputLines(channel: channel)
        self.outputChannel = outputChannel
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(remoteProcessOutputLinesAsyncIterator: remoteProcessOutputLines.makeAsyncIterator(), outputChannel: outputChannel)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        var remoteProcessOutputLinesAsyncIterator: RemoteProcessOutputLines.AsyncIterator
        let outputChannel: OutputChannel

        public mutating func next() async -> String? {
            while let next = await remoteProcessOutputLinesAsyncIterator.next() {
                switch next {
                    case .stdOut(let line): if outputChannel == .stdOut { return line }
                    case .stdErr(let line): if outputChannel == .stdErr { return line }
                }
            }
            return nil
        }
    }
}
