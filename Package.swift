// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SshClient",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "SshClient",
            targets: ["SshClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssh.git", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.1"),
    ],
    targets: [
        .target(
            name: "SshClient",
            dependencies: [
                .product(name: "NIOSSH", package: "swift-nio-ssh"),
            ]
        ),
        .executableTarget(
            name: "ssh-execute",
            dependencies: [
                "SshClient",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
