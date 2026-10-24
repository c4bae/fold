// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "WindowNotch",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WindowNotch",
            path: "Sources/WindowNotch"
        ),
        .testTarget(
            name: "WindowNotchTests",
            dependencies: ["WindowNotch"],
            path: "Tests/WindowNotchTests"
        ),
    ]
)
