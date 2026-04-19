import AppKit
import Defaults
import Settings

// アプリ全体の状態管理
@MainActor
@Observable
final class AppState {
    let permissionManager = PermissionManager()
    let spotlightManager: SpotlightManager
    let clickManager: ClickManager
    let keyStrokeManager: KeyStrokeManager
    private var settingsWindowController: SettingsWindowController?
    private var permissionObservationTask: Task<Void, Never>?

    init() {
        // 各マネージャーを初期化
        spotlightManager = SpotlightManager()
        clickManager = ClickManager()
        keyStrokeManager = KeyStrokeManager()

        // アクセシビリティ権限の確認
        permissionManager.checkAndRequestAccessibility()

        // 権限付与後にキーストロークを有効化（CGEventTapに権限が必要）
        permissionObservationTask = Task { [weak self] in
            // 権限が付与されるまで待機
            while let self = self, !self.permissionManager.isAccessibilityGranted {
                try? await Task.sleep(for: .seconds(1))
            }
            // 権限が付与された時点でキーストロークが有効設定なら有効化
            if let self = self, Defaults[.keyStrokeEnabled], !self.keyStrokeManager.isActive {
                self.keyStrokeManager.activate()
            }
        }
    }

    // 設定ウィンドウを表示
    func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                panes: [
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("spotlight"),
                        title: L("settings.spotlight.title"),
                        toolbarIcon: NSImage(
                            systemSymbolName: "light.max",
                            accessibilityDescription: nil
                        )!
                    ) {
                        SpotlightSettingsView()
                    },
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("clicks"),
                        title: L("settings.clicks.title"),
                        toolbarIcon: NSImage(
                            systemSymbolName: "cursorarrow.click.2",
                            accessibilityDescription: nil
                        )!
                    ) {
                        ClickSettingsView()
                    },
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("keystrokes"),
                        title: L("settings.keystrokes.title"),
                        toolbarIcon: NSImage(
                            systemSymbolName: "keyboard",
                            accessibilityDescription: nil
                        )!
                    ) {
                        KeyStrokeSettingsView()
                    },
                    Settings.Pane(
                        identifier: Settings.PaneIdentifier("others"),
                        title: L("settings.others.title"),
                        toolbarIcon: NSImage(
                            systemSymbolName: "gearshape",
                            accessibilityDescription: nil
                        )!
                    ) {
                        OtherSettingsView()
                    },
                ]
            )
        }
        settingsWindowController?.show()
        NSApp.activate(ignoringOtherApps: true)
    }
}
