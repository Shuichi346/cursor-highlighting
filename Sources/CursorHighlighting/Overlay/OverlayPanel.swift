import AppKit

// 全画面透過オーバーレイ用の共有NSPanelサブクラス
@MainActor
final class OverlayPanel: NSPanel {
    private(set) var currentScreen: NSScreen

    init(screen: NSScreen, overlayLevel: NSWindow.Level = .screenSaver) {
        self.currentScreen = screen
        super.init(
            contentRect: screen.frame,
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

    // 表示対象のスクリーンへ移動
    func move(to screen: NSScreen) {
        currentScreen = screen
        setFrame(screen.frame, display: true)
    }

    // 全画面で表示
    func showFullScreen() {
        setFrame(currentScreen.frame, display: true)
        orderFrontRegardless()
    }

    // 非表示
    func hideOverlay() {
        orderOut(nil)
    }
}
