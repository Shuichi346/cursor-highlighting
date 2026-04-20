import AppKit
import Defaults
import KeyboardShortcuts

// スポットライト機能のオーケストレーター
@MainActor
@Observable
final class SpotlightManager {
    private let overlayWindow = SpotlightOverlayWindow()
    private(set) var isActive = false
    private var observationTasks: [Task<Void, Never>] = []

    init() {
        // ホットキー登録
        KeyboardShortcuts.onKeyUp(for: .toggleSpotlight) { [weak self] in
            self?.toggle()
        }

        // 設定変更の監視を開始
        startObserving()
    }

    // トグル操作
    func toggle() {
        Defaults[.spotlightEnabled].toggle()
    }

    // 有効化
    private func activate() {
        guard !isActive else { return }
        isActive = true
        overlayWindow.show()
    }

    // 無効化
    private func deactivate() {
        guard isActive else { return }
        isActive = false
        overlayWindow.hide()
    }

    func shutdown() {
        observationTasks.forEach { $0.cancel() }
        observationTasks.removeAll()
        deactivate()
    }

    // Defaults変更を監視してアクティブ状態と設定を反映
    private func startObserving() {
        applyEnabledState(Defaults[.spotlightEnabled])

        observationTasks.append(Task { [weak self] in
            for await enabled in Defaults.updates(.spotlightEnabled, initial: false) {
                self?.applyEnabledState(enabled)
            }
        })

        // 個別設定の変更監視
        observationTasks.append(Task { [weak self] in
            for await _ in Defaults.updates(.spotlightRadius, initial: false) {
                self?.overlayWindow.updateSettings()
            }
        })
        observationTasks.append(Task { [weak self] in
            for await _ in Defaults.updates(.spotlightBlur, initial: false) {
                self?.overlayWindow.updateSettings()
            }
        })
        observationTasks.append(Task { [weak self] in
            for await _ in Defaults.updates(.spotlightOpacity, initial: false) {
                self?.overlayWindow.updateSettings()
            }
        })
        observationTasks.append(Task { [weak self] in
            for await _ in Defaults.updates(.spotlightColor, initial: false) {
                self?.overlayWindow.updateSettings()
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
