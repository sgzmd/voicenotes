// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TranscriptionService",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "TranscriptionService",
            targets: ["TranscriptionService"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TranscriptionService",
            dependencies: []
        )
    ]
)
