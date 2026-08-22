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
    private let clock = ContinuousClock()

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
        entries.append(
            KeyStrokeEntry(
                text: text,
                expiresAt: clock.now.advanced(by: .seconds(2))
            ))
        if entries.count > 10 {
            entries.removeFirst()
        }
        refreshView()
        scheduleNextCleanup()
    }

    // フォントサイズ・テーマ変更を即時反映
    func updateAppearance() {
        refreshView()
    }

    // 下位互換: フォントサイズ変更のみの呼び出し
    func updateFontSize() {
        refreshView()
    }

    private func refreshView() {
        moveToCurrentScreenIfNeeded()
        hostingView?.rootView = makeHUDView()
    }

    private func makeHUDView() -> KeyStrokeHUDView {
        KeyStrokeHUDView(
            entries: entries,
            fontSize: Defaults[.keyStrokeFontSize],
            theme: Defaults[.keyStrokeTheme]
        )
    }

    func screenParametersDidChange() {
        moveToCurrentScreenIfNeeded()
    }

    private func scheduleNextCleanup() {
        cleanupTask?.cancel()
        guard let nextExpiration = entries.map(\.expiresAt).min() else {
            cleanupTask = nil
            return
        }

        let clock = self.clock
        cleanupTask = Task { [weak self, clock] in
            do {
                try await clock.sleep(until: nextExpiration)
            } catch {
                return
            }
            guard let self else { return }
            let previousCount = self.entries.count
            let now = self.clock.now
            self.entries.removeAll { $0.expiresAt <= now }
            if self.entries.count != previousCount {
                self.refreshView()
            }
            self.scheduleNextCleanup()
        }
    }

    private func moveToCurrentScreenIfNeeded() {
        guard let panel, let screen = preferredScreen(),
            screen.cursorHighlightingID != panel.currentScreen.cursorHighlightingID
                || screen.frame != panel.currentScreen.frame
        else {
            return
        }
        panel.move(to: screen)
    }

    private func preferredScreen() -> NSScreen? {
        NSScreen.containing(NSEvent.mouseLocation) ?? NSScreen.main ?? NSScreen.screens.first
    }
}
