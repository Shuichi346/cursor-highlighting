import AppKit
import Defaults
import SwiftUI

// アプリ全体の状態管理
@MainActor
@Observable
final class AppState {
    let permissionManager: PermissionManager
    let spotlightManager: SpotlightManager
    let clickManager: ClickManager
    let keyStrokeManager: KeyStrokeManager
    private var settingsWindow: NSWindow?
    private var keyStrokeObservationTask: Task<Void, Never>?
    private var screenParametersObserver: NSObjectProtocol?
    private var didStart = false

    init(permissionManager: PermissionManager = PermissionManager()) {
        self.permissionManager = permissionManager
        spotlightManager = SpotlightManager()
        clickManager = ClickManager()
        keyStrokeManager = KeyStrokeManager()
    }

    func start() {
        guard !didStart else { return }
        didStart = true

        spotlightManager.start()
        clickManager.start()
        keyStrokeManager.start()

        permissionManager.onAuthorizationChange = { [weak self] isGranted in
            self?.applyInputMonitoringStatus(isGranted)
        }

        keyStrokeObservationTask = Task { [weak self] in
            for await isEnabled in Defaults.updates(.keyStrokeEnabled, initial: false) {
                self?.applyKeyStrokeEnabledState(isEnabled, requestPermission: isEnabled)
            }
        }

        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.screenParametersDidChange()
            }
        }

        applyKeyStrokeEnabledState(
            Defaults[.keyStrokeEnabled],
            requestPermission: Defaults[.keyStrokeEnabled]
        )
    }

    // カスタム設定ウィンドウを表示
    func showSettings() {
        if let existing = settingsWindow {
            if existing.isMiniaturized {
                existing.deminiaturize(nil)
            }
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

    func applicationDidBecomeActive() {
        guard didStart else { return }
        let isGranted = permissionManager.refreshInputMonitoringStatus()
        applyInputMonitoringStatus(isGranted)
    }

    func shutdown() {
        guard didStart else { return }
        didStart = false
        keyStrokeObservationTask?.cancel()
        keyStrokeObservationTask = nil
        if let screenParametersObserver {
            NotificationCenter.default.removeObserver(screenParametersObserver)
            self.screenParametersObserver = nil
        }
        permissionManager.onAuthorizationChange = nil
        permissionManager.stopPolling()
        spotlightManager.shutdown()
        clickManager.shutdown()
        keyStrokeManager.shutdown()
    }

    private func applyKeyStrokeEnabledState(
        _ isEnabled: Bool,
        requestPermission: Bool
    ) {
        guard isEnabled else {
            permissionManager.stopPolling()
            keyStrokeManager.deactivate()
            return
        }

        if permissionManager.refreshInputMonitoringStatus() {
            keyStrokeManager.activate()
        } else {
            keyStrokeManager.deactivate()
            if requestPermission {
                permissionManager.requestInputMonitoring()
            }
        }
    }

    private func applyInputMonitoringStatus(_ isGranted: Bool) {
        guard Defaults[.keyStrokeEnabled], isGranted else {
            keyStrokeManager.deactivate()
            return
        }
        keyStrokeManager.activate()
    }

    private func screenParametersDidChange() {
        spotlightManager.screenParametersDidChange()
        clickManager.screenParametersDidChange()
        keyStrokeManager.screenParametersDidChange()
    }
}
