import AppKit
import Defaults
import QuartzCore

// スポットライトオーバーレイウィンドウの管理クラス（マルチモニタ対応）
@MainActor
final class SpotlightOverlayWindow: NSObject {
    private struct Settings {
        var radius: CGFloat = 30
        var blurRadius: CGFloat = 0
        var overlayOpacity: CGFloat = 0
        var color: NSColor = .clear
    }

    private var panels: [CursorScreenID: (panel: OverlayPanel, view: SpotlightOverlayView)] = [:]
    private var mouseStreamCancel: (@MainActor () -> Void)?
    private var trackingTask: Task<Void, Never>?
    private var displayLink: CADisplayLink?
    private var displayLinkScreenID: CursorScreenID?
    private var pendingCursorPosition: NSPoint?
    private var activeScreenID: CursorScreenID?
    private var settings = Settings()
    private var isVisible = false

    // オーバーレイを表示してマウス追跡を開始
    func show() {
        hide()
        isVisible = true
        updateSettings()
        reconcileScreens()
        updateCursorPosition(NSEvent.mouseLocation)

        // マウスイベントストリームを開始
        let (stream, cancel) = createMouseEventStream(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged],
            bufferingNewest: 1
        )
        self.mouseStreamCancel = cancel

        // マウス位置を追跡
        trackingTask = Task { [weak self] in
            for await event in stream {
                self?.enqueueCursorPosition(
                    NSPoint(x: event.locationInScreen.x, y: event.locationInScreen.y)
                )
            }
        }
    }

    // オーバーレイを非表示にして追跡を停止
    func hide() {
        isVisible = false
        trackingTask?.cancel()
        trackingTask = nil
        mouseStreamCancel?()
        mouseStreamCancel = nil
        displayLink?.invalidate()
        displayLink = nil
        displayLinkScreenID = nil
        pendingCursorPosition = nil
        activeScreenID = nil
        for (_, entry) in panels {
            entry.panel.hideOverlay()
        }
        panels.removeAll()
    }

    // 設定変更を反映
    func updateSettings() {
        settings = Settings(
            radius: CGFloat(Defaults[.spotlightRadius]),
            blurRadius: CGFloat(Defaults[.spotlightBlur]),
            overlayOpacity: CGFloat(Defaults[.spotlightOpacity]),
            color: Defaults[.spotlightColor].nsColor
        )
        for (_, entry) in panels {
            applySettings(to: entry.view)
        }
    }

    func screenParametersDidChange() {
        guard isVisible else { return }
        displayLink?.invalidate()
        displayLink = nil
        displayLinkScreenID = nil
        reconcileScreens()
        let cursorPosition = pendingCursorPosition ?? NSEvent.mouseLocation
        pendingCursorPosition = nil
        updateCursorPosition(cursorPosition)
    }

    private func restartDisplayLink(for screen: NSScreen) {
        displayLink?.invalidate()
        let newDisplayLink = screen.displayLink(
            target: self,
            selector: #selector(displayLinkDidFire(_:))
        )
        newDisplayLink.isPaused = true
        newDisplayLink.add(to: .main, forMode: .common)
        displayLink = newDisplayLink
        displayLinkScreenID = screen.cursorHighlightingID
    }

    private func enqueueCursorPosition(_ screenPoint: NSPoint) {
        pendingCursorPosition = screenPoint
        guard let displayLink else {
            pendingCursorPosition = nil
            updateCursorPosition(screenPoint)
            return
        }
        displayLink.isPaused = false
    }

    @objc private func displayLinkDidFire(_ displayLink: CADisplayLink) {
        displayLink.isPaused = true
        guard let screenPoint = pendingCursorPosition else { return }
        pendingCursorPosition = nil
        updateCursorPosition(screenPoint)
    }

    // スクリーン座標からビュー座標へ変換してカーソル位置を更新
    private func updateCursorPosition(_ screenPoint: NSPoint) {
        guard let cursorScreen = preferredScreen(for: screenPoint) else {
            if let activeScreenID {
                panels[activeScreenID]?.view.setCursorPosition(nil)
            }
            activeScreenID = nil
            return
        }

        let nextScreenID = cursorScreen.cursorHighlightingID
        guard let entry = panels[nextScreenID] else { return }

        if displayLinkScreenID != nextScreenID {
            restartDisplayLink(for: cursorScreen)
        }

        if activeScreenID != nextScreenID, let activeScreenID {
            panels[activeScreenID]?.view.setCursorPosition(nil)
        }

        let windowPoint = entry.panel.convertPoint(fromScreen: screenPoint)
        let viewPoint = entry.view.convert(windowPoint, from: nil)
        entry.view.setCursorPosition(viewPoint)
        activeScreenID = nextScreenID
    }

    private func applySettings(to view: SpotlightOverlayView) {
        view.configure(
            spotlightRadius: settings.radius,
            blurRadius: settings.blurRadius,
            overlayOpacity: settings.overlayOpacity,
            spotlightColor: settings.color
        )
    }

    private func reconcileScreens() {
        let screensByID = Dictionary(
            uniqueKeysWithValues: NSScreen.screens.map { ($0.cursorHighlightingID, $0) })
        let reconciliation = ScreenReconciliation(
            existing: Set(panels.keys),
            current: Set(screensByID.keys)
        )

        for id in reconciliation.removed {
            panels.removeValue(forKey: id)?.panel.hideOverlay()
            if activeScreenID == id {
                activeScreenID = nil
            }
        }

        for id in reconciliation.retained {
            if let entry = panels[id], let screen = screensByID[id] {
                entry.panel.move(to: screen)
            }
        }

        for id in reconciliation.added {
            guard let screen = screensByID[id] else { continue }
            let level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue - 1)
            let panel = OverlayPanel(screen: screen, overlayLevel: level)
            let view = SpotlightOverlayView(
                frame: NSRect(origin: .zero, size: screen.frame.size)
            )
            view.autoresizingMask = [.width, .height]
            applySettings(to: view)
            view.setCursorPosition(nil)
            panel.contentView = view
            panel.showFullScreen()
            panels[id] = (panel: panel, view: view)
        }
    }

    private func preferredScreen(for point: NSPoint) -> NSScreen? {
        NSScreen.containing(point) ?? NSScreen.main ?? NSScreen.screens.first
    }
}
