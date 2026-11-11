// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Stroke",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Stroke", targets: ["StrokeApp"])
    ],
    targets: [
        .executableTarget(name: "StrokeApp", path: "Sources/StrokeApp")
    ]
)
