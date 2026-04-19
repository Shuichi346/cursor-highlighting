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

        if !isAccessibilityGranted {
            // システムプロンプトを表示
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            startPolling()
        }
    }

    // 権限が付与されるまで定期的にポーリング
    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                if AXIsProcessTrusted() {
                    self?.isAccessibilityGranted = true
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
