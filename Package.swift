// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CursorHighlighting",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "CursorHighlighting", targets: ["CursorHighlighting"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.4.0"),
        .package(url: "https://github.com/sindresorhus/Settings", from: "3.1.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.1.0"),
        .package(url: "https://github.com/sindresorhus/Defaults", from: "9.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "CursorHighlighting",
            dependencies: [
                "KeyboardShortcuts",
                "Settings",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                "Defaults",
            ],
            path: "Sources/CursorHighlighting",
            resources: [.process("Resources")]
        ),
    ],
    swiftLanguageVersions: [.v6]
)
