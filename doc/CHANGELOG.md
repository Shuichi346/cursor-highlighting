# Changelog

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
