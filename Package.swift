// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Schedule",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "Schedule", targets: ["Schedule"])
    ],
    targets: [
        .target(name: "Schedule"),
        .testTarget(name: "ScheduleTests", dependencies: ["Schedule"])
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
