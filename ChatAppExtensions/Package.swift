// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatAppExtensions",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "ChatAppExtensions",
            targets: ["ChatAppExtensions"]),
    ],
    dependencies: [
        .package(path: "../ChatAppModels")
    ],
    targets: [
        .target(
            name: "ChatAppExtensions",
            dependencies: [
                "ChatAppModels"
            ]
        ),
        .testTarget(
            name: "ChatAppExtensionsTests",
            dependencies: ["ChatAppExtensions"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)
