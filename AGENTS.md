# AGENTS.md

Project instructions for coding agents working in this repository.

## Build and packaging

- Use `Package.swift` for development compilation and tests. Use `CursorHighlighting.xcodeproj` for `.app` packaging, signing, archiving, and notarization.
- Treat `project.yml` as the source for generated Xcode project structure. After changing targets, resources, packages, or build settings, run `xcodegen generate` and commit both `project.yml` and the generated project changes.
- Keep `Package.resolved` and `CursorHighlighting.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` tracked. Resolve each build system normally; their `originHash` values need not match.
- Never assemble the release app manually from `.build`, place dependency `.bundle` directories at the `.app` root, or treat `swift run` as distribution validation.
- Before handoff, run `swift test`, `swift build -c release -Xswiftc -warnings-as-errors`, an Xcode Debug build, and `make verify`.

## Runtime conventions

- Defer event monitors, overlays, hotkey registration, and permission work until `applicationDidFinishLaunching`.
- Key Stroke capture uses the passive Core Graphics event tap and Input Monitoring permission. Request permission only after the user enables the feature; do not substitute Accessibility prompting.
- Reconcile overlay panels on `NSApplication.didChangeScreenParametersNotification` using stable display identifiers.
- Keep event-tap and AppKit monitor cleanup on `MainActor`. Limit `@unchecked Sendable` to the C callback bridge in `CGEventBridge.swift`.
