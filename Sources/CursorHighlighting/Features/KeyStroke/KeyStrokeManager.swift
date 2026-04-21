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
    private var observationTasks: [Task<Void, Never>] = []

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleKeyStrokes) {
            Defaults[.keyStrokeEnabled].toggle()
        }

        startObserving()
    }

    // 有効化
    func activate() {
        guard !isActive else { return }

        guard let (stream, cancel) = createKeyEventStream() else {
            return
        }

        isActive = true
        overlayWindow.show()
        eventStreamCancel = cancel

        consumeTask = Task { [weak self] in
            for await event in stream {
                guard let self = self else { break }
                let displayString = KeySymbol.displayString(
                    keyCode: event.keyCode,
                    modifiers: event.flags
                )
                guard !displayString.isEmpty else { continue }
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

    func shutdown() {
        observationTasks.forEach { $0.cancel() }
        observationTasks.removeAll()
        deactivate()
    }

    private func startObserving() {
        applyEnabledState(Defaults[.keyStrokeEnabled])

        observationTasks.append(
            Task { [weak self] in
                for await enabled in Defaults.updates(.keyStrokeEnabled, initial: false) {
                    self?.applyEnabledState(enabled)
                }
            })

        observationTasks.append(
            Task { [weak self] in
                for await _ in Defaults.updates(.keyStrokeFontSize, initial: false) {
                    self?.overlayWindow.updateAppearance()
                }
            })

        // テーマ変更の監視
        observationTasks.append(
            Task { [weak self] in
                for await _ in Defaults.updates(.keyStrokeTheme, initial: false) {
                    self?.overlayWindow.updateAppearance()
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
