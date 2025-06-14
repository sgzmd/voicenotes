// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VoiceNotesApp",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.12.0")
    ],

    targets: [
        .target(
            name: "TranscriptionService",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit")
            ],
            path: "Sources/TranscriptionService"
        ),
        .executableTarget(
            name: "VoiceNotesApp",
            dependencies: [
                "TranscriptionService",
                .product(name: "WhisperKit", package: "WhisperKit"),
            ],
            linkerSettings: [
                .linkedFramework("CoreAudio")
            ]
        ),
        .testTarget(
            name: "TranscriptionServiceTests",
            dependencies: ["TranscriptionService"],

            path: "Tests/TranscriptionService",
            resources: [
                .copy("TestModels")
            ]
        ),
    ]

)
