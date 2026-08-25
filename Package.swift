// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "SwiftSP621E",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "SwiftSP621E",
            targets: ["SwiftSP621E"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftSP621E",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
