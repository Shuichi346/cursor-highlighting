import AppKit

// 全画面透過オーバーレイ用の共有NSPanelサブクラス
@MainActor
final class OverlayPanel: NSPanel {
    init(overlayLevel: NSWindow.Level = .screenSaver) {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.level = overlayLevel
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // 全画面で表示
    func showFullScreen() {
        let screenFrame = NSScreen.main?.frame ?? frame
        setFrame(screenFrame, display: true)
        orderFrontRegardless()
    }

    // 非表示
    func hideOverlay() {
        orderOut(nil)
    }
}
