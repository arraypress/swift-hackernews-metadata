// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HackerNewsMetadata",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "HackerNewsMetadata",
            targets: ["HackerNewsMetadata"]
        ),
    ],
    targets: [
        .target(
            name: "HackerNewsMetadata",
            dependencies: []
        ),
        .testTarget(
            name: "HackerNewsMetadataTests",
            dependencies: ["HackerNewsMetadata"]
        ),
    ]
)
