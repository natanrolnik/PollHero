// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PollKit",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/rensbreur/SwiftTUI", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "PollKit",
            dependencies: [.product(name: "SwiftTUI", package: "SwiftTUI")]
        ),
    ]
)
