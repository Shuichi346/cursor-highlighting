import AppKit
import Defaults

// クリックリング表示用のオーバーレイウィンドウ
@MainActor
final class ClickOverlayWindow {
    private var panels: [ObjectIdentifier: OverlayPanel] = [:]

    // オーバーレイを表示
    func show() {
        guard let screen = preferredScreen(for: NSEvent.mouseLocation) else { return }
        _ = panel(for: screen)
    }

    // オーバーレイを非表示
    func hide() {
        for panel in panels.values {
            panel.hideOverlay()
        }
        panels.removeAll()
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
        let key = ObjectIdentifier(screen)

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

    private func preferredScreen(for point: NSPoint) -> NSScreen? {
        NSScreen.containing(point) ?? NSScreen.main ?? NSScreen.screens.first
    }
}
