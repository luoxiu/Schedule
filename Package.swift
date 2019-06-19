// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Schedule",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
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
