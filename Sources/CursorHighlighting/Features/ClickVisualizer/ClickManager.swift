import AppKit
import Defaults
import KeyboardShortcuts

// クリック可視化機能のマネージャー
@MainActor
@Observable
final class ClickManager {
    private let overlayWindow = ClickOverlayWindow()
    private var clickStreamCancel: (@Sendable () -> Void)?
    private var consumeTask: Task<Void, Never>?
    private(set) var isActive = false
    private var observationTask: Task<Void, Never>?

    init() {
        // ホットキー登録
        KeyboardShortcuts.onKeyUp(for: .toggleClicks) { [weak self] in
            Defaults[.clickEnabled].toggle()
        }

        // 設定変更の監視を開始
        startObserving()
    }

    // 有効化
    func activate() {
        guard !isActive else { return }
        isActive = true
        overlayWindow.show()

        // クリックイベントストリームを作成
        let (stream, cancel) = createMouseEventStream(
            matching: [.leftMouseDown, .rightMouseDown]
        )
        clickStreamCancel = cancel

        // クリックイベントを消費
        consumeTask = Task { [weak self] in
            for await event in stream {
                guard let self = self else { break }
                switch event.type {
                case .leftMouseDown:
                    self.overlayWindow.showClickRing(
                        at: NSPoint(x: event.locationInScreen.x, y: event.locationInScreen.y),
                        color: Defaults[.leftClickColor].nsColor,
                        maxRadius: CGFloat(Defaults[.clickRingMaxRadius])
                    )
                case .rightMouseDown:
                    self.overlayWindow.showClickRing(
                        at: NSPoint(x: event.locationInScreen.x, y: event.locationInScreen.y),
                        color: Defaults[.rightClickColor].nsColor,
                        maxRadius: CGFloat(Defaults[.clickRingMaxRadius])
                    )
                default:
                    break
                }
            }
        }
    }

    // 無効化
    func deactivate() {
        guard isActive else { return }
        consumeTask?.cancel()
        consumeTask = nil
        clickStreamCancel?()
        clickStreamCancel = nil
        overlayWindow.hide()
        isActive = false
    }

    // Defaults変更の監視
    private func startObserving() {
        observationTask = Task { [weak self] in
            for await enabled in Defaults.updates(.clickEnabled) {
                if enabled {
                    self?.activate()
                } else {
                    self?.deactivate()
                }
            }
        }
    }
}
