import AppKit
import Defaults
import KeyboardShortcuts

// クリック可視化機能のマネージャー
@MainActor
@Observable
final class ClickManager {
    private let overlayWindow = ClickOverlayWindow()
    private var clickStreamCancel: (@MainActor () -> Void)?
    private var consumeTask: Task<Void, Never>?
    private(set) var isActive = false
    private var observationTasks: [Task<Void, Never>] = []
    private var didStart = false

    func start() {
        guard !didStart else { return }
        didStart = true

        // ホットキー登録
        KeyboardShortcuts.onKeyUp(for: .toggleClicks) {
            Defaults[.clickEnabled].toggle()
        }

        startObserving()
    }

    // 有効化
    func activate() {
        guard !isActive else { return }
        isActive = true
        overlayWindow.show()

        // クリックイベントストリームを作成
        let (stream, cancel) = createMouseEventStream(
            matching: [.leftMouseDown, .rightMouseDown],
            bufferingNewest: 32
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

    func shutdown() {
        observationTasks.forEach { $0.cancel() }
        observationTasks.removeAll()
        deactivate()
    }

    func screenParametersDidChange() {
        guard isActive else { return }
        overlayWindow.screenParametersDidChange()
    }

    // Defaults変更の監視
    private func startObserving() {
        applyEnabledState(Defaults[.clickEnabled])

        observationTasks.append(
            Task { [weak self] in
                for await enabled in Defaults.updates(.clickEnabled, initial: false) {
                    self?.applyEnabledState(enabled)
                }
            })
    }

    private func applyEnabledState(_ isEnabled: Bool) {
        if isEnabled {
            activate()
        } else {
            deactivate()
        }
    }
}
