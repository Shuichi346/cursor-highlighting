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
        let level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        let newPanel = OverlayPanel(overlayLevel: level)

        let hudView = KeyStrokeHUDView(
            entries: entries,
            fontSize: Defaults[.keyStrokeFontSize]
        )
        let hosting = NSHostingView(rootView: hudView)
        hosting.frame = newPanel.frame
        hosting.autoresizingMask = [.width, .height]

        newPanel.contentView = hosting
        newPanel.showFullScreen()

        self.panel = newPanel
        self.hostingView = hosting

        // 古いエントリを定期的に削除
        cleanupTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self = self else { break }
                let now = Date()
                self.entries.removeAll { now.timeIntervalSince($0.timestamp) > 2.0 }
                self.refreshView()
            }
        }
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
        entries.append(KeyStrokeEntry(text: text, timestamp: Date()))
        if entries.count > 10 {
            entries.removeFirst()
        }
        refreshView()
    }

    // ホスティングビューのrootViewを更新
    private func refreshView() {
        hostingView?.rootView = KeyStrokeHUDView(
            entries: entries,
            fontSize: Defaults[.keyStrokeFontSize]
        )
    }
}
