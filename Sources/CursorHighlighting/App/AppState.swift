import AppKit
import Defaults
import SwiftUI

// アプリ全体の状態管理
@MainActor
@Observable
final class AppState {
    let permissionManager = PermissionManager()
    let spotlightManager: SpotlightManager
    let clickManager: ClickManager
    let keyStrokeManager: KeyStrokeManager
    private var settingsWindow: NSWindow?
    private var permissionObservationTask: Task<Void, Never>?
    private var terminationObserver: NSObjectProtocol?

    init() {
        spotlightManager = SpotlightManager()
        clickManager = ClickManager()
        keyStrokeManager = KeyStrokeManager()

        permissionManager.checkAndRequestAccessibility()

        permissionObservationTask = Task { [weak self] in
            while let self = self, !self.permissionManager.isAccessibilityGranted {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    // キャンセルされた場合はループを脱出
                    return
                }
                // sleep後にもキャンセル状態を確認
                guard !Task.isCancelled else { return }
            }
            guard let self = self else { return }
            // 権限が付与されたらポーリングを停止
            self.permissionManager.stopPolling()
            // キーストロークが有効かつ未起動なら起動する
            if Defaults[.keyStrokeEnabled], !self.keyStrokeManager.isActive {
                self.keyStrokeManager.activate()
            }
        }

        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: NSApp,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                self?.shutdown()
            }
        }
    }

    // カスタム設定ウィンドウを表示
    func showSettings() {
        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: SettingsWindowView())

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Cursor Highlighting"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 720, height: 520))
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor.windowBackgroundColor

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.settingsWindow = window
    }

    func shutdown() {
        permissionObservationTask?.cancel()
        permissionObservationTask = nil
        permissionManager.stopPolling()
        spotlightManager.shutdown()
        clickManager.shutdown()
        keyStrokeManager.shutdown()
    }
}
