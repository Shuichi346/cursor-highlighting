import AppKit

// NSEventモニターからAsyncStreamへのブリッジ型
struct BridgedMouseEvent: Sendable {
    let locationInScreen: CGPoint
    let type: NSEvent.EventType
}

// マウスイベントのAsyncStreamを生成するファクトリ関数
@MainActor
func createMouseEventStream(
    matching mask: NSEvent.EventTypeMask
) -> (stream: AsyncStream<BridgedMouseEvent>, cancel: @Sendable () -> Void) {
    let (stream, continuation) = AsyncStream.makeStream(
        of: BridgedMouseEvent.self,
        bufferingPolicy: .bufferingNewest(128)
    )

    // グローバルモニター（他アプリがフォーカス時）
    let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
        let location = NSEvent.mouseLocation
        let bridged = BridgedMouseEvent(
            locationInScreen: CGPoint(x: location.x, y: location.y),
            type: event.type
        )
        continuation.yield(bridged)
    }

    // ローカルモニター（自アプリがフォーカス時）
    let localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
        let location = NSEvent.mouseLocation
        let bridged = BridgedMouseEvent(
            locationInScreen: CGPoint(x: location.x, y: location.y),
            type: event.type
        )
        continuation.yield(bridged)
        return event
    }

    // キャンセルクロージャ
    let cancel: @Sendable () -> Void = {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        continuation.finish()
    }

    return (stream, cancel)
}
