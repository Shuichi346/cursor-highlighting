// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CursorHighlighting",
    defaultLocalization: "en",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "CursorHighlighting", targets: ["CursorHighlighting"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.4.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.1.0"),
        .package(url: "https://github.com/sindresorhus/Defaults", from: "9.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "CursorHighlighting",
            dependencies: [
                "KeyboardShortcuts",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                "Defaults",
            ],
            path: "Sources/CursorHighlighting",
            exclude: ["Resources/Info.plist"],
            resources: [.process("Resources")]
        )
    ],
    swiftLanguageModes: [.v6]
)
