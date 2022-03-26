import NIO

/// AsyncSequence of lines from stdout and stderr of a remote process.
public final class RemoteProcessOutputLines: AsyncSequence {
    /// Output line from a remote process.
    public enum Line {
        case stdOut(String)
        case stdErr(String)
    }

    public typealias Element = Line

    private let remoteProcessOutputBytes: RemoteProcessOutputBytes
    private var stdOut = [UInt8]()
    private var stdErr = [UInt8]()

    init(channel: Channel) {
        remoteProcessOutputBytes = RemoteProcessOutputBytes(channel: channel)
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(remoteProcessOutputLines: self)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        let remoteProcessOutputLines: RemoteProcessOutputLines

        public mutating func next() async -> Line? {
            let AsciiNewline = 0x0A

            for await outputByte in remoteProcessOutputLines.remoteProcessOutputBytes {
                switch outputByte {
                case .stdOut(let byte):
                    if byte == AsciiNewline {
                        if let string = String(bytes: remoteProcessOutputLines.stdOut, encoding: .utf8) {
                            remoteProcessOutputLines.stdOut = []
                            return .stdOut(string)
                        } else {
                            remoteProcessOutputLines.stdOut = []
                        }
                    } else {
                        remoteProcessOutputLines.stdOut.append(byte)
                    }

                case .stdErr(let byte):
                    if byte == AsciiNewline {
                        if let string = String(bytes: remoteProcessOutputLines.stdErr, encoding: .utf8) {
                            remoteProcessOutputLines.stdErr = []
                            return .stdErr(string)
                        } else {
                            remoteProcessOutputLines.stdErr = []
                        }
                    } else {
                        remoteProcessOutputLines.stdErr.append(byte)
                    }
                }
            }

            if !remoteProcessOutputLines.stdOut.isEmpty,
               let string = String(bytes: remoteProcessOutputLines.stdOut, encoding: .utf8) {
                remoteProcessOutputLines.stdOut = []
                return .stdOut(string)
            }

            if !remoteProcessOutputLines.stdErr.isEmpty,
               let string = String(bytes: remoteProcessOutputLines.stdErr, encoding: .utf8) {
                remoteProcessOutputLines.stdErr = []
                return .stdErr(string)
            }

            return nil
        }
    }
}
