// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PenPalAI",
    platforms: [
        .macOS(.v12),  // Minimum macOS version
        .iOS(.v16),       // Minimum iOS version
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PenPalAI",
            targets: ["PenPalAI"])
    ],
    dependencies: [
        .package(url: "https://github.com/klein-artur/SwiftGPT", from: "1.0.0"),
        .package(url: "https://github.com/klein-artur/SwiftDose", from: "1.0.0")
    ],
    targets: [
        .systemLibrary(
            name: "CSQLite",
            path: "Sources/CSQLite",
            providers: [
                .apt(["libsqlite3-dev"]),
                .brew(["sqlite3"])
            ]
        ),
        .target(
            name: "PenPalAI",
            dependencies: ["SwiftGPT", "SwiftDose", "CSQLite"]),
        .testTarget(
            name: "PenPalAITests",
            dependencies: ["PenPalAI"]),
        ]
)
