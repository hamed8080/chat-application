// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatAppUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "ChatAppUI",
            targets: ["ChatAppUI"]),
    ],
    dependencies: [
        .package(path: "../../AdditiveUI"),
        .package(path: "../ChatAppModels"),
        .package(path: "../ChatAppExtensions"),
        .package(path: "../ChatAppViewModels"),
    ],
    targets: [
        .target(
            name: "ChatAppUI",
            dependencies: [
                "AdditiveUI",
                "ChatAppModels",
                "ChatAppExtensions",
                "ChatAppViewModels"
            ],
            resources: [.process("Resources/Fonts/")]
        ),
        .testTarget(
            name: "ChatAppUITests",
            dependencies: ["ChatAppUI"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)
