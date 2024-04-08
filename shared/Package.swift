// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Shared",
    platforms: [
       .macOS(.v12)
    ],
    products: [
        .library(
            name: "Shared",
            targets: ["Shared"]
        )
    ],
    targets: [
        .target(
            name: "Shared",
            path: "."
        )
    ]
)

