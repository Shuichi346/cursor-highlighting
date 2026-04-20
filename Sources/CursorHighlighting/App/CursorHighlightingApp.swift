import Defaults
import SwiftUI
import AppKit

// メインエントリーポイント：メニューバー専用アプリ
@main
struct CursorHighlightingApp: App {
    @State private var appState = AppState()
    @Default(.spotlightEnabled) private var spotlightEnabled
    @Default(.clickEnabled) private var clickEnabled
    @Default(.keyStrokeEnabled) private var keyStrokeEnabled
    @Default(.appLanguage) private var appLanguage

    init() {
        Localization.applySavedLanguage()
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        let _ = appLanguage

        MenuBarExtra("Cursor Highlighting", systemImage: "cursorarrow.rays") {
            Toggle(L("menu.spotlight"), isOn: $spotlightEnabled)
            Toggle(L("menu.clicks"), isOn: $clickEnabled)
            Toggle(L("menu.keystrokes"), isOn: $keyStrokeEnabled)
            Divider()
            Button(L("menu.settings")) {
                appState.showSettings()
            }
            Divider()
            Button(L("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
