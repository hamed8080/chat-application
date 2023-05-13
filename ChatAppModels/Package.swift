// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatAppModels",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ChatAppModels",
            targets: ["ChatAppModels"]),
    ],
    dependencies: [
        .package(path: "../../Chat"),
    ],
    targets: [
        .target(
            name: "ChatAppModels",
            dependencies: [
                "Chat",
            ]
        ),
        .testTarget(
            name: "ChatAppModelsTests",
            dependencies: ["ChatAppModels"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)
