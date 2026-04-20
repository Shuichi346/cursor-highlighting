import AppKit
import Defaults
import SwiftUI

// キーストロークHUDのオーバーレイウィンドウ管理
@MainActor
@Observable
final class KeyStrokeOverlayWindow {
    private var panel: OverlayPanel?
    private var hostingView: NSHostingView<KeyStrokeHUDView>?
    var entries: [KeyStrokeEntry] = []
    private var cleanupTask: Task<Void, Never>?

    // オーバーレイを表示
    func show() {
        cleanupTask?.cancel()
        cleanupTask = nil
        panel?.hideOverlay()
        panel = nil
        hostingView = nil

        guard let screen = preferredScreen() else { return }
        let level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        let newPanel = OverlayPanel(screen: screen, overlayLevel: level)

        let hosting = NSHostingView(rootView: makeHUDView())
        hosting.frame = NSRect(origin: .zero, size: screen.frame.size)
        hosting.autoresizingMask = [.width, .height]

        newPanel.contentView = hosting
        newPanel.showFullScreen()

        self.panel = newPanel
        self.hostingView = hosting

        // 古いエントリを定期的に削除
        startCleanupTask()
    }

    // オーバーレイを非表示
    func hide() {
        cleanupTask?.cancel()
        cleanupTask = nil
        panel?.hideOverlay()
        panel = nil
        hostingView = nil
        entries = []
    }

    // エントリを追加
    func addEntry(_ text: String) {
        moveToCurrentScreenIfNeeded()
        entries.append(KeyStrokeEntry(text: text, timestamp: Date()))
        if entries.count > 10 {
            entries.removeFirst()
        }
        refreshView()
    }

    // フォントサイズ変更を即時反映
    func updateFontSize() {
        refreshView()
    }

    // ホスティングビューのrootViewを更新
    private func refreshView() {
        moveToCurrentScreenIfNeeded()
        hostingView?.rootView = makeHUDView()
    }

    private func makeHUDView() -> KeyStrokeHUDView {
        KeyStrokeHUDView(entries: entries, fontSize: Defaults[.keyStrokeFontSize])
    }

    private func startCleanupTask() {
        cleanupTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self = self else { break }
                let now = Date()
                let previousCount = self.entries.count
                self.entries.removeAll { now.timeIntervalSince($0.timestamp) > 2.0 }
                if self.entries.count != previousCount {
                    self.refreshView()
                }
            }
        }
    }

    private func moveToCurrentScreenIfNeeded() {
        guard let panel, let screen = preferredScreen(), screen !== panel.currentScreen else { return }
        panel.move(to: screen)
    }

    private func preferredScreen() -> NSScreen? {
        NSScreen.containing(NSEvent.mouseLocation) ?? NSScreen.main ?? NSScreen.screens.first
    }
}
