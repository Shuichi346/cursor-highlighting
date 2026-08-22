// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CursorHighlighting",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "CursorHighlighting", targets: ["CursorHighlighting"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "3.0.1"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.1.0"),
        .package(url: "https://github.com/sindresorhus/Defaults", from: "9.0.9"),
    ],
    targets: [
        .executableTarget(
            name: "CursorHighlighting",
            dependencies: [
                "KeyboardShortcuts",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                "Defaults",
            ],
            path: "Sources/CursorHighlighting"
        ),
        .testTarget(
            name: "CursorHighlightingTests",
            dependencies: ["CursorHighlighting"],
            path: "Tests/CursorHighlightingTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
