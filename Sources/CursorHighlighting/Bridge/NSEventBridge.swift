import AppKit

// NSEventモニターからAsyncStreamへのブリッジ型
struct BridgedMouseEvent: Sendable {
    let locationInScreen: CGPoint
    let type: NSEvent.EventType
}

// NSEventモニターを@Sendableクロージャに安全に渡すためのボックス型
final class MonitorBox: @unchecked Sendable {
    let globalMonitor: Any?
    let localMonitor: Any?
    init(global: Any?, local: Any?) {
        self.globalMonitor = global
        self.localMonitor = local
    }
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

    // モニター参照をSendableなボックスに格納
    let monitors = MonitorBox(global: globalMonitor, local: localMonitor)

    // キャンセルクロージャ
    let cancel: @Sendable () -> Void = {
        if let global = monitors.globalMonitor {
            NSEvent.removeMonitor(global)
        }
        if let local = monitors.localMonitor {
            NSEvent.removeMonitor(local)
        }
        continuation.finish()
    }

    return (stream, cancel)
}
