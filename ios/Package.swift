// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "GIBowlCore",
    platforms: [
        .iOS("27.0"),
        .macOS("27.0"),
    ],
    products: [
        .library(name: "GIBowlCore", targets: ["GIBowlCore"]),
    ],
    targets: [
        .target(name: "GIBowlCore"),
        .testTarget(name: "GIBowlCoreTests", dependencies: ["GIBowlCore"]),
    ]
)
