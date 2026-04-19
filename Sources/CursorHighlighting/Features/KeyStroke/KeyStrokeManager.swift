import AppKit
import Defaults
import KeyboardShortcuts

// キーストローク表示機能のマネージャー
@MainActor
@Observable
final class KeyStrokeManager {
    private let overlayWindow = KeyStrokeOverlayWindow()
    private var eventStreamCancel: (@Sendable () -> Void)?
    private var consumeTask: Task<Void, Never>?
    private(set) var isActive = false
    private var observationTask: Task<Void, Never>?

    init() {
        // ホットキー登録
        KeyboardShortcuts.onKeyUp(for: .toggleKeyStrokes) {
            Defaults[.keyStrokeEnabled].toggle()
        }

        // 設定変更の監視を開始
        startObserving()
    }

    // 有効化
    func activate() {
        guard !isActive else { return }

        // CGEventTap AsyncStreamを作成（アクセシビリティ権限が必要）
        guard let (stream, cancel) = createKeyEventStream() else {
            // 権限未付与の場合はリトライせず待機
            return
        }

        isActive = true
        overlayWindow.show()
        eventStreamCancel = cancel

        // キーイベントを消費してHUDに表示
        consumeTask = Task { [weak self] in
            for await event in stream {
                guard let self = self else { break }
                let displayString = KeySymbol.displayString(
                    keyCode: event.keyCode,
                    modifiers: event.flags
                )
                self.overlayWindow.addEntry(displayString)
            }
        }
    }

    // 無効化
    func deactivate() {
        guard isActive else { return }
        consumeTask?.cancel()
        consumeTask = nil
        eventStreamCancel?()
        eventStreamCancel = nil
        overlayWindow.hide()
        isActive = false
    }

    // Defaults変更の監視
    private func startObserving() {
        observationTask = Task { [weak self] in
            for await enabled in Defaults.updates(.keyStrokeEnabled) {
                if enabled {
                    self?.activate()
                } else {
                    self?.deactivate()
                }
            }
        }
    }
}
