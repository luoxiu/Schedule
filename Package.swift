// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "Schedule",
    products: [
        .library(name: "Schedule", targets: ["Schedule"]),
        .executable(name: "ScheduleDemo", targets: ["ScheduleDemo"])
    ],
    targets: [
        .target(name: "Schedule"),
        .testTarget(name: "ScheduleTests", dependencies: ["Schedule"]),
        .target(name: "ScheduleDemo", dependencies: ["Schedule"])
    ]
)
