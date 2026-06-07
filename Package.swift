// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SubPulse",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SubPulse", targets: ["SubPulse"])
    ],
    targets: [
        .executableTarget(
            name: "SubPulse",
            path: "Sources/SubPulse"
        ),
        .testTarget(
            name: "SubPulseTests",
            dependencies: ["SubPulse"],
            path: "Tests/SubPulseTests"
        )
    ]
)
