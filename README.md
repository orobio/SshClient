# SshClient

Easy to use SSH client functionality with an asynchronous API (async/await), built on [swift-nio-ssh](https://github.com/apple/swift-nio-ssh).

`SshClient` currently provides the following functionality:

- Opening an SSH connection.
- Executing a command remotely.
- Getting an AsyncSequence with stdout and/or stderr output lines from the remote command.

## Usage

A simple example of setting up an SSH connection and executing a remote command:

```swift
let sshConnection = try await SshClient().connect(host: "10.0.0.1", username: "username")
let remoteProcess = try await sshConnection.execute("ls")
for await line in remoteProcess.stdOutLines {
    print(line)
}
```

## Documentation

For detailed documentation, please see: [SshClient documentation](https://orobio.github.io/SshClient/documentation/sshclient).

## Adding SshClient as a Dependency

To use `SshClient` in a SwiftPM project, add the following
line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/orobio/SshClient", from: "0.1.0"),
```

Include `"SshClient"` as a dependency for your executable target:

```swift
.target(name: "<target>", dependencies: [
    "SshClient",
]),
```

Finally, add `import SshClient` to your source code.

## Source Stability

This package does not have a stable 1.0.0 release yet. Public API can change at any time.
