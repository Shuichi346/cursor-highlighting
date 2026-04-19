**Implementation Plan: cursor-highlighting**

**Overview:**
A macOS menu-bar-only utility application that visually highlights mouse operations and keyboard input for presentations, screen recordings, and live streaming. The app provides three core features — Mouse Spotlight (dims the screen except for a circle around the cursor), Mouse Clicks (animated rings on click), and Key Strokes (on-screen display of pressed keys) — all togglable via global hotkeys. Built entirely in **Swift 6.3 language mode** using Swift Package Manager, targeting **macOS 26 (Tahoe)** exclusively.

---

**Why Swift 6.3 Language Mode (Not Swift 5 Compatibility)**

This plan enforces Swift 6.3 language mode (`swiftLanguageVersions: [.v6]`) for three structural reasons:

**① Complete elimination of data races at compile time.** This application uniquely combines low-level input signal reception (C-convention `CGEventTapCallBack` firing on an arbitrary background thread) with high-level UI drawing (overlay windows updating at display refresh rate on `@MainActor`). In Swift 5 mode, an incorrect thread handoff between these layers would produce a non-deterministic bug — "occasional app freezing" or "crash during specific operations" — discoverable only at runtime, if ever. Swift 6's strict concurrency checking elevates every such data race to a **compile error**. The bridge pattern in this plan (`AsyncStream.Continuation.yield` from the C callback → `for await` on `@MainActor`) is verified safe by the compiler itself. No manual audit required, no runtime surprises.

**② Compliance with Apple's forward trajectory.** Apple is progressively tightening memory safety and isolation requirements for APIs touching Accessibility and Input Monitoring (TCC-controlled). Code written in Swift 5 patterns (unguarded `DispatchQueue.main.async`, raw pointer juggling via `Unmanaged`) is at increasing risk of deprecation warnings, behavioral changes, or outright rejection in future macOS releases. Swift 6.3 patterns — `@MainActor` isolation, structured concurrency, `Sendable`-verified data flow — align with Apple's stated direction and maximize the application's longevity against OS evolution.

**③ Performance and efficiency for real-time input tracking.** Swift 6.3's `AsyncStream` and `Task` have measurably less runtime overhead than legacy `DispatchQueue` hop patterns. For mouse tracking at display refresh rate (120Hz on ProMotion displays), each microsecond of dispatch overhead matters. The `AsyncStream` bridge yields events directly into the consuming `Task` without GCD queue scheduling, context switching, or autorelease pool overhead. This is structurally more efficient for the sustained high-frequency event processing this application requires.

**The CGEventTapCallBack → AsyncStream Bridge Pattern:**

The central technical challenge is safely bridging `CGEventTapCallBack` (a `@convention(c)` function pointer called on an arbitrary thread by CoreGraphics) into Swift's structured concurrency world. The solution:

1. `AsyncStream.Continuation` is **`Sendable` and documented as thread-safe** (Apple's source: "It is thread safe to send and finish; all calls to the continuation are serialized"). This means `continuation.yield(value)` can be safely called from any thread — including the C callback thread — without violating Swift 6 concurrency rules.
2. The `Continuation` is stored in a `nonisolated(unsafe)` or `@unchecked Sendable` wrapper that the C callback accesses via `UnsafeMutableRawPointer` (the `userInfo` parameter of `CGEvent.tapCreate`). Since the continuation itself is `Sendable`, only the pointer bridging is unsafe — and this unsafety is minimal, explicit, and confined to a single 5-line wrapper.
3. A `Task { @MainActor in for await event in stream { ... } }` consumes the stream, guaranteeing all UI updates happen on the main actor. The compiler verifies this isolation statically.

This pattern **eliminates the entire class of bugs** where a developer accidentally accesses UI state from the callback thread. In Swift 5 mode, such a bug would compile silently and crash at runtime.

---

**Stated Assumptions:**
1. The app is **not sandboxed**. It requires Accessibility and Input Monitoring permissions via TCC, which require an unsandboxed execution context for `CGEvent.tapCreate` with `.listenOnly`.
2. The app is a **menu-bar-only agent** (`LSUIElement = true`); no Dock icon, no main application window.
3. The settings window uses `sindresorhus/Settings` for tab-based layout.
4. Localization uses traditional `Localizable.strings` files bundled as SPM resources. English (`en`) is the default; Japanese (`ja`) is the second language.
5. The user builds via `swift build` / `swift run` from the terminal using `Makefile`. Xcode 26.4 is installed (providing the Swift 6.3 toolchain and macOS 26 SDK) but is not used as an editor.
6. Targets single display (`NSScreen.main`). Multi-monitor support is out of scope for v1.0.
7. Code-signing is not required for local development. `make app` produces an unsigned `.app` bundle. Distribution-grade signing is out of scope.
8. All sindresorhus dependencies compile cleanly when imported into a Swift 6 language mode project because SPM compiles each package with its own declared language mode independently.

**Requirements:**
1. **R1:** Menu-bar-only agent with `NSStatusItem` icon (SF Symbol `cursorarrow.rays`).
2. **R2:** Menu bar dropdown: toggles for each feature, "Settings…", "Quit".
3. **R3 — Mouse Spotlight:** Fullscreen dim overlay with cursor-following bright circle. Customizable: radius (px), blur (px), opacity (0.0–1.0), color. Default hotkey: `Shift+1`.
4. **R4 — Mouse Clicks:** Expanding/fading ring animation on left-click (default blue `#007AFF`) and right-click (default red `#FF3B30`). Customizable: colors, max ring radius.
5. **R5 — Key Strokes:** Pressed keys displayed in bottom-center HUD. Modifier keys as macOS symbols (`⌘⌥⇧⌃⇪fn`). Fades after 2s inactivity. Customizable: on/off, font size.
6. **R6 — Settings:** 4-tab window: Mouse Spotlight, Mouse Clicks, Key Strokes, Others.
7. **R7 — Others Tab:** Launch at Login toggle, language switcher (English/Japanese).
8. **R8 — Localization:** All UI strings in English and Japanese. Default English. Switchable in Settings.
9. **R9 — Permissions:** On launch, check Accessibility via `AXIsProcessTrustedWithOptions`; poll until granted.
10. **R10 — Build:** `make run` builds+runs. `make app` produces `CursorHighlighting.app` bundle.
11. **R11 — Repository:** `.gitignore`, `README.md`, `CHANGELOG.md`, `LICENSE` (MIT).
12. **R12 — Code Comments:** All inline comments in Japanese.
13. **R13 — Swift 6.3:** All source compiled in Swift 6 language mode. Zero concurrency warnings. Zero `@unchecked Sendable` on application-level types (only permitted on the minimal C-bridge wrapper).

**Tech Stack and Conventions:**
- **Compiler:** Swift 6.3 (bundled with Xcode 26.4)
- **Language mode:** Swift 6 (`swiftLanguageVersions: [.v6]`)
- **UI:** SwiftUI + AppKit interop (`NSPanel` for overlays)
- **Package manager:** Swift Package Manager (`swift-tools-version: 6.3`)
- **Target platform:** `platforms: [.macOS(.v26)]`
- **Dependencies:**
  - `sindresorhus/KeyboardShortcuts` from `"2.4.0"` — Global hotkey recording and listening
  - `sindresorhus/Settings` from `"3.1.0"` — Tabbed settings window
  - `sindresorhus/LaunchAtLogin-Modern` from `"1.1.0"` — Launch at Login
  - `sindresorhus/Defaults` from `"9.0.0"` — Type-safe UserDefaults
- **File naming:** PascalCase for Swift source files
- **Module name:** `CursorHighlighting`
- **Entry point:** `@main` on the SwiftUI `App` struct
- **Concurrency model:**
  - All UI code is `@MainActor`-isolated
  - C callbacks bridge to `AsyncStream` via `Sendable` continuation
  - No `DispatchQueue.main.async` anywhere in application code — all main-thread dispatch is via `@MainActor` isolation or `Task { @MainActor in }`

**Boundaries:**

```
✅ Always:
  - Use Swift 6 language mode strict concurrency throughout
  - Bridge C callbacks exclusively via AsyncStream.Continuation (Sendable, thread-safe)
  - Use @MainActor for all UI-mutating code
  - Write all code comments in Japanese
  - Use sindresorhus libraries for hotkeys, settings, defaults, launch-at-login

⚠️ Ask First:
  - Adding any dependency not listed in this plan
  - Using @unchecked Sendable on any type other than the CGEvent bridge wrapper
  - Changing the deployment target from macOS 26

🚫 Never:
  - Use Xcode project files (.xcodeproj / .xcworkspace)
  - Use storyboards or XIBs
  - Use DispatchQueue.main.async for main-thread dispatch (use @MainActor instead)
  - Use Swift 5 language mode or swiftSettings: [.swiftLanguageMode(.v5)]
  - Use cuda or any GPU API other than CPU-based Core Animation / Core Graphics
  - Commit secrets, API keys, or tokens to source control
```

**Architecture:**

```
cursor-highlighting/
├── Package.swift
├── Makefile
├── LICENSE
├── README.md
├── CHANGELOG.md
├── .gitignore
└── Sources/
    └── CursorHighlighting/
        ├── App/
        │   ├── CursorHighlightingApp.swift          // @main entry point, MenuBarExtra
        │   ├── AppState.swift                       // @MainActor observable, owns all managers
        │   └── PermissionManager.swift              // AX permission check + poll
        ├── Bridge/
        │   ├── CGEventBridge.swift                  // CGEvent tap → AsyncStream bridge
        │   └── NSEventBridge.swift                  // NSEvent global monitor → AsyncStream bridge
        ├── Features/
        │   ├── Spotlight/
        │   │   ├── SpotlightManager.swift           // Feature orchestrator
        │   │   ├── SpotlightOverlayWindow.swift     // OverlayPanel + SpotlightView lifecycle
        │   │   └── SpotlightOverlayView.swift       // NSView, Core Graphics drawing
        │   ├── ClickVisualizer/
        │   │   ├── ClickManager.swift               // Mouse click monitoring
        │   │   ├── ClickOverlayWindow.swift         // OverlayPanel lifecycle
        │   │   └── ClickRingView.swift              // CAShapeLayer ring animation
        │   └── KeyStroke/
        │       ├── KeyStrokeManager.swift           // CGEvent tap consumer
        │       ├── KeyStrokeOverlayWindow.swift     // OverlayPanel + SwiftUI hosting
        │       └── KeyStrokeHUDView.swift           // SwiftUI HUD view
        ├── Settings/
        │   ├── SettingsManager.swift                // Defaults.Keys + KeyboardShortcuts.Name
        │   ├── SpotlightSettingsView.swift
        │   ├── ClickSettingsView.swift
        │   ├── KeyStrokeSettingsView.swift
        │   └── OtherSettingsView.swift
        ├── Overlay/
        │   └── OverlayPanel.swift                   // Shared NSPanel subclass
        ├── Utilities/
        │   ├── KeySymbols.swift                     // Keycode → symbol mapping
        │   ├── CodableColor.swift                   // Color serialization for Defaults
        │   └── L10n.swift                           // Localization helper
        └── Resources/
            ├── Info.plist
            ├── en.lproj/
            │   └── Localizable.strings
            └── ja.lproj/
                └── Localizable.strings
```

**Agent Summary:**

| Agent               | Step Count | Phases Involved  |
|----------------------|------------|------------------|
| devops-agent         | 6          | 1, 8             |
| coding-agent         | 20         | 2, 3, 4, 5, 6, 7 |
| documentation-agent  | 3          | 1, 8             |
| review-agent         | 8          | 1, 2, 3, 4, 5, 6, 7, 8 |

---

## Phase 1: Project Scaffolding and Build Infrastructure
**Purpose:** Establish the project skeleton with Swift 6.3 tooling, dependencies, and build system. After this phase, `swift build` succeeds and `make run` launches a minimal menu-bar app.

### Step 1.1: Create `Package.swift`
- **Agent:** devops-agent
- **Location:** `cursor-highlighting/Package.swift`
- **Action:** Create the Swift Package Manager manifest.
- **Details:**
  ```swift
  // swift-tools-version: 6.3
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
  ```
  - **Key decision:** `swift-tools-version: 6.3` ensures we use the latest SPM features including `.macOS(.v26)`. `swiftLanguageVersions: [.v6]` enforces strict concurrency for our target. Dependencies compile with their own declared language mode (typically Swift 5), which is handled transparently by SPM.
- **Dependencies:** None
- **Verification:** `cd cursor-highlighting && swift package resolve` completes with 0 errors; all 4 dependencies resolve.
- **Complexity:** Low
- **Risk:** Medium — If any sindresorhus package declares an upper bound on swift-tools-version that conflicts, resolution will fail. Mitigation: the specified versions (2.4.0+, 3.1.0+, 1.1.0+, 9.0.0+) are all recent and support Swift 6 toolchains as consumers. If resolution fails, the agent should inspect the error and try the latest release tag for the failing package.

### Step 1.2: Create Directory Structure
- **Agent:** devops-agent
- **Location:** `cursor-highlighting/Sources/CursorHighlighting/`
- **Action:** Create all directories per the Architecture tree. Place `.gitkeep` in empty directories.
- **Details:** Directories to create:
  `App/`, `Bridge/`, `Features/Spotlight/`, `Features/ClickVisualizer/`, `Features/KeyStroke/`, `Settings/`, `Overlay/`, `Utilities/`, `Resources/en.lproj/`, `Resources/ja.lproj/`
- **Dependencies:** Step 1.1
- **Verification:** `find Sources -type d | sort` matches expected structure.
- **Complexity:** Low
- **Risk:** Low

### Step 1.3: Create `.gitignore`
- **Agent:** devops-agent
- **Location:** `cursor-highlighting/.gitignore`
- **Action:** Create `.gitignore`.
- **Details:**
  ```
  # macOS
  .DS_Store
  Thumbs.db
  ._*

  # Swift / SPM
  .build/
  .swiftpm/
  Package.resolved
  *.xcodeproj
  *.xcworkspace
  xcuserdata/
  DerivedData/

  # Build output
  build/
  ```
- **Dependencies:** None
- **Verification:** File exists with listed patterns.
- **Complexity:** Low
- **Risk:** Low

### Step 1.4: Create `LICENSE`
- **Agent:** documentation-agent
- **Location:** `cursor-highlighting/LICENSE`
- **Action:** Create MIT License file with year 2026 and copyright holder `cursor-highlighting contributors`.
- **Dependencies:** None
- **Verification:** File contains "MIT License".
- **Complexity:** Low
- **Risk:** Low

### Step 1.5: Create `Info.plist`
- **Agent:** devops-agent
- **Location:** `Sources/CursorHighlighting/Resources/Info.plist`
- **Action:** Create macOS app Info.plist.
- **Details:** XML property list with keys:
  - `CFBundleName` = `"CursorHighlighting"`
  - `CFBundleDisplayName` = `"Cursor Highlighting"`
  - `CFBundleIdentifier` = `"com.github.cursor-highlighting"`
  - `CFBundleVersion` = `"1.0.0"`
  - `CFBundleShortVersionString` = `"1.0.0"`
  - `CFBundlePackageType` = `"APPL"`
  - `CFBundleExecutable` = `"CursorHighlighting"`
  - `LSMinimumSystemVersion` = `"26.0"`
  - `LSUIElement` = `true` (boolean — menu-bar-only, no Dock icon)
  - `NSHighResolutionCapable` = `true` (boolean)
  - `CFBundleAllowMixedLocalizations` = `true` (boolean)
  - `CFBundleDevelopmentRegion` = `"en"`
- **Dependencies:** Step 1.2
- **Verification:** `plutil -lint Sources/CursorHighlighting/Resources/Info.plist` returns OK.
- **Complexity:** Low
- **Risk:** Low

### Step 1.6: Create Minimal Entry Point
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/App/CursorHighlightingApp.swift`
- **Action:** Create the `@main` SwiftUI App struct with a minimal `MenuBarExtra`.
- **Details:**
  - Define `@main struct CursorHighlightingApp: App`.
  - `body` contains a single `MenuBarExtra("Cursor Highlighting", systemImage: "cursorarrow.rays")` with a `Button("Quit") { NSApplication.shared.terminate(nil) }` inside.
  - Import `SwiftUI` and `AppKit`.
  - This file must compile under Swift 6 language mode with zero warnings.
- **Dependencies:** Steps 1.1, 1.2
- **Verification:** `swift build` succeeds with 0 errors and 0 warnings.
- **Complexity:** Low
- **Risk:** Low

### Step 1.7: Create `Makefile`
- **Agent:** devops-agent
- **Location:** `cursor-highlighting/Makefile`
- **Action:** Create Makefile with `run`, `app`, and `clean` targets.
- **Details:**
  ```makefile
  APP_NAME = CursorHighlighting
  BUILD_DIR = .build/release
  APP_BUNDLE = build/$(APP_NAME).app
  RESOURCE_BUNDLE = $(BUILD_DIR)/CursorHighlighting_CursorHighlighting.bundle

  .PHONY: run app build-release clean

  run:
  	swift run $(APP_NAME)

  build-release:
  	swift build -c release

  app: build-release
  	rm -rf $(APP_BUNDLE)
  	mkdir -p $(APP_BUNDLE)/Contents/MacOS
  	mkdir -p $(APP_BUNDLE)/Contents/Resources
  	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
  	cp Sources/$(APP_NAME)/Resources/Info.plist $(APP_BUNDLE)/Contents/
  	@if [ -d "$(RESOURCE_BUNDLE)" ]; then \
  		cp -r $(RESOURCE_BUNDLE) $(APP_BUNDLE)/Contents/Resources/; \
  	fi
  	@echo "✅ Built $(APP_BUNDLE)"

  clean:
  	swift package clean
  	rm -rf build/
  ```
  - **IMPORTANT:** Makefile indentation must use actual tab characters, not spaces.
- **Dependencies:** Steps 1.1, 1.5, 1.6
- **Verification:** `make run` launches the app with menu bar icon. `make app` produces `build/CursorHighlighting.app`. `file build/CursorHighlighting.app/Contents/MacOS/CursorHighlighting` shows Mach-O arm64 executable.
- **Complexity:** Medium
- **Risk:** Medium — SPM resource bundle naming may differ. After first `swift build -c release`, agent should check `ls .build/release/*.bundle` to confirm exact name and update Makefile variable if needed.

### Step 1.G: Phase Gate — Project Scaffolding Verification
- **Agent:** review-agent
- **Action:** Verify Phase 1 is complete.
- **Verification:**
  1. `swift package resolve` — 0 errors.
  2. `swift build` — 0 errors, 0 warnings (strict concurrency active).
  3. `make run` — app launches, menu bar icon `cursorarrow.rays` visible, "Quit" button works.
  4. `make app` — produces `build/CursorHighlighting.app` with valid Mach-O binary.
  5. `.gitignore`, `LICENSE` present.
- **Dependencies:** Steps 1.1–1.7

---

## Phase 2: Core Infrastructure — Bridges, Overlay, Settings, Permissions, Localization
**Purpose:** Build all shared foundational components. This is the most critical phase: it establishes the concurrency-safe C-to-Swift bridge pattern, the reusable overlay panel, centralized settings, permission management, and localization. After this phase, the app has a functioning settings window with 4 tabs and permission handling.

### Step 2.1: Create `CGEventBridge.swift` — C Callback → AsyncStream Bridge
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Bridge/CGEventBridge.swift`
- **Action:** Create the concurrency-safe bridge that converts `CGEventTapCallBack` events into an `AsyncStream`.
- **Details:**
  - Define a value type for events crossing the bridge:
    ```
    struct BridgedKeyEvent: Sendable {
        let keyCode: Int64
        let flags: CGEventFlags
        let type: CGEventType
    }
    ```
    `CGEventFlags` is imported as a struct of `RawRepresentable` with `UInt64` raw value — it is `Sendable` by value. `CGEventType` is also `Sendable` (C enum).
  - Define a final class wrapper for the continuation pointer:
    ```
    final class JsonContinuationBox: @unchecked Sendable {
        let continuation: AsyncStream<BridgedKeyEvent>.Continuation
        init(_ continuation: AsyncStream<BridgedKeyEvent>.Continuation) {
            self.continuation = continuation
        }
    }
    ```
    **This is the ONLY `@unchecked Sendable` in the entire application.** It is justified because `AsyncStream.Continuation` is documented as thread-safe for `yield` calls, and the box is immutable (let-only). The `@unchecked` is needed solely because `AsyncStream.Continuation` does not have a formal `Sendable` conformance on the wrapping generic type in all Swift versions, though its `yield` is thread-safe.
  - Define the file-scope C callback function:
    ```
    private func cgEventCallback(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent,
        userInfo: UnsafeMutableRawPointer?
    ) -> Unmanaged<CGEvent>? { ... }
    ```
    - Inside: extract `BridgedKeyEvent` from the `event` (keyCode via `.getIntegerValueField(.keyboardEventKeycode)`, flags via `.flags`).
    - Handle `.tapDisabledByTimeout` / `.tapDisabledByUserInput`: re-enable the tap via `CGEvent.tapEnable(tap:enable:)`.
    - Retrieve `ContinuationBox` from `userInfo` via `Unmanaged<ContinuationBox>.fromOpaque(userInfo!).takeUnretainedValue()`.
    - Call `box.continuation.yield(bridgedEvent)`.
    - Return `Unmanaged.passRetained(event)` (required by signature even for `.listenOnly`).
  - Define the public factory:
    ```
    @MainActor
    func createKeyEventStream() -> (stream: AsyncStream<BridgedKeyEvent>, cancel: @Sendable () -> Void)?
    ```
    - Uses `AsyncStream.makeStream(of: BridgedKeyEvent.self, bufferingPolicy: .bufferingNewest(64))`.
    - Creates `ContinuationBox`, retains it via `Unmanaged.passRetained(box).toOpaque()` for `userInfo`.
    - Calls `CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: mask, callback: cgEventCallback, userInfo: pointer)` where `mask = CGEventMask(1 << CGEventType.keyDown.rawValue)`.
    - If tap creation returns `nil` (permission not granted), call `continuation.finish()` and return `nil`.
    - Creates `CFRunLoopSource`, adds to `CFRunLoopGetMain()`, enables the tap.
    - The `cancel` closure: disables the tap, removes the run loop source, releases the `Unmanaged` box, calls `continuation.finish()`.
    - Sets `continuation.onTermination = { _ in /* cleanup */ }`.
    - Returns `(stream, cancel)`.
  - **Why `CFRunLoopGetMain()`:** The event tap callback will fire on the run loop it's added to. By adding to the main run loop, we minimize thread-hop latency. Since the callback body is trivial (extract values + yield to lock-free continuation), it won't block the main run loop.
- **Dependencies:** Step 1.1
- **Verification:** `swift build` — 0 errors, 0 warnings under Swift 6 strict concurrency.
- **Complexity:** High
- **Risk:** High — This is the most concurrency-sensitive code in the app. The `Unmanaged` retain/release cycle must be balanced. The agent must ensure `passRetained` is matched by exactly one `release` in the `cancel` closure. If `onTermination` fires before `cancel` is called, double-release must be prevented (use a `Bool` flag in the box, or rely on `onTermination` as the sole cleanup path).

### Step 2.2: Create `NSEventBridge.swift` — NSEvent Monitor → AsyncStream Bridge
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Bridge/NSEventBridge.swift`
- **Action:** Create AsyncStream bridges for `NSEvent.addGlobalMonitorForEvents` and `NSEvent.addLocalMonitorForEvents`.
- **Details:**
  - Define a value type:
    ```
    struct BridgedMouseEvent: Sendable {
        let locationInScreen: CGPoint  // screen coordinates, bottom-left origin
        let type: NSEvent.EventType    // Sendable (RawRepresentable)
    }
    ```
  - Factory function:
    ```
    @MainActor
    func createMouseEventStream(matching mask: NSEvent.EventTypeMask) -> (stream: AsyncStream<BridgedMouseEvent>, cancel: @Sendable () -> Void)
    ```
    - Uses `AsyncStream.makeStream(of: BridgedMouseEvent.self, bufferingPolicy: .bufferingNewest(128))`.
    - Installs a global monitor: `NSEvent.addGlobalMonitorForEvents(matching: mask) { event in continuation.yield(BridgedMouseEvent(locationInScreen: NSEvent.mouseLocation, type: event.type)) }`.
    - Installs a local monitor: `NSEvent.addLocalMonitorForEvents(matching: mask) { event in continuation.yield(...); return event }`.
    - `cancel` closure removes both monitors via `NSEvent.removeMonitor`, then calls `continuation.finish()`.
    - Returns `(stream, cancel)`.
  - **Note on `@Sendable` closure:** The `NSEvent.addGlobalMonitorForEvents` handler is `@Sendable` in the macOS 26 SDK. The continuation's `yield` is thread-safe, so calling it from the handler is safe. The `BridgedMouseEvent` is `Sendable` by construction. No isolation violations.
- **Dependencies:** Step 1.1
- **Verification:** `swift build` — 0 errors, 0 warnings.
- **Complexity:** Medium
- **Risk:** Low — `NSEvent.mouseLocation` is a class property that is safe to read from any thread.

### Step 2.3: Create `OverlayPanel.swift` — Shared NSPanel Subclass
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Overlay/OverlayPanel.swift`
- **Action:** Create the reusable transparent, click-through overlay panel.
- **Details:**
  - Class: `@MainActor final class OverlayPanel: NSPanel`
  - `init(overlayLevel: NSWindow.Level = .screenSaver)`:
    - Call `super.init(contentRect: NSScreen.main?.frame ?? .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)`.
    - Set: `self.level = overlayLevel`, `.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `.backgroundColor = .clear`, `.isOpaque = false`, `.hasShadow = false`, `.ignoresMouseEvents = true`, `.isMovableByWindowBackground = false`, `.hidesOnDeactivate = false`.
  - Override `var canBecomeKey: Bool { false }`
  - Override `var canBecomeMain: Bool { false }`
  - `func showFullScreen()`: `setFrame(NSScreen.main?.frame ?? .zero, display: true)`; `orderFrontRegardless()`.
  - `func hideOverlay()`: `orderOut(nil)`.
- **Dependencies:** Step 1.6
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Low
- **Risk:** Low

### Step 2.4: Create `CodableColor.swift` — Color Serialization
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Utilities/CodableColor.swift`
- **Action:** Create a `Sendable`, `Codable` color type compatible with `Defaults`.
- **Details:**
  - `struct CodableColor: Codable, Sendable, Equatable, Defaults.Serializable`
  - Properties: `let red: Double`, `green: Double`, `blue: Double`, `alpha: Double`
  - `init(nsColor: NSColor)`: convert via `nsColor.usingColorSpace(.sRGB)!`, extract components.
  - Computed `var nsColor: NSColor`: `NSColor(sRGBRed: CGFloat(red), green: ..., blue: ..., alpha: ...)`.
  - Computed `var color: Color`: `Color(nsColor: self.nsColor)`.
  - `static func fromHex(_ hex: String) -> CodableColor`: parse `"#RRGGBB"` format.
  - Static defaults: `.blue = .fromHex("#007AFF")`, `.red = .fromHex("#FF3B30")`, `.spotlightDefault = CodableColor(red: 1, green: 1, blue: 1, alpha: 0.5)`.
- **Dependencies:** Step 1.1
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Low
- **Risk:** Low

### Step 2.5: Create `KeySymbols.swift` — Keycode Mapping
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Utilities/KeySymbols.swift`
- **Action:** Create keycode-to-display-string utility.
- **Details:**
  - `enum KeySymbol` (caseless, namespace only).
  - `static func modifierSymbols(from flags: CGEventFlags) -> String`:
    - Build string in macOS standard order: `⌃` (`.maskControl`), `⌥` (`.maskAlternate`), `⇧` (`.maskShift`), `⌘` (`.maskCommand`).
    - Also: Caps Lock → `⇪`, Function → `fn`.
    - Return concatenated string, e.g. `"⌘⇧"`.
  - `static func keyName(from keyCode: Int64) -> String`:
    - Static `[Int64: String]` dictionary mapping common macOS keycodes:
      - 36→`"↩"`, 48→`"⇥"`, 49→`"␣"`, 51→`"⌫"`, 53→`"⎋"`, 76→`"⌅"`,
      - 123→`"←"`, 124→`"→"`, 125→`"↓"`, 126→`"↑"`,
      - 122→`"F1"` through 111→`"F12"` (standard F-key keycodes),
      - 0→`"A"`, 1→`"S"`, 2→`"D"`, ... (full US QWERTY layout, keycodes 0–50 for letter/number/symbol keys).
    - Fallback: return `"?"` for unknown keycodes.
  - `static func displayString(keyCode: Int64, modifiers: CGEventFlags) -> String`:
    - `let mods = modifierSymbols(from: modifiers)`
    - `let key = keyName(from: keyCode)`
    - Return `mods + key`, e.g. `"⌘⇧A"`.
    - If only modifier flags changed (no printable key), return just the modifier string.
- **Dependencies:** Step 1.1
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Medium
- **Risk:** Medium — Keycode mapping is US-layout-specific. Document this limitation in a comment. For v1.0, this is acceptable.

### Step 2.6: Create `SettingsManager.swift` — Defaults Keys and Shortcut Names
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Settings/SettingsManager.swift`
- **Action:** Define all persistent settings and hotkey names.
- **Details:**
  - ```
    import Defaults
    import KeyboardShortcuts

    extension Defaults.Keys {
        // Spotlight
        static let spotlightEnabled = Key<Bool>("spotlightEnabled", default: false)
        static let spotlightRadius = Key<Double>("spotlightRadius", default: 150.0)
        static let spotlightBlur = Key<Double>("spotlightBlur", default: 30.0)
        static let spotlightOpacity = Key<Double>("spotlightOpacity", default: 0.5)
        static let spotlightColor = Key<CodableColor>("spotlightColor", default: .spotlightDefault)
        // Click
        static let clickEnabled = Key<Bool>("clickEnabled", default: true)
        static let leftClickColor = Key<CodableColor>("leftClickColor", default: .blue)
        static let rightClickColor = Key<CodableColor>("rightClickColor", default: .red)
        static let clickRingMaxRadius = Key<Double>("clickRingMaxRadius", default: 30.0)
        // KeyStroke
        static let keyStrokeEnabled = Key<Bool>("keyStrokeEnabled", default: true)
        static let keyStrokeFontSize = Key<Double>("keyStrokeFontSize", default: 48.0)
        // Others
        static let appLanguage = Key<String>("appLanguage", default: "en")
    }

    extension KeyboardShortcuts.Name {
        static let toggleSpotlight = Self("toggleSpotlight", default: .init(.one, modifiers: [.shift]))
        static let toggleClicks = Self("toggleClicks")
        static let toggleKeyStrokes = Self("toggleKeyStrokes")
    }
    ```
- **Dependencies:** Steps 1.1, 2.4
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Low
- **Risk:** Low

### Step 2.7: Create `PermissionManager.swift`
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/App/PermissionManager.swift`
- **Action:** Create the permission checker using structured concurrency.
- **Details:**
  - `@MainActor @Observable final class PermissionManager`
  - Property: `var isAccessibilityGranted: Bool = false`
  - Property: `private var pollTask: Task<Void, Never>?`
  - Method `func checkAndRequestAccessibility()`:
    - `import ApplicationServices`
    - Call `AXIsProcessTrusted()` → set `isAccessibilityGranted`.
    - If not trusted: call `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)` to show system prompt.
    - Start polling: `pollTask = Task { [weak self] in while !Task.isCancelled { try? await Task.sleep(for: .seconds(2)); if AXIsProcessTrusted() { await MainActor.run { self?.isAccessibilityGranted = true }; break } } }`.
  - Method `func stopPolling()`: `pollTask?.cancel()`.
  - **Note:** `Task.sleep(for:)` is used instead of `Timer` — idiomatic structured concurrency. The `Task` is cancelled in `stopPolling` or when permission is granted.
- **Dependencies:** Step 1.6
- **Verification:** `swift build` — 0 errors, 0 concurrency warnings.
- **Complexity:** Low
- **Risk:** Low

### Step 2.8: Create `L10n.swift` — Localization Helper
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Utilities/L10n.swift`
- **Action:** Create localization utility function.
- **Details:**
  - `func L(_ key: String) -> String { NSLocalizedString(key, bundle: .module, comment: "") }`
  - This relies on SPM's auto-generated `Bundle.module` which includes the `.lproj` resource directories.
  - All UI code must call `L("key")` for every user-facing string.
- **Dependencies:** Step 1.1
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Low
- **Risk:** Low

### Step 2.9: Create Localization Resource Files
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Resources/en.lproj/Localizable.strings`, `Sources/CursorHighlighting/Resources/ja.lproj/Localizable.strings`
- **Action:** Create both localization files with all user-facing strings.
- **Details:**
  - **English (`en.lproj/Localizable.strings`):**
    ```
    "menu.spotlight" = "Mouse Spotlight";
    "menu.clicks" = "Mouse Clicks";
    "menu.keystrokes" = "Key Strokes";
    "menu.settings" = "Settings…";
    "menu.quit" = "Quit";
    "settings.spotlight.title" = "Mouse Spotlight";
    "settings.spotlight.hotkey" = "Hotkey";
    "settings.spotlight.radius" = "Circle Radius";
    "settings.spotlight.blur" = "Circle Blur";
    "settings.spotlight.opacity" = "Overlay Opacity";
    "settings.spotlight.color" = "Spotlight Color";
    "settings.clicks.title" = "Mouse Clicks";
    "settings.clicks.leftColor" = "Left Click Color";
    "settings.clicks.rightColor" = "Right Click Color";
    "settings.clicks.ringSize" = "Ring Size";
    "settings.keystrokes.title" = "Key Strokes";
    "settings.keystrokes.enabled" = "Show Key Strokes";
    "settings.keystrokes.fontSize" = "Font Size";
    "settings.keystrokes.hotkey" = "Hotkey";
    "settings.others.title" = "Others";
    "settings.others.launchAtLogin" = "Launch at Login";
    "settings.others.language" = "Language";
    "settings.others.language.en" = "English";
    "settings.others.language.ja" = "Japanese";
    "settings.others.restartRequired" = "Please restart the app for the language change to take effect.";
    "permission.title" = "Accessibility Permission Required";
    "permission.message" = "Cursor Highlighting needs Accessibility permission to monitor mouse and keyboard events. Please grant access in System Settings.";
    "permission.openSettings" = "Open System Settings";
    ```
  - **Japanese (`ja.lproj/Localizable.strings`):**
    ```
    "menu.spotlight" = "マウス スポットライト";
    "menu.clicks" = "マウス クリック";
    "menu.keystrokes" = "キーストローク";
    "menu.settings" = "設定…";
    "menu.quit" = "終了";
    "settings.spotlight.title" = "マウス スポットライト";
    "settings.spotlight.hotkey" = "ホットキー";
    "settings.spotlight.radius" = "円の半径";
    "settings.spotlight.blur" = "ぼかし";
    "settings.spotlight.opacity" = "暗部の透明度";
    "settings.spotlight.color" = "スポットライトの色";
    "settings.clicks.title" = "マウス クリック";
    "settings.clicks.leftColor" = "左クリックの色";
    "settings.clicks.rightColor" = "右クリックの色";
    "settings.clicks.ringSize" = "リングのサイズ";
    "settings.keystrokes.title" = "キーストローク";
    "settings.keystrokes.enabled" = "キーストロークを表示";
    "settings.keystrokes.fontSize" = "フォントサイズ";
    "settings.keystrokes.hotkey" = "ホットキー";
    "settings.others.title" = "その他";
    "settings.others.launchAtLogin" = "ログイン時に起動";
    "settings.others.language" = "言語";
    "settings.others.language.en" = "英語";
    "settings.others.language.ja" = "日本語";
    "settings.others.restartRequired" = "言語の変更を反映するにはアプリを再起動してください。";
    "permission.title" = "アクセシビリティの許可が必要です";
    "permission.message" = "マウスとキーボードのイベントを監視するために、アクセシビリティの許可が必要です。システム設定で許可してください。";
    "permission.openSettings" = "システム設定を開く";
    ```
- **Dependencies:** Step 1.2
- **Verification:** `swift build` — 0 errors. Resource bundle generated.
- **Complexity:** Low
- **Risk:** Low

### Step 2.10: Create Settings Tab Views
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Settings/SpotlightSettingsView.swift`, `ClickSettingsView.swift`, `KeyStrokeSettingsView.swift`, `OtherSettingsView.swift`
- **Action:** Create the 4 settings tab views as SwiftUI views.
- **Details:**
  - All views use `Settings.Container(contentWidth: 450.0)` and `Settings.Section(title:)` from sindresorhus/Settings for layout.
  - **SpotlightSettingsView:**
    - `KeyboardShortcuts.Recorder(L("settings.spotlight.hotkey"), name: .toggleSpotlight)`
    - `Slider` for radius: `@Default(.spotlightRadius) var radius`, range `50...400`, step `10`. Label: `L("settings.spotlight.radius")`.
    - `Slider` for blur: `@Default(.spotlightBlur) var blur`, range `0...100`, step `5`. Label: `L("settings.spotlight.blur")`.
    - `Slider` for opacity: `@Default(.spotlightOpacity) var opacity`, range `0.1...1.0`, step `0.05`. Label: `L("settings.spotlight.opacity")`.
    - `ColorPicker(L("settings.spotlight.color"), selection: ...)` — use a `@State var color: Color` synced bidirectionally with `Defaults[.spotlightColor]` via `.onAppear` and `.onChange`.
  - **ClickSettingsView:**
    - `KeyboardShortcuts.Recorder(L("settings.keystrokes.hotkey"), name: .toggleClicks)` (reuse hotkey label or create a clicks-specific one; the plan uses the generic "Hotkey" label).
    - `ColorPicker(L("settings.clicks.leftColor"), ...)` bound to `Defaults[.leftClickColor]`.
    - `ColorPicker(L("settings.clicks.rightColor"), ...)` bound to `Defaults[.rightClickColor]`.
    - `Slider` for `@Default(.clickRingMaxRadius)`, range `15...80`, step `5`. Label: `L("settings.clicks.ringSize")`.
  - **KeyStrokeSettingsView:**
    - `KeyboardShortcuts.Recorder(L("settings.keystrokes.hotkey"), name: .toggleKeyStrokes)`
    - `Toggle(L("settings.keystrokes.enabled"), isOn: $keyStrokeEnabled)` where `@Default(.keyStrokeEnabled) var keyStrokeEnabled`.
    - `Slider` for `@Default(.keyStrokeFontSize)`, range `24...96`, step `4`. Label: `L("settings.keystrokes.fontSize")`.
  - **OtherSettingsView:**
    - `LaunchAtLogin.Toggle(L("settings.others.launchAtLogin"))`
    - `Picker(L("settings.others.language"), selection: $appLanguage)` where `@Default(.appLanguage) var appLanguage`. Options: `Text(L("settings.others.language.en")).tag("en")`, `Text(L("settings.others.language.ja")).tag("ja")`.
    - `.onChange(of: appLanguage)`: set `UserDefaults.standard.set([appLanguage], forKey: "AppleLanguages")` and show an alert with `L("settings.others.restartRequired")`.
- **Dependencies:** Steps 2.4, 2.6, 2.8, 2.9
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Medium
- **Risk:** Low

### Step 2.11: Create `AppState.swift` and Wire Settings Window
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/App/AppState.swift`, update `CursorHighlightingApp.swift`
- **Action:** Create the central app state and wire up the settings window and menu bar.
- **Details:**
  - **AppState.swift:**
    - `@MainActor @Observable final class AppState`
    - Properties:
      - `let permissionManager = PermissionManager()`
      - `var settingsWindowController: SettingsWindowController?` (lazy, see below)
    - Method `func showSettings()`:
      - Lazily create `SettingsWindowController` with 4 panes:
        - `Settings.Pane(identifier: .init("spotlight"), title: L("settings.spotlight.title"), toolbarIcon: NSImage(systemSymbolName: "light.max", accessibilityDescription: nil)!) { SpotlightSettingsView() }`
        - `Settings.Pane(identifier: .init("clicks"), title: L("settings.clicks.title"), toolbarIcon: NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: nil)!) { ClickSettingsView() }`
        - `Settings.Pane(identifier: .init("keystrokes"), title: L("settings.keystrokes.title"), toolbarIcon: NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)!) { KeyStrokeSettingsView() }`
        - `Settings.Pane(identifier: .init("others"), title: L("settings.others.title"), toolbarIcon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)!) { OtherSettingsView() }`
      - Call `settingsWindowController?.show()` and `NSApp.activate(ignoringOtherApps: true)`.
    - In `init()`: call `permissionManager.checkAndRequestAccessibility()`.
  - **CursorHighlightingApp.swift (rewrite):**
    - `@main struct CursorHighlightingApp: App`
    - `@State private var appState = AppState()`
    - `@Default(.spotlightEnabled) private var spotlightEnabled`
    - `@Default(.clickEnabled) private var clickEnabled`
    - `@Default(.keyStrokeEnabled) private var keyStrokeEnabled`
    - `body`: `MenuBarExtra(L("menu.spotlight"), systemImage: "cursorarrow.rays")` containing:
      - `Toggle(L("menu.spotlight"), isOn: $spotlightEnabled)`
      - `Toggle(L("menu.clicks"), isOn: $clickEnabled)`
      - `Toggle(L("menu.keystrokes"), isOn: $keyStrokeEnabled)`
      - `Divider()`
      - `Button(L("menu.settings")) { appState.showSettings() }`
      - `Divider()`
      - `Button(L("menu.quit")) { NSApplication.shared.terminate(nil) }`
- **Dependencies:** Steps 2.7, 2.8, 2.9, 2.10
- **Verification:** `swift build` — 0 errors. `make run` — menu bar dropdown shows toggles and Settings. Settings window opens with 4 functional tabs.
- **Complexity:** Medium
- **Risk:** Medium — `Settings.Pane` API must match sindresorhus/Settings version. Agent should verify the exact API surface.

### Step 2.G: Phase Gate — Core Infrastructure Verification
- **Agent:** review-agent
- **Action:** Verify Phase 2 is complete.
- **Verification:**
  1. `swift build` — 0 errors, 0 concurrency warnings.
  2. `make run` — menu bar icon visible; dropdown has toggles + Settings + Quit.
  3. "Settings…" opens tabbed window with 4 tabs. Each tab renders controls.
  4. Change a setting (e.g., spotlight radius), quit, relaunch — setting persists.
  5. On first launch without Accessibility, system prompt appears.
  6. No `@unchecked Sendable` used anywhere except `ContinuationBox` in `CGEventBridge.swift`.
- **Dependencies:** Steps 2.1–2.11

---

## Phase 3: Mouse Spotlight Feature
**Purpose:** Implement the fullscreen spotlight overlay. After this phase, Shift+1 toggles a dimming overlay with a cursor-following bright circle.

### Step 3.1: Create `SpotlightOverlayView.swift` — Core Graphics Drawing
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/Spotlight/SpotlightOverlayView.swift`
- **Action:** Create `NSView` subclass that draws the spotlight effect.
- **Details:**
  - `@MainActor final class SpotlightOverlayView: NSView`
  - Properties (all MainActor-isolated, set from the consuming Task):
    - `var cursorPosition: NSPoint = .zero { didSet { needsDisplay = true } }`
    - `var spotlightRadius: CGFloat = 150`
    - `var blurRadius: CGFloat = 30`
    - `var overlayOpacity: CGFloat = 0.5`
    - `var spotlightColor: NSColor = .white`
  - Override `var isFlipped: Bool { true }`
  - Override `hitTest(_ point: NSPoint) -> NSView? { nil }`
  - Override `draw(_ dirtyRect: NSRect)`:
    - **Algorithm (even-odd fill rule — most reliable):**
      1. Get current `NSGraphicsContext.current!.cgContext`.
      2. Create a `CGMutablePath`.
      3. Add the full view rect as the outer boundary: `path.addRect(bounds)`.
      4. Add an ellipse centered on `cursorPosition` with x-radius and y-radius = `spotlightRadius`: `path.addEllipse(in: CGRect(x: cursorPosition.x - spotlightRadius, y: cursorPosition.y - spotlightRadius, width: spotlightRadius * 2, height: spotlightRadius * 2))`.
      5. Set fill color: `NSColor.black.withAlphaComponent(overlayOpacity).setFill()`.
      6. `context.addPath(path)` and `context.fillPath(using: .evenOdd)` — this fills the rect minus the ellipse, creating the spotlight cutout.
      7. For blur effect at the edge: apply a `CIFilter.gaussianBlur` to the layer, or more practically, draw a radial gradient ring around the ellipse boundary. **Simpler approach:** set `self.layer?.filters = [CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: blurRadius])!]` in a setup method, or draw multiple concentric ellipses with decreasing opacity to simulate a soft edge. The recommended approach is to use the even-odd path for the hard cutout and then apply `layer?.compositingFilter` or use `NSView.shadow` for the soft edge. The agent should implement the even-odd cutout first, then test if the `blurRadius` can be achieved via `CALayer.shadowRadius` on an inverted mask.
    - If `spotlightColor` is not white: after drawing the dimmed overlay, draw a radial gradient from `spotlightColor.withAlphaComponent(0.15)` at center to `.clear` at `spotlightRadius`, to add a subtle color tint.
- **Dependencies:** Step 2.3
- **Verification:** `swift build` — 0 errors.
- **Complexity:** High
- **Risk:** High — Visual quality depends on the blur technique. The agent should try even-odd + `CIGaussianBlur` on the layer first. If `CIFilter` on layer is too expensive at 120Hz, fall back to drawing a gradient ring manually. Document the chosen approach in a code comment.

### Step 3.2: Create `SpotlightOverlayWindow.swift`
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/Spotlight/SpotlightOverlayWindow.swift`
- **Action:** Create the window controller that manages the overlay panel and consumes the mouse event stream.
- **Details:**
  - `@MainActor final class SpotlightOverlayWindow`
  - Properties:
    - `private var panel: OverlayPanel?`
    - `private var overlayView: SpotlightOverlayView?`
    - `private var mouseStreamCancel: (@Sendable () -> Void)?`
    - `private var trackingTask: Task<Void, Never>?`
  - Method `func show()`:
    1. Create `OverlayPanel(overlayLevel: .init(rawValue: NSWindow.Level.screenSaver.rawValue - 1))` — spotlight is the lowest overlay.
    2. Create `SpotlightOverlayView(frame: panel.frame)`.
    3. Apply current settings from `Defaults`: `overlayView.spotlightRadius = Defaults[.spotlightRadius]`, etc.
    4. Set as `panel.contentView!.addSubview(overlayView)` or set as `panel.contentView`.
    5. `panel.showFullScreen()`.
    6. Create mouse stream: `let (stream, cancel) = createMouseEventStream(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged])`.
    7. Store `cancel`.
    8. Immediately update position: convert `NSEvent.mouseLocation` to view coords.
    9. Start consuming: `trackingTask = Task { for await event in stream { let screenFrame = self.panel?.frame ?? .zero; self.overlayView?.cursorPosition = NSPoint(x: event.locationInScreen.x - screenFrame.origin.x, y: screenFrame.height - (event.locationInScreen.y - screenFrame.origin.y)); } }`.
  - Method `func hide()`:
    - `trackingTask?.cancel()`. `mouseStreamCancel?()`. `panel?.hideOverlay()`. `panel = nil; overlayView = nil`.
  - Method `func updateSettings()`:
    - Read Defaults and update `overlayView` properties. Call `overlayView?.needsDisplay = true`.
- **Dependencies:** Steps 2.2, 2.3, 3.1
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Medium
- **Risk:** Medium — Coordinate conversion. `NSEvent.mouseLocation` is in global screen coordinates (bottom-left origin). The panel frame origin may not be at (0,0) if the screen doesn't start at origin. Formula: `viewX = mouseLocation.x - panel.frame.origin.x`, `viewY = panel.frame.height - (mouseLocation.y - panel.frame.origin.y)` (because the view is flipped).

### Step 3.3: Create `SpotlightManager.swift`
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/Spotlight/SpotlightManager.swift`
- **Action:** Create the feature orchestrator.
- **Details:**
  - `@MainActor @Observable final class SpotlightManager`
  - Properties:
    - `private let overlayWindow = SpotlightOverlayWindow()`
    - `private(set) var isActive = false`
    - `private var observationTask: Task<Void, Never>?`
  - In `init()`:
    - Register hotkey: `KeyboardShortcuts.onKeyUp(for: .toggleSpotlight) { [weak self] in self?.toggle() }`
    - Start observing settings: create a `Task` that uses `Defaults.updates(.spotlightEnabled)` (or manual observation) to react to enable/disable changes. When enabled: `activate()`. When disabled: `deactivate()`.
    - Also observe `spotlightRadius`, `spotlightBlur`, `spotlightOpacity`, `spotlightColor` changes and call `overlayWindow.updateSettings()`.
  - `func toggle()`: `Defaults[.spotlightEnabled].toggle()`
  - `private func activate()`: `isActive = true; overlayWindow.show()`
  - `private func deactivate()`: `isActive = false; overlayWindow.hide()`
- **Dependencies:** Steps 2.6, 3.2
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Medium
- **Risk:** Low

### Step 3.4: Integrate SpotlightManager into AppState
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/App/AppState.swift` (update)
- **Action:** Add `let spotlightManager = SpotlightManager()` to `AppState`.
- **Dependencies:** Steps 2.11, 3.3
- **Verification:** `make run` — Shift+1 toggles spotlight overlay. Circle follows cursor.
- **Complexity:** Low
- **Risk:** Low

### Step 3.G: Phase Gate — Mouse Spotlight Verification
- **Agent:** review-agent
- **Action:** Verify spotlight feature.
- **Verification:**
  1. `swift build` — 0 errors, 0 concurrency warnings.
  2. `make run` — press Shift+1: screen dims, bright circle at cursor.
  3. Move mouse: circle follows smoothly.
  4. Shift+1 again: overlay disappears.
  5. Menu bar toggle works identically.
  6. Settings > radius slider: effect updates while active.
- **Dependencies:** Steps 3.1–3.4

---

## Phase 4: Mouse Click Visualizer Feature
**Purpose:** Implement click ring animations. After this phase, clicks produce expanding, fading rings.

### Step 4.1: Create `ClickRingView.swift`
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/ClickVisualizer/ClickRingView.swift`
- **Action:** Create the animated ring view using Core Animation.
- **Details:**
  - `@MainActor final class ClickRingView: NSView`
  - Init: `init(center: NSPoint, color: NSColor, maxRadius: CGFloat)`
    - Frame: square of `(maxRadius * 2 + 10)²`, centered on `center`.
    - `wantsLayer = true`.
    - Add a `CAShapeLayer` sublayer: initial circle path radius 5px, stroke color `color.cgColor`, fill `nil`, line width 3.
  - Method `func animate()`:
    - `CAAnimationGroup` duration `0.4s`:
      - `CABasicAnimation(keyPath: "path")`: 5px circle → `maxRadius` circle.
      - `CABasicAnimation(keyPath: "opacity")`: 1.0 → 0.0.
      - `CABasicAnimation(keyPath: "lineWidth")`: 3.0 → 1.0.
    - `isRemovedOnCompletion = false`, `fillMode = .forwards`.
    - After 0.5s: `Task { try? await Task.sleep(for: .milliseconds(500)); self.removeFromSuperview() }`.
  - Override `hitTest` → `nil`.
- **Dependencies:** Step 2.3
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Medium
- **Risk:** Low

### Step 4.2: Create `ClickOverlayWindow.swift`
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/ClickVisualizer/ClickOverlayWindow.swift`
- **Action:** Create overlay window for hosting click rings.
- **Details:**
  - `@MainActor final class ClickOverlayWindow`
  - Properties: `private var panel: OverlayPanel?`
  - `func show()`: create `OverlayPanel(overlayLevel: .screenSaver)`, set `NSView()` as contentView, `showFullScreen()`.
  - `func hide()`: `panel?.hideOverlay(); panel = nil`.
  - `func showClickRing(at screenPoint: NSPoint, color: NSColor, maxRadius: CGFloat)`:
    - Convert screen coords to panel-content coords: `let x = screenPoint.x - (panel?.frame.origin.x ?? 0)`, `let y = screenPoint.y - (panel?.frame.origin.y ?? 0)`.
    - Create `ClickRingView(center: NSPoint(x: x, y: y), color: color, maxRadius: maxRadius)`.
    - Add as subview of `panel?.contentView`. Call `animate()`.
- **Dependencies:** Steps 2.3, 4.1
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Low
- **Risk:** Low

### Step 4.3: Create `ClickManager.swift`
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/ClickVisualizer/ClickManager.swift`
- **Action:** Create mouse click monitor using AsyncStream bridge.
- **Details:**
  - `@MainActor @Observable final class ClickManager`
  - Properties:
    - `private let overlayWindow = ClickOverlayWindow()`
    - `private var clickStreamCancel: (@Sendable () -> Void)?`
    - `private var consumeTask: Task<Void, Never>?`
    - `private(set) var isActive = false`
  - `func activate()`:
    - `overlayWindow.show(); isActive = true`.
    - `let (stream, cancel) = createMouseEventStream(matching: [.leftMouseDown, .rightMouseDown])`.
    - `clickStreamCancel = cancel`.
    - `consumeTask = Task { for await event in stream { switch event.type { case .leftMouseDown: overlayWindow.showClickRing(at: event.locationInScreen, color: Defaults[.leftClickColor].nsColor, maxRadius: Defaults[.clickRingMaxRadius]); case .rightMouseDown: overlayWindow.showClickRing(at: event.locationInScreen, color: Defaults[.rightClickColor].nsColor, maxRadius: Defaults[.clickRingMaxRadius]); default: break } } }`.
  - `func deactivate()`: cancel task, cancel stream, hide overlay, `isActive = false`.
  - In `init()`: observe `Defaults[.clickEnabled]`. When true → `activate()`. When false → `deactivate()`. Register hotkey: `KeyboardShortcuts.onKeyUp(for: .toggleClicks) { [weak self] in Defaults[.clickEnabled].toggle() }`.
- **Dependencies:** Steps 2.2, 2.6, 4.2
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Medium
- **Risk:** Low

### Step 4.4: Integrate ClickManager into AppState
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/App/AppState.swift` (update)
- **Action:** Add `let clickManager = ClickManager()`.
- **Dependencies:** Steps 2.11, 4.3
- **Verification:** `make run` — left click → blue ring, right click → red ring.
- **Complexity:** Low
- **Risk:** Low

### Step 4.G: Phase Gate — Click Visualizer Verification
- **Agent:** review-agent
- **Action:** Verify click feature.
- **Verification:**
  1. `swift build` — 0 errors.
  2. Enable "Mouse Clicks". Left click → blue ring. Right click → red ring. Ring expands and fades in ~0.4s.
  3. Disable → no more rings.
  4. Change colors in Settings → new colors take effect on next click.
- **Dependencies:** Steps 4.1–4.4

---

## Phase 5: Key Stroke Display Feature
**Purpose:** Implement keyboard HUD using the CGEvent AsyncStream bridge. After this phase, pressed keys appear at the bottom of the screen.

### Step 5.1: Create `KeyStrokeHUDView.swift`
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/KeyStroke/KeyStrokeHUDView.swift`
- **Action:** Create the SwiftUI HUD view.
- **Details:**
  - Define: `struct KeyStrokeEntry: Identifiable, Sendable { let id = UUID(); let text: String; let timestamp: Date }`
  - `struct KeyStrokeHUDView: View`
  - Input: `var entries: [KeyStrokeEntry]`, `var fontSize: Double`
  - Body:
    - `HStack(spacing: 8)` showing entries (max 8).
    - Each entry: `Text(entry.text)` with `.font(.system(size: fontSize, weight: .medium, design: .rounded))`, `.foregroundStyle(.white)`, `.padding(.horizontal, 12)`, `.padding(.vertical, 8)`, `.background(RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.7)))`.
    - Outer container: `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)`, `.padding(.bottom, 60)`.
    - `.animation(.easeInOut(duration: 0.2), value: entries.count)`.
- **Dependencies:** None
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Low
- **Risk:** Low

### Step 5.2: Create `KeyStrokeOverlayWindow.swift`
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/KeyStroke/KeyStrokeOverlayWindow.swift`
- **Action:** Create overlay hosting the HUD.
- **Details:**
  - `@MainActor @Observable final class KeyStrokeOverlayWindow`
  - Properties:
    - `private var panel: OverlayPanel?`
    - `var entries: [KeyStrokeEntry] = []`
    - `private var cleanupTask: Task<Void, Never>?`
  - `func show()`:
    - Create `OverlayPanel(overlayLevel: .init(rawValue: NSWindow.Level.screenSaver.rawValue + 1))` — keystroke is the topmost overlay.
    - Create `NSHostingView(rootView: KeyStrokeHUDView(entries: entries, fontSize: Defaults[.keyStrokeFontSize]))`. However, since the view needs to reactively update, the agent should use a wrapper `@Observable` class or make the hosting view observe this window's `entries` property. The recommended approach: create an inner `@Observable class HUDState { var entries: [KeyStrokeEntry] = []; var fontSize: Double = 48 }`, pass it to the view via environment or direct binding, and update it from this window.
    - Set as panel's contentView.
    - `panel.showFullScreen()`.
    - Start cleanup: `cleanupTask = Task { while !Task.isCancelled { try? await Task.sleep(for: .milliseconds(500)); entries.removeAll { Date().timeIntervalSince($0.timestamp) > 2.0 } } }`.
  - `func hide()`: `cleanupTask?.cancel(); panel?.hideOverlay(); panel = nil; entries = []`.
  - `func addEntry(_ text: String)`: `entries.append(KeyStrokeEntry(text: text, timestamp: Date())); if entries.count > 10 { entries.removeFirst() }`.
- **Dependencies:** Steps 2.3, 5.1
- **Verification:** `swift build` — 0 errors.
- **Complexity:** Medium
- **Risk:** Medium — Reactive updates from `@Observable` to `NSHostingView` require the hosting view to re-read the observable. The agent should test that entry additions actually update the displayed view.

### Step 5.3: Create `KeyStrokeManager.swift` — CGEvent Stream Consumer
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/Features/KeyStroke/KeyStrokeManager.swift`
- **Action:** Create the manager that uses the `CGEventBridge` AsyncStream.
- **Details:**
  - `@MainActor @Observable final class KeyStrokeManager`
  - Properties:
    - `private let overlayWindow = KeyStrokeOverlayWindow()`
    - `private var eventStreamCancel: (@Sendable () -> Void)?`
    - `private var consumeTask: Task<Void, Never>?`
    - `private(set) var isActive = false`
  - `func activate()`:
    1. `overlayWindow.show(); isActive = true`.
    2. `guard let (stream, cancel) = createKeyEventStream() else { /* permission not granted */ return }`.
    3. `eventStreamCancel = cancel`.
    4. `consumeTask = Task { for await event in stream { let displayString = KeySymbol.displayString(keyCode: event.keyCode, modifiers: event.flags); self.overlayWindow.addEntry(displayString) } }`.
    - **This is the payoff of the AsyncStream bridge:** the `for await` loop runs on `@MainActor` (because this class is `@MainActor`-isolated). The compiler statically verifies that `overlayWindow.addEntry` is called on the main actor. No manual dispatch needed. No data race possible.
  - `func deactivate()`: `consumeTask?.cancel(); eventStreamCancel?(); overlayWindow.hide(); isActive = false`.
  - In `init()`: observe `Defaults[.keyStrokeEnabled]`. When true → `activate()`. When false → `deactivate()`. Register hotkey: `KeyboardShortcuts.onKeyUp(for: .toggleKeyStrokes) { [weak self] in Defaults[.keyStrokeEnabled].toggle() }`.
- **Dependencies:** Steps 2.1, 2.5, 2.6, 5.2
- **Verification:** `swift build` — 0 errors, **0 concurrency warnings**. The entire data path from C callback to UI update is compiler-verified safe.
- **Complexity:** High
- **Risk:** High — `createKeyEventStream()` returns `nil` if Accessibility permission is not granted (because `CGEvent.tapCreate` returns nil). The manager must handle this gracefully: check `PermissionManager.isAccessibilityGranted` before calling `activate()`, and retry when permission is granted.

### Step 5.4: Integrate KeyStrokeManager into AppState
- **Agent:** coding-agent
- **Location:** `Sources/CursorHighlighting/App/AppState.swift` (update)
- **Action:** Add `let keyStrokeManager = KeyStrokeManager()`.
- **Details:**
  - After `permissionManager.isAccessibilityGranted` becomes `true`, ensure `keyStrokeManager` can activate. Use observation: when `permissionManager.isAccessibilityGranted` changes to `true` and `Defaults[.keyStrokeEnabled]` is `true`, call `keyStrokeManager.activate()`.
- **Dependencies:** Steps 2.7, 2.11, 5.3
- **Verification:** `make run` — grant Accessibility → enable Key Strokes → type keys → keys appear in HUD.
- **Complexity:** Medium
- **Risk:** Medium — Permission timing.

### Step 5.G: Phase Gate — Key Stroke Verification
- **Agent:** review-agent
- **Action:** Verify key stroke feature.
- **Verification:**
  1. `swift build` — 0 errors, 0 concurrency warnings.
  2. Grant Accessibility. Enable "Key Strokes".
  3. Type `A` → `"A"` appears in HUD. Type `⌘C` → `"⌘C"` appears. Type `⇧⌘Z` → `"⇧⌘Z"`.
  4. Wait 3 seconds → entries disappear.
  5. Disable → HUD gone.
  6. **Critical:** Verify `swift build` still has 0 concurrency warnings — the C-to-MainActor path is compiler-verified.
- **Dependencies:** Steps 5.1–5.4

---

## Phase 6: Integration and Polish
**Purpose:** Ensure all three features work simultaneously, settings live-update, and overlay stacking is correct.

### Step 6.1: Verify Overlay Stacking
- **Agent:** review-agent
- **Location:** All overlay window files
- **Action:** Confirm the three overlays use distinct window levels.
- **Details:** Expected levels:
  - Spotlight: `screenSaver.rawValue - 1` (bottom)
  - Click rings: `screenSaver` (middle)
  - Key strokes: `screenSaver.rawValue + 1` (top)
- **Verification:** Enable all three features. Visual inspection: spotlight dims screen, click rings render on top of dim, keystrokes render on top of everything.
- **Dependencies:** Phases 3, 4, 5
- **Complexity:** Low
- **Risk:** Low

### Step 6.2: Settings Live-Update Wiring
- **Agent:** coding-agent
- **Location:** `SpotlightManager.swift`, `KeyStrokeOverlayWindow.swift` (updates)
- **Action:** Ensure all settings changes apply immediately while features are active.
- **Details:**
  - `SpotlightManager`: observe `Defaults` keys for radius, blur, opacity, color. On change, call `overlayWindow.updateSettings()`.
  - `KeyStrokeOverlayWindow`: observe `Defaults[.keyStrokeFontSize]` and update the HUD state's `fontSize`.
  - Click: already reads Defaults per-click, so inherently live.
- **Dependencies:** Steps 3.3, 5.2
- **Verification:** While spotlight active, change radius in Settings → immediate visual change.
- **Complexity:** Low
- **Risk:** Low

### Step 6.G: Phase Gate — Full Integration Verification
- **Agent:** review-agent
- **Action:** Full feature integration test.
- **Verification:**
  1. `swift build` — 0 errors, 0 concurrency warnings.
  2. Enable all three features simultaneously.
  3. Move mouse → spotlight follows. Click → ring appears above spotlight. Type → HUD above everything.
  4. Toggle each off independently → each overlay disappears without affecting others.
  5. Quit → relaunch → features restore to their saved enabled/disabled state.
  6. `swift build 2>&1 | grep -i "warning"` — output is empty or shows only dependency warnings (not our code).
- **Dependencies:** Steps 6.1–6.2

---

## Phase 7: Hotkey Integration Finalization
**Purpose:** Ensure all three features have customizable hotkeys with recorder UI in Settings.

### Step 7.1: Verify Hotkey Recorders in All Settings Tabs
- **Agent:** review-agent
- **Location:** Settings views
- **Action:** Confirm that `KeyboardShortcuts.Recorder` is present in Spotlight, Click, and KeyStroke settings tabs, and that the recorders correctly save/restore shortcuts.
- **Verification:**
  1. Open Settings > Mouse Spotlight: Recorder shows default `⇧1`. Clear it, record `⌥S`. Press `⌥S` → spotlight toggles.
  2. Open Settings > Mouse Clicks: Recorder shows no default. Record `⇧2`. Press `⇧2` → clicks toggle.
  3. Open Settings > Key Strokes: Recorder shows no default. Record `⇧3`. Press `⇧3` → keystrokes toggle.
  4. Quit and relaunch: all three hotkeys persist.
- **Dependencies:** Steps 2.10, 3.3, 4.3, 5.3
- **Complexity:** Low
- **Risk:** Low

### Step 7.G: Phase Gate — Hotkey Verification
- **Agent:** review-agent
- **Action:** Confirm all hotkeys function globally.
- **Verification:** All three hotkeys work when another app (e.g., Terminal, Safari) is in the foreground.
- **Dependencies:** Step 7.1

---

## Phase 8: Documentation and Release Preparation
**Purpose:** Create repository documentation and finalize the build system.

### Step 8.1: Create `README.md`
- **Agent:** documentation-agent
- **Location:** `cursor-highlighting/README.md`
- **Action:** Create comprehensive README in English.
- **Details:** Include:
  - Project name, one-line description, MIT license badge.
  - Features: Spotlight, Clicks, Key Strokes — brief description of each.
  - Requirements: macOS 26.0 (Tahoe) or later, Xcode 26.4+ (for Swift 6.3 toolchain).
  - Build instructions: `git clone ...`, `cd cursor-highlighting`, `make run` to run, `make app` to build .app bundle.
  - Permissions: explain Accessibility + Input Monitoring requirement, how to grant in System Settings > Privacy & Security.
  - Configuration: describe 4 Settings tabs.
  - Keyboard shortcuts: default Shift+1 for Spotlight, customizable for all.
  - Localization: English (default) and Japanese, switchable in Settings.
  - Architecture: brief note on Swift 6.3, AsyncStream C bridge pattern.
  - Credits: sindresorhus libraries.
  - License: MIT.
- **Dependencies:** All previous phases.
- **Verification:** File renders correctly as Markdown.
- **Complexity:** Low
- **Risk:** Low

### Step 8.2: Create `CHANGELOG.md`
- **Agent:** documentation-agent
- **Location:** `cursor-highlighting/CHANGELOG.md`
- **Action:** Create initial changelog.
- **Details:**
  ```markdown
  # Changelog

  ## [1.0.0] - 2026-04-19

  ### Added
  - Mouse Spotlight feature with customizable radius, blur, opacity, and color
  - Mouse Click visualization with color-coded expanding rings for left/right clicks
  - Key Stroke display with macOS modifier symbols (⌘⌥⇧⌃)
  - Global hotkey support (customizable via Settings)
  - Settings window with 4 tabs (Mouse Spotlight, Mouse Clicks, Key Strokes, Others)
  - English and Japanese localization
  - Launch at Login option
  - Menu bar interface with per-feature toggles
  - Built with Swift 6.3 language mode — zero data races by construction
  ```
- **Dependencies:** None
- **Verification:** File exists.
- **Complexity:** Low
- **Risk:** Low

### Step 8.3: Final Makefile Validation
- **Agent:** devops-agent
- **Location:** `cursor-highlighting/Makefile` (verify/update)
- **Action:** Ensure `make app` produces a fully functional .app bundle including resource bundles.
- **Details:**
  - After `swift build -c release`, run `ls .build/release/*.bundle` to identify the exact SPM resource bundle name.
  - If the name differs from `CursorHighlighting_CursorHighlighting.bundle`, update the `RESOURCE_BUNDLE` variable in the Makefile.
  - Verify that `open build/CursorHighlighting.app` launches correctly and localization works (the resource bundle must be present for `Bundle.module` to find `.lproj` files).
- **Dependencies:** Step 1.7
- **Verification:** `make clean && make app && open build/CursorHighlighting.app` — app launches, all features work, localization strings load correctly.
- **Complexity:** Medium
- **Risk:** Medium — Resource bundle path is the primary risk. Agent must verify empirically after build.

### Step 8.G: Phase Gate — Final End-to-End Verification
- **Agent:** review-agent
- **Action:** Complete project verification.
- **Verification:**
  1. `swift build -c release` — 0 errors, 0 concurrency warnings from `CursorHighlighting` target.
  2. `make app` — produces `build/CursorHighlighting.app`.
  3. `open build/CursorHighlighting.app` — launches as menu-bar-only agent.
  4. All three features toggle from menu and hotkeys.
  5. Settings window: 4 tabs, all controls functional. Persistence across restart.
  6. Language switch: English → Japanese → restart → Japanese UI.
  7. Launch at Login toggle: appears in System Settings > General > Login Items.
  8. Repository files: `.gitignore`, `LICENSE`, `README.md`, `CHANGELOG.md` all present and correct.
  9. Code comments: spot-check 5 files — all comments in Japanese.
  10. **Concurrency safety:** `grep -r "@unchecked Sendable" Sources/` returns exactly 1 result in `CGEventBridge.swift`.
  11. **No DispatchQueue.main.async:** `grep -r "DispatchQueue.main" Sources/` returns 0 results.
- **Dependencies:** All steps.

---

**Risks and Mitigations:**

| Risk | Severity | Mitigation |
|---|---|---|
| `CGEvent.tapCreate` returns `nil` without Accessibility permission | High | `PermissionManager` checks + prompts at launch. `createKeyEventStream()` returns `nil` gracefully. `KeyStrokeManager` observes permission state and retries activation. |
| Core Graphics even-odd cutout + blur edge quality at 120Hz | High | Try even-odd path first (fast, GPU-composited). For blur, try `CIGaussianBlur` layer filter. If too expensive, use gradient ring fallback. Agent should benchmark and choose. |
| SPM resource bundle not found in .app | Medium | Step 8.3 verifies empirically and fixes Makefile. `L()` helper can fall back to returning the key if `Bundle.module` fails. |
| sindresorhus dependency compilation under swift-tools-version 6.3 | Medium | Dependencies compile with their own language mode (not ours). If resolution fails, pin to a specific release tag known to work with Swift 6 toolchain. |
| `AsyncStream` buffer overflow under extreme input rate | Low | `bufferingPolicy: .bufferingNewest(128)` drops oldest events rather than blocking. For mouse/keyboard events, this is acceptable — a dropped intermediate mouse position is invisible. |
| Overlay windows don't appear above fullscreen apps | Medium | `.fullScreenAuxiliary` + `.screenSaver` level. If insufficient, document as known limitation in README. |

**Success Criteria:**
1. `swift build` — 0 errors, 0 concurrency warnings from `CursorHighlighting` target, under Swift 6 language mode.
2. `make run` launches menu-bar-only app. `make app` produces valid `.app` bundle.
3. Mouse Spotlight: Shift+1 toggles fullscreen dim overlay with cursor-following bright circle. Settings (radius/blur/opacity/color) apply in real-time.
4. Mouse Clicks: left-click → blue ring, right-click → red ring, expanding + fading ~0.4s. Colors/size customizable.
5. Key Strokes: typed keys appear in bottom-center HUD with correct macOS modifier symbols. Entries fade after 2s.
6. All three features work simultaneously with correct overlay stacking.
7. Settings window: 4 tabs, all controls functional, persistent across restarts.
8. Language switchable between English and Japanese.
9. All code comments in Japanese.
10. `grep -r "@unchecked Sendable" Sources/` returns exactly 1 result (`CGEventBridge.swift`).
11. `grep -r "DispatchQueue.main" Sources/` returns 0 results.
12. Repository: `.gitignore`, `LICENSE` (MIT), `README.md`, `CHANGELOG.md` present.