// swift-tools-version: 6.1

//
// This source file is part of the ssutil open-source project
//
// SPDX-FileCopyrightText: 2025 Lukas Kollmer
//
// SPDX-License-Identifier: MIT
//

import PackageDescription

let package = Package(
    name: "ssutil",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "ssutil", targets: ["ssutilCLI"]),
        .library(name: "SSUtilLib", targets: ["SSUtilLib"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.6")
    ],
    targets: [
        .target(
            name: "SSUtilLib",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms")
            ]
        ),
        .executableTarget(
            name: "ssutilCLI",
            dependencies: [
                .target(name: "SSUtilLib"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "SSUtilLibTests",
            dependencies: [
                .target(name: "SSUtilLib"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [
                .process("Resources/inputs"),
                .copy("Resources/bezels"),
                .process("__Snapshots__")
            ]
        )
    ]
)
