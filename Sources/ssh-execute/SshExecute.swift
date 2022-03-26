import Glibc
import ArgumentParser
import SshClient

func currentUser() -> String {
    String(cString: getlogin())
}

struct StdErr: TextOutputStream {
    mutating func write(_ string: String) { fputs(string, stderr) }
    static var stream = Self()
}

@main
struct SshExecute: AsyncParsableCommand {
    @Argument(help: "The host to connect to.")
    var host: String

    @Argument(help: "The command to execute.")
    var command: String

    @Option(name: .shortAndLong, help: "The port to connect to.")
    var port = 22

    @Option(name: .shortAndLong, help: "The username to use for logging in.")
    var user: String?

    mutating func run() async throws {
        let username = user ?? currentUser()
        let sshConnection = try await SshClient().connect(host: host, username: username, port: port)

        let remoteProcess = try await sshConnection.execute(command)
        for await line in remoteProcess.stdOutAndStdErrLines {
            switch line {
            case .stdOut(let line): print(line)
            case .stdErr(let line): print(line, to: &StdErr.stream)
            }
        }

        let exitCode = try await remoteProcess.exitCode
        throw ExitCode(Int32(exitCode))
    }
}
