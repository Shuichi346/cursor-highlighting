# Changelog

## [1.0.6] - 2026-04-21

### Fixed
- **Keystrokes:** Fixed keystroke HUD displaying incorrect characters on non-US keyboard layouts (JIS, Dvorak, AZERTY, etc.). Now extracts Unicode characters directly from `CGEvent.keyboardGetUnicodeString` at the event tap callback, with `UCKeyTranslate` via `TISCopyCurrentKeyboardLayoutInputSource` as a secondary fallback. The previous static US QWERTY keycode table is retained only as a last resort.
- **Keystrokes:** Added support for previously unhandled keys: F13–F20, numpad operators, JIS-specific keys (英数/かな), and other special keys that were displaying as `?`.
- **Core / Lifecycle:** Fixed a potential busy-loop on app termination when accessibility permission had not been granted. The permission polling task now properly exits on cancellation instead of silently swallowing `CancellationError` and re-entering the loop.
- **Settings:** "Reset All Settings" now also disables Launch at Login, matching the UI label "Restore all settings to their original default values."
- **Spotlight:** Fixed the edge blur effect rendering as an unnatural dark halo outside the spotlight circle. The blur now draws a smooth opacity gradient from the spotlight boundary outward, correctly softening the edge transition.
- **Spotlight:** Fixed spotlight overlay only covering the current display on multi-monitor setups. All connected screens are now dimmed simultaneously, with the spotlight cutout following the cursor across displays.
- **Click Effects:** Fixed click ring animation shrinking instead of expanding when Ring Size was set below 5 px. The initial ring radius is now clamped proportionally to `maxRadius`. The minimum slider value has been raised to 5 px.
- **Settings / Info.plist:** Unified version string across `Info.plist` (`CFBundleVersion`, `CFBundleShortVersionString`) and the Settings UI. Version is now read dynamically from `Bundle.main` instead of being hardcoded.

## [1.0.5] - 2026-04-21

### Fixed
- **Core / Resources:** Fixed an issue where the built `.app` bundle requested access to the source code directory (e.g. Documents folder) on launch and when opening Settings. This was caused by SPM's auto-generated `resource_bundle_accessor.swift` containing a hardcoded fallback path to the build directory. Resolved by eliminating `Bundle.module` dependency from the project and correcting the `.bundle` copy destination in the Makefile.

### Changed
- **Localization:** Replaced `Localizable.strings` / `Bundle.module` based localization with an in-code Swift dictionary in `L10n.swift`. This removes the SPM resource bundle dependency from the project target entirely.
- **Package.swift:** Removed `defaultLocalization`, `resources`, and `exclude` declarations since the project no longer uses SPM resource bundles.
- **Makefile:** Changed dependency library `.bundle` copy destination from `Contents/Resources/` to the `.app` root directory to match the path `Bundle.main.bundleURL` resolves to on macOS.

### Removed
- **Resources:** Removed `Sources/CursorHighlighting/Resources/en.lproj/Localizable.strings` and the `en.lproj` directory (no longer needed).

## [1.0.4] - 2026-04-20

### Changed
- **Spotlight:** Default enabled state changed to `true` (was `false`)
- **Spotlight:** Default radius changed to 30 px (was 150 px)
- **Spotlight:** Default blur changed to 0 px (was 30 px)
- **Spotlight:** Default background opacity changed to 0% (was 50%)
- **Spotlight:** Default color changed to semi-transparent red (was white)
- **Spotlight:** Removed default hotkey `⇧1` (now unassigned)
- **Spotlight:** Drawing logic now skips dimming overlay when opacity is 0 and always renders spotlight color circle when alpha > 0
- **Keystrokes:** Default enabled state changed to `false` (was `true`)
- **Keystrokes:** Font size slider range changed to 10–80 pt with step 2 (was 10–96 pt with step 4)
- **Added reset functionality:** Added a reset function to default values

### Fixed
- **Core / Lifecycle:** Fixed a bug where the accessibility permission polling would never stop if Key Strokes was disabled at the time permission was granted

## [1.0.3] - 2026-04-20

### Removed
- **Appearance tab:** Removed the entire Appearance settings tab and all related code (AppearanceSettingsView.swift, color presets, preset buttons). Color configuration for each feature is already available within its own settings page, making the dedicated Appearance tab redundant.
- **Japanese localization:** Removed Japanese language support and the language switcher in Settings > General. The UI is now English-only. Removed ja.lproj/Localizable.strings, the Localization enum, applySavedLanguage(), the appLanguage Defaults key, and CFBundleAllowMixedLocalizations from Info.plist.


##[1.0.2] - 2026-04-20

### Fixed
- **Core / Lifecycles:**
  - Fixed an issue where the saved enabled/disabled states for Mouse Spotlight, Clicks, and Key Strokes were not reflected immediately upon app launch.
  - Fixed task leaks and potential duplicate observations in `SpotlightManager`, `KeyStrokeOverlayWindow`, and `AppState` by properly retaining and cancelling Swift Concurrency `Task` instances.
  - Ensured that `CGEventTap` for keyboard monitoring is automatically re-enabled if the system temporarily disables it due to timeouts or heavy user input.
  - Hardened memory management for `CGEventTap` cleanup using a locked `EventTapBox` to prevent double-release crashes.

- **Multi-Monitor & Coordinates:**
  - Added full multi-monitor support; overlay windows and tracking now seamlessly follow the mouse across all connected displays.
  - Fixed an issue where the Mouse Clicks ring animation appeared at the wrong Y-coordinate due to incorrect flipped-view conversions.

- **UI & Settings:**
  - Fixed an issue where localization logic relied solely on system `AppleLanguages`, which caused mismatches. The app now resolves strings directly from the appropriate `.lproj` bundle.
  - Sliders in the Settings window now explicitly display their current exact values (e.g., "150 px").
  - Fixed an issue where changes to the Key Stroke font size were not visually applied until the next stroke.
  - Excluded standalone modifier key presses from incorrectly appearing in the Key Stroke HUD.
  - Fixed the Key Stroke HUD animation so it smoothly animates even when replacing entries without changing the total count.
  - Ensured that the alpha component of the spotlight color setting is accurately reflected in the spotlight overlay drawing.
  - Handled invalid hex color codes gracefully to prevent corrupted settings.

- **Build System:**
  - Fixed a hardcoded `.bundle` resource path in the `Makefile` to prevent build breakage when SPM dependency resolution changes folder names.

## [1.0.1] - 2026-04-19

### Changed
- Mouse Spotlight: Reduced minimum circle radius from 50px to 0px
- Mouse Spotlight: Reduced minimum dark area opacity from 0.1 to 0
- Key Strokes: Reduced minimum font size from 24pt to 10pt
- Mouse Clicks: Reduced minimum ring size from 15px to 0px
- Fixed sliders extending beyond window boundaries by setting fixed width

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
