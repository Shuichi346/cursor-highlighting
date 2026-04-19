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
        let level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue - 1)
        let newPanel = OverlayPanel(overlayLevel: level)
        let view = SpotlightOverlayView(frame: newPanel.frame)

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
        guard let panel = panel else { return }
        let panelFrame = panel.frame
        // スクリーン座標（左下原点）→ ビュー座標（左上原点、isFlipped=true）
        let viewX = screenPoint.x - panelFrame.origin.x
        let viewY = panelFrame.height - (screenPoint.y - panelFrame.origin.y)
        overlayView?.cursorPosition = NSPoint(x: viewX, y: viewY)
    }
}
