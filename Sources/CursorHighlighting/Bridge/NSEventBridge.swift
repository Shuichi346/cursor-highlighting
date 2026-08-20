import AppKit

// NSEventモニターからAsyncStreamへのブリッジ型
struct BridgedMouseEvent: Sendable {
    let locationInScreen: CGPoint
    let type: NSEvent.EventType
}

func screenLocation(
    eventLocation: CGPoint,
    convertWindowPointToScreen: ((CGPoint) -> CGPoint)?
) -> CGPoint {
    convertWindowPointToScreen?(eventLocation) ?? eventLocation
}

@MainActor
func screenLocation(for event: NSEvent) -> CGPoint {
    screenLocation(
        eventLocation: event.locationInWindow,
        convertWindowPointToScreen: event.window.map { window in
            { window.convertPoint(toScreen: $0) }
        }
    )
}

// マウスイベントのAsyncStreamを生成するファクトリ関数
@MainActor
func createMouseEventStream(
    matching mask: NSEvent.EventTypeMask,
    bufferingNewest limit: Int
) -> (stream: AsyncStream<BridgedMouseEvent>, cancel: @MainActor () -> Void) {
    precondition(limit > 0)
    let (stream, continuation) = AsyncStream.makeStream(
        of: BridgedMouseEvent.self,
        bufferingPolicy: .bufferingNewest(limit)
    )

    // グローバルモニター（他アプリがフォーカス時）
    let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
        let location = screenLocation(for: event)
        let bridged = BridgedMouseEvent(
            locationInScreen: CGPoint(x: location.x, y: location.y),
            type: event.type
        )
        continuation.yield(bridged)
    }

    // ローカルモニター（自アプリがフォーカス時）
    let localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
        let location = screenLocation(for: event)
        let bridged = BridgedMouseEvent(
            locationInScreen: CGPoint(x: location.x, y: location.y),
            type: event.type
        )
        continuation.yield(bridged)
        return event
    }

    // キャンセルクロージャ
    var isCancelled = false
    let cancel: @MainActor @Sendable () -> Void = {
        guard !isCancelled else { return }
        isCancelled = true
        if let global = globalMonitor {
            NSEvent.removeMonitor(global)
        }
        if let local = localMonitor {
            NSEvent.removeMonitor(local)
        }
        continuation.finish()
    }

    return (stream, cancel)
}
