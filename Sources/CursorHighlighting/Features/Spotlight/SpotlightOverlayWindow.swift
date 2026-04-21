import AppKit
import Defaults

// スポットライトオーバーレイウィンドウの管理クラス
@MainActor
final class SpotlightOverlayWindow {
    private var panel: OverlayPanel?
    private var overlayView: SpotlightOverlayView?
    private var mouseStreamCancel: (@Sendable () -> Void)?
    private var trackingTask: Task<Void, Never>?

    // オーバーレイを表示してマウス追跡を開始
    func show() {
        hide()

        guard let screen = preferredScreen(for: NSEvent.mouseLocation) else { return }
        let level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue - 1)
        let newPanel = OverlayPanel(screen: screen, overlayLevel: level)
        let view = SpotlightOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.autoresizingMask = [.width, .height]

        // 現在の設定を適用
        view.spotlightRadius = CGFloat(Defaults[.spotlightRadius])
        view.blurRadius = CGFloat(Defaults[.spotlightBlur])
        view.overlayOpacity = CGFloat(Defaults[.spotlightOpacity])
        view.spotlightColor = Defaults[.spotlightColor].nsColor

        newPanel.contentView = view
        newPanel.showFullScreen()

        self.panel = newPanel
        self.overlayView = view

        // 初期カーソル位置を設定
        updateCursorPosition(NSEvent.mouseLocation)

        // マウスイベントストリームを開始
        let (stream, cancel) = createMouseEventStream(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        )
        self.mouseStreamCancel = cancel

        // マウス位置を追跡
        trackingTask = Task { [weak self] in
            for await event in stream {
                self?.updateCursorPosition(
                    NSPoint(x: event.locationInScreen.x, y: event.locationInScreen.y)
                )
            }
        }
    }

    // オーバーレイを非表示にして追跡を停止
    func hide() {
        trackingTask?.cancel()
        trackingTask = nil
        mouseStreamCancel?()
        mouseStreamCancel = nil
        panel?.hideOverlay()
        panel = nil
        overlayView = nil
    }

    // 設定変更を反映
    func updateSettings() {
        overlayView?.spotlightRadius = CGFloat(Defaults[.spotlightRadius])
        overlayView?.blurRadius = CGFloat(Defaults[.spotlightBlur])
        overlayView?.overlayOpacity = CGFloat(Defaults[.spotlightOpacity])
        overlayView?.spotlightColor = Defaults[.spotlightColor].nsColor
        overlayView?.needsDisplay = true
    }

    // スクリーン座標からビュー座標へ変換してカーソル位置を更新
    private func updateCursorPosition(_ screenPoint: NSPoint) {
        guard let panel, let overlayView else { return }

        if let screen = preferredScreen(for: screenPoint), screen !== panel.currentScreen {
            panel.move(to: screen)
        }

        let windowPoint = panel.convertPoint(fromScreen: screenPoint)
        let viewPoint = overlayView.convert(windowPoint, from: nil)
        overlayView.cursorPosition = viewPoint
    }

    private func preferredScreen(for point: NSPoint) -> NSScreen? {
        NSScreen.containing(point) ?? NSScreen.main ?? NSScreen.screens.first
    }
}
