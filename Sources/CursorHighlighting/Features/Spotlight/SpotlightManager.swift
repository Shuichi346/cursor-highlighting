import AppKit
import Defaults
import KeyboardShortcuts

// スポットライト機能のオーケストレーター
@MainActor
@Observable
final class SpotlightManager {
    private let overlayWindow = SpotlightOverlayWindow()
    private(set) var isActive = false
    private var observationTask: Task<Void, Never>?

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

    // Defaults変更を監視してアクティブ状態と設定を反映
    private func startObserving() {
        observationTask = Task { [weak self] in
            for await enabled in Defaults.updates(.spotlightEnabled) {
                if enabled {
                    self?.activate()
                } else {
                    self?.deactivate()
                }
            }
        }

        // 個別設定の変更監視
        Task { [weak self] in
            for await _ in Defaults.updates(.spotlightRadius) {
                self?.overlayWindow.updateSettings()
            }
        }
        Task { [weak self] in
            for await _ in Defaults.updates(.spotlightBlur) {
                self?.overlayWindow.updateSettings()
            }
        }
        Task { [weak self] in
            for await _ in Defaults.updates(.spotlightOpacity) {
                self?.overlayWindow.updateSettings()
            }
        }
        Task { [weak self] in
            for await _ in Defaults.updates(.spotlightColor) {
                self?.overlayWindow.updateSettings()
            }
        }
    }
}
