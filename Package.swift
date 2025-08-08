// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

//
//  Package.swift
//  ssutil
//
//  Created by Lukas Kollmer on 2025-08-07.
//  Copyright © 2025 Lukas Kollmer. All rights reserved.
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
    ]
)
