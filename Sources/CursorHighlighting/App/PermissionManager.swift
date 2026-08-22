import AppKit
import CoreGraphics

struct InputMonitoringAuthorization {
    let preflight: () -> Bool
    let request: () -> Bool

    @MainActor static let live = Self(
        preflight: { CGPreflightListenEventAccess() },
        request: { CGRequestListenEventAccess() }
    )
}

// 入力監視権限の確認・要求を行うマネージャー
@MainActor
@Observable
final class PermissionManager {
    private(set) var isInputMonitoringGranted = false
    var onAuthorizationChange: ((Bool) -> Void)?
    private var pollTask: Task<Void, Never>?
    private let authorization: InputMonitoringAuthorization

    init(authorization: InputMonitoringAuthorization = .live) {
        self.authorization = authorization
    }

    @discardableResult
    func refreshInputMonitoringStatus() -> Bool {
        updateStatus(authorization.preflight())
        return isInputMonitoringGranted
    }

    func requestInputMonitoring() {
        let granted = authorization.request() || authorization.preflight()
        updateStatus(granted)

        guard !granted else {
            stopPolling()
            return
        }
        startPolling()
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                guard let self = self else { break }
                if self.authorization.preflight() {
                    self.updateStatus(true)
                    self.pollTask = nil
                    break
                }
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func updateStatus(_ isGranted: Bool) {
        guard isInputMonitoringGranted != isGranted else { return }
        isInputMonitoringGranted = isGranted
        onAuthorizationChange?(isGranted)
    }
}
