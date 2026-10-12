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

## Documentation maintenance

- After completed implementation work, update `CHANGELOG.md`, the detailed `doc/CHANGELOG.md`, `NOTES.md`, and `AGENTS.md` in English using the current task's evidence, including already committed or pushed work.
- Record what changed in the changelog in past tense under `Fixed`, `Added`, `Changed`, and `Removed`. Omit empty categories and routine cleanup or test-only changes unless their impact matters.
- Use `## YYYY-MM-DD` for new work, newest first, and append to existing same-day categories. Use the completion date in the user's timezone; do not guess dates or release versions. Preserve existing dated/versioned history and classify undated historical entries directly under `Fixed`, `Added`, `Changed`, and `Removed`. Do not create new `Unreleased` sections.
- Keep causes, solution rationale, behavior to preserve, known useful paths/tests, and unresolved limitations in `NOTES.md`, following its existing conventions. Keep durable, verified repository instructions in `AGENTS.md`; avoid duplicate summaries, session logs, and one-time rules.
- Read only relevant sections needed to avoid duplicates or contradictions. Reuse task evidence; inspect the smallest relevant diff or source excerpt only for missing material facts, without routinely rebuilding history.
- For a full update, consider all three root files and create missing files with minimal headings. Leave existing files unchanged when there is nothing material to add.
- Review the documentation diff and unresolved references, and run required documentation checks. Documentation-only changes do not require rerunning implementation tests solely to record the work.
