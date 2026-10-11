// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DigitalCodeExtractor",
    platforms: [
        .iOS(.v15),
        .macOS(.v14),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DigitalCodeExtractor",
            targets: ["DigitalCodeExtractor"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DigitalCodeExtractor",
            resources: [
                // Copy the pre-compiled Core ML model verbatim. `.copy` preserves
                // the `.mlmodelc` bundle directory (which `.process` would flatten).
                .copy("Resources/DigitalCodeDetector.mlmodelc")
            ]
        ),
        .testTarget(
            name: "DigitalCodeExtractorTests",
            dependencies: ["DigitalCodeExtractor"]
        ),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
