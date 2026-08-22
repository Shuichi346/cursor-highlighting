import AppKit
import Defaults
import SwiftUI

// メインエントリーポイント：メニューバー専用アプリ
@main
struct CursorHighlightingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Default(.spotlightEnabled) private var spotlightEnabled
    @Default(.clickEnabled) private var clickEnabled
    @Default(.keyStrokeEnabled) private var keyStrokeEnabled

    var body: some Scene {
        MenuBarExtra("Cursor Highlighting", systemImage: "cursorarrow.rays") {
            Toggle(L("menu.spotlight"), isOn: $spotlightEnabled)
            Toggle(L("menu.clicks"), isOn: $clickEnabled)
            Toggle(L("menu.keystrokes"), isOn: $keyStrokeEnabled)
            Divider()
            Button(L("menu.settings")) {
                appDelegate.appState.showSettings()
            }
            Divider()
            Button(L("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        appState.applicationDidBecomeActive()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.shutdown()
    }
}
