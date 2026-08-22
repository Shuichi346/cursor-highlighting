import Testing
@testable import CursorHighlighting

@MainActor
@Test("Input Monitoring state changes are refreshed without prompting")
func refreshInputMonitoringState() {
    var isGranted = false
    var observedStates: [Bool] = []
    let manager = PermissionManager(
        authorization: InputMonitoringAuthorization(
            preflight: { isGranted },
            request: {
                Issue.record("Refresh must not request permission")
                return false
            }
        )
    )
    manager.onAuthorizationChange = { observedStates.append($0) }

    #expect(manager.refreshInputMonitoringStatus() == false)
    isGranted = true
    #expect(manager.refreshInputMonitoringStatus() == true)
    isGranted = false
    #expect(manager.refreshInputMonitoringStatus() == false)
    #expect(observedStates == [true, false])
}

@MainActor
@Test("Input Monitoring is requested only through the explicit request path")
func requestInputMonitoring() {
    var requestCount = 0
    let manager = PermissionManager(
        authorization: InputMonitoringAuthorization(
            preflight: { false },
            request: {
                requestCount += 1
                return true
            }
        )
    )

    manager.requestInputMonitoring()

    #expect(requestCount == 1)
    #expect(manager.isInputMonitoringGranted)
}
