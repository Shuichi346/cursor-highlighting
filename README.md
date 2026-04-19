# Cursor Highlighting

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A macOS menu-bar-only utility that visually highlights mouse operations and keyboard input for presentations, screen recordings, and live streaming.

## Features

- **Mouse Spotlight** — Dims the screen except for a circle around the cursor
- **Mouse Clicks** — Animated color-coded rings on left/right click
- **Key Strokes** — On-screen HUD display of pressed keys with macOS modifier symbols (⌘⌥⇧⌃)

All features are togglable via customizable global hotkeys.

## Requirements

- macOS 26.0 (Tahoe) or later
- Xcode 26.4+ (provides Swift 6.3 toolchain and macOS 26 SDK)

## Build & Run

```bash
git clone https://github.com/your-username/cursor-highlighting.git
cd cursor-highlighting
make run        # Build and run
make app        # Create .app bundle at build/CursorHighlighting.app
make clean      # Clean build artifacts
```

## Permissions

This app requires **Accessibility** permission to monitor mouse and keyboard events.

On first launch, you will be prompted to grant access. Navigate to:
**System Settings > Privacy & Security > Accessibility** and enable Cursor Highlighting.

## Configuration

Open Settings from the menu bar dropdown. Four tabs:

1. **Mouse Spotlight** — Radius, blur, opacity, color, hotkey (default: Shift+1)
2. **Mouse Clicks** — Left/right click colors, ring size, hotkey
3. **Key Strokes** — Enable/disable, font size, hotkey
4. **Others** — Launch at Login, language (English/Japanese)

## Keyboard Shortcuts

| Feature | Default | Customizable |
|---------|---------|--------------|
| Mouse Spotlight | ⇧1 | ✅ |
| Mouse Clicks | (none) | ✅ |
| Key Strokes | (none) | ✅ |

## Localization

English (default) and Japanese. Switchable in Settings > Others.

## Architecture

Built with Swift 6.3 language mode (strict concurrency). Uses `AsyncStream` to safely bridge C-level `CGEventTapCallBack` into Swift's structured concurrency model — all data races are caught at compile time.

## Credits

- [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [sindresorhus/Settings](https://github.com/sindresorhus/Settings)
- [sindresorhus/LaunchAtLogin-Modern](https://github.com/sindresorhus/LaunchAtLogin-Modern)
- [sindresorhus/Defaults](https://github.com/sindresorhus/Defaults)

## License

MIT
