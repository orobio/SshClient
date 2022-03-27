# ``SshClient``

Easy to use SSH client functionality with an asynchronous API (async/await), built on [swift-nio-ssh](https://github.com/apple/swift-nio-ssh).

## Overview
The following is a simple example of setting up an SSH connection and executing a remote command:

```swift
let sshConnection = try await SshClient().connect(host: "10.0.0.1", username: "username")
let remoteProcess = try await sshConnection.execute("ls")
for await line in remoteProcess.stdOutLines {
    print(line)
}
```

For more details, see: ``SshClient/SshClient``, ``SshConnection`` and ``RemoteProcess``.