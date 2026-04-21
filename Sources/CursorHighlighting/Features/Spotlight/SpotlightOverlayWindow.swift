import AppKit
import Defaults

// スポットライトオーバーレイウィンドウの管理クラス（マルチモニタ対応）
@MainActor
final class SpotlightOverlayWindow {
    private var panels: [ObjectIdentifier: (panel: OverlayPanel, view: SpotlightOverlayView)] = [:]
    private var mouseStreamCancel: (@Sendable () -> Void)?
    private var trackingTask: Task<Void, Never>?

    // オーバーレイを表示してマウス追跡を開始
    func show() {
        hide()

        let level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue - 1)

        // 全ディスプレイにパネルを配置
        for screen in NSScreen.screens {
            let newPanel = OverlayPanel(screen: screen, overlayLevel: level)
            let view = SpotlightOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.autoresizingMask = [.width, .height]

            applySettings(to: view)

            newPanel.contentView = view
            newPanel.showFullScreen()

            let key = ObjectIdentifier(screen)
            panels[key] = (panel: newPanel, view: view)
        }

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
        for (_, entry) in panels {
            entry.panel.hideOverlay()
        }
        panels.removeAll()
    }

    // 設定変更を反映
    func updateSettings() {
        for (_, entry) in panels {
            applySettings(to: entry.view)
            entry.view.needsDisplay = true
        }
    }

    // スクリーン座標からビュー座標へ変換してカーソル位置を更新
    private func updateCursorPosition(_ screenPoint: NSPoint) {
        let cursorScreen = preferredScreen(for: screenPoint)

        for (_, entry) in panels {
            let panel = entry.panel
            let view = entry.view

            if panel.currentScreen === cursorScreen {
                // カーソルがあるスクリーンではスポットライトを表示
                let windowPoint = panel.convertPoint(fromScreen: screenPoint)
                let viewPoint = view.convert(windowPoint, from: nil)
                view.cursorPosition = viewPoint
                view.overlayOpacity = CGFloat(Defaults[.spotlightOpacity])
            } else {
                // カーソルのない画面は全面暗幕
                view.cursorPosition = NSPoint(x: -99999, y: -99999)
                view.overlayOpacity = CGFloat(Defaults[.spotlightOpacity])
            }
        }
    }

    private func applySettings(to view: SpotlightOverlayView) {
        view.spotlightRadius = CGFloat(Defaults[.spotlightRadius])
        view.blurRadius = CGFloat(Defaults[.spotlightBlur])
        view.overlayOpacity = CGFloat(Defaults[.spotlightOpacity])
        view.spotlightColor = Defaults[.spotlightColor].nsColor
    }

    private func preferredScreen(for point: NSPoint) -> NSScreen? {
        NSScreen.containing(point) ?? NSScreen.main ?? NSScreen.screens.first
    }
}
