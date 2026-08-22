import AppKit
import Defaults
import KeyboardShortcuts

// キーストローク表示機能のマネージャー
@MainActor
@Observable
final class KeyStrokeManager {
    private let overlayWindow = KeyStrokeOverlayWindow()
    private var eventStreamCancel: (@MainActor () -> Void)?
    private var consumeTask: Task<Void, Never>?
    private(set) var isActive = false
    private var observationTasks: [Task<Void, Never>] = []
    private var didStart = false

    func start() {
        guard !didStart else { return }
        didStart = true

        KeyboardShortcuts.onKeyUp(for: .toggleKeyStrokes) {
            Defaults[.keyStrokeEnabled].toggle()
        }

        startObserving()
    }

    // 有効化
    func activate() {
        guard didStart, !isActive else { return }

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
                    modifiers: event.flags,
                    characters: event.characters
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

    func screenParametersDidChange() {
        guard isActive else { return }
        overlayWindow.screenParametersDidChange()
    }

    private func startObserving() {
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

}
