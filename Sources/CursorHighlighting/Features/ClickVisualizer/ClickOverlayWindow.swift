import AppKit
// クリックリング表示用のオーバーレイウィンドウ
@MainActor
final class ClickOverlayWindow {
    private var panels: [CursorScreenID: OverlayPanel] = [:]
    private var isVisible = false

    // オーバーレイを表示
    func show() {
        isVisible = true
        reconcileScreens()
        guard let screen = preferredScreen(for: NSEvent.mouseLocation) else { return }
        _ = panel(for: screen)
    }

    // オーバーレイを非表示
    func hide() {
        isVisible = false
        for panel in panels.values {
            panel.hideOverlay()
        }
        panels.removeAll()
    }

    func screenParametersDidChange() {
        guard isVisible else { return }
        reconcileScreens()
    }

    // 指定位置にクリックリングを表示
    func showClickRing(at screenPoint: NSPoint, color: NSColor, maxRadius: CGFloat) {
        guard let screen = preferredScreen(for: screenPoint) else { return }
        let panel = panel(for: screen)
        guard let contentView = panel.contentView else { return }

        let windowPoint = panel.convertPoint(fromScreen: screenPoint)
        let viewPoint = contentView.convert(windowPoint, from: nil)

        let ringView = ClickRingView(center: viewPoint, color: color, maxRadius: maxRadius)
        contentView.addSubview(ringView)
        ringView.animate()
    }

    private func panel(for screen: NSScreen) -> OverlayPanel {
        let key = screen.cursorHighlightingID

        if let panel = panels[key] {
            panel.move(to: screen)
            return panel
        }

        let panel = OverlayPanel(screen: screen, overlayLevel: .screenSaver)
        let contentView = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        contentView.autoresizingMask = [.width, .height]
        panel.contentView = contentView
        panel.showFullScreen()
        panels[key] = panel
        return panel
    }

    private func reconcileScreens() {
        let screensByID = Dictionary(
            uniqueKeysWithValues: NSScreen.screens.map { ($0.cursorHighlightingID, $0) })
        let reconciliation = ScreenReconciliation(
            existing: Set(panels.keys),
            current: Set(screensByID.keys)
        )

        for key in reconciliation.removed {
            panels.removeValue(forKey: key)?.hideOverlay()
        }

        for key in reconciliation.retained {
            if let screen = screensByID[key] {
                panels[key]?.move(to: screen)
            }
        }
    }

    private func preferredScreen(for point: NSPoint) -> NSScreen? {
        NSScreen.containing(point) ?? NSScreen.main ?? NSScreen.screens.first
    }
}
