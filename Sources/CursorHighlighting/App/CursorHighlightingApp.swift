import SwiftUI
import Defaults

// メインエントリーポイント：メニューバー専用アプリ
@main
struct CursorHighlightingApp: App {
    @State private var appState = AppState()
    @Default(.spotlightEnabled) private var spotlightEnabled
    @Default(.clickEnabled) private var clickEnabled
    @Default(.keyStrokeEnabled) private var keyStrokeEnabled

    var body: some Scene {
        // メニューバーアイコンとドロップダウンメニュー
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
