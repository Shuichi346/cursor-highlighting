import AppKit
import Defaults

// クリックリング表示用のオーバーレイウィンドウ
@MainActor
final class ClickOverlayWindow {
    private var panel: OverlayPanel?

    // オーバーレイを表示
    func show() {
        let newPanel = OverlayPanel(overlayLevel: .screenSaver)
        newPanel.contentView = NSView(frame: newPanel.frame)
        newPanel.showFullScreen()
        self.panel = newPanel
    }

    // オーバーレイを非表示
    func hide() {
        panel?.hideOverlay()
        panel = nil
    }

    // 指定位置にクリックリングを表示
    func showClickRing(at screenPoint: NSPoint, color: NSColor, maxRadius: CGFloat) {
        guard let panel = panel, let contentView = panel.contentView else { return }

        // スクリーン座標をパネルのコンテンツビュー座標に変換
        let panelFrame = panel.frame
        let viewPoint = NSPoint(
            x: screenPoint.x - panelFrame.origin.x,
            y: screenPoint.y - panelFrame.origin.y
        )

        let ringView = ClickRingView(center: viewPoint, color: color, maxRadius: maxRadius)
        contentView.addSubview(ringView)
        ringView.animate()
    }
}
