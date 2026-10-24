// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Fold",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Fold",
            path: "Sources/Fold"
        ),
        .testTarget(
            name: "FoldTests",
            dependencies: ["Fold"],
            path: "Tests/FoldTests"
        ),
    ]
)
