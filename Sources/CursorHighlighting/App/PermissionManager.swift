import AppKit
import ApplicationServices

// アクセシビリティ権限の確認・要求を行うマネージャー
@MainActor
@Observable
final class PermissionManager {
    var isAccessibilityGranted: Bool = false
    private var pollTask: Task<Void, Never>?

    // アクセシビリティ権限を確認し、未付与なら要求
    func checkAndRequestAccessibility() {
        isAccessibilityGranted = AXIsProcessTrusted()

        guard !isAccessibilityGranted else {
            stopPolling()
            return
        }

        // Swift 6ではkAXTrustedCheckOptionPromptが可変グローバル変数として扱われるため、定数文字列を直接使用
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        startPolling()
    }

    // 権限が付与されるまで定期的にポーリング
    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self = self else { break }
                if AXIsProcessTrusted() {
                    self.isAccessibilityGranted = true
                    self.pollTask = nil
                    break
                }
            }
        }
    }

    // ポーリングを停止
    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}
