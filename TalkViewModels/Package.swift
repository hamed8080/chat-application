// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TalkViewModels",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "TalkViewModels",
            targets: ["TalkViewModels"]),
    ],
    dependencies: [
        .package(path: "../TalkModels"),
        .package(path: "../TalkExtensions"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "TalkViewModels",
            dependencies: [
                "TalkModels",
                "TalkExtensions",
                .product(name: "Collections", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "TalkViewModelsTests",
            dependencies: ["TalkViewModels"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)
