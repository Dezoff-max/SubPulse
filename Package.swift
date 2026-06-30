// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SubPulse",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SubPulse", targets: ["SubPulse"]),
        .executable(name: "SubPulseWidgets", targets: ["SubPulseWidgets"])
    ],
    targets: [
        .executableTarget(
            name: "SubPulse",
            path: "Sources/SubPulse"
        ),
        .executableTarget(
            name: "SubPulseWidgets",
            path: "Sources/SubPulseWidgets",
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-e", "-Xlinker", "_NSExtensionMain"])
            ]
        ),
        .testTarget(
            name: "SubPulseTests",
            dependencies: ["SubPulse"],
            path: "Tests/SubPulseTests"
        )
    ]
)
