// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatAppViewModels",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "ChatAppViewModels",
            targets: ["ChatAppViewModels"]),
    ],
    dependencies: [
        .package(path: "../ChatAppModels"),
        .package(path: "../ChatAppExtensions"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "ChatAppViewModels",
            dependencies: [
                "ChatAppModels",
                "ChatAppExtensions",
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "ChatAppViewModelsTests",
            dependencies: ["ChatAppViewModels"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)
