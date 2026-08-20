# Notes

## 2026-08-20

- Kept `Package.swift` for development builds and tests, while making `CursorHighlighting.xcodeproj` the authority for application packaging and signing.
- Replaced the invalid dependency-bundle-at-app-root workaround with Xcode-managed resources under `Contents/Resources`.
- Verified SwiftPM Debug tests, a warning-free SwiftPM Release build, Xcode Debug and Release builds, universal architectures, sealed resources, and strict code signing.
- Left live GUI/TCC and physical multi-monitor smoke testing for manual validation.
- Did not exercise Developer ID signing or notarization because those steps require maintainer credentials and external Apple services.
