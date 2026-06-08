// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ToneBar",
    platforms: [
        .macOS("26.0")
    ],
    targets: [
        .executableTarget(
            name: "ToneBar",
            path: "Sources/ToneBar",
            swiftSettings: [
                // Keep Swift 5 language mode so the CoreAudio C callbacks and
                // ObservableObject plumbing don't trip strict-concurrency errors.
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
