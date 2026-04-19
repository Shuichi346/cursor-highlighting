@preconcurrency import CoreFoundation
@preconcurrency import CoreGraphics
import Foundation

// CGEventTapコールバックからAsyncStreamへの安全なブリッジ型
struct BridgedKeyEvent: Sendable {
    let keyCode: Int64
    let flags: CGEventFlags
    let type: CGEventType
}

// AsyncStream.ContinuationをCコールバックに渡すためのボックス型
// Continuationはスレッドセーフ（yieldはどのスレッドからでも安全に呼べる）
// @unchecked Sendableはこのアプリケーション全体で唯一ここだけ使用
final class ContinuationBox: @unchecked Sendable {
    let continuation: AsyncStream<BridgedKeyEvent>.Continuation
    init(_ continuation: AsyncStream<BridgedKeyEvent>.Continuation) {
        self.continuation = continuation
    }
}

// CGEventTap関連のCFオブジェクトを@Sendableクロージャに安全に渡すためのボックス型
// CFMachPort・CFRunLoopSourceは実質スレッドセーフだがSendable準拠がない
final class EventTapBox: @unchecked Sendable {
    let eventTap: CFMachPort
    let runLoopSource: CFRunLoopSource
    let pointerBits: Int

    init(eventTap: CFMachPort, runLoopSource: CFRunLoopSource, pointerBits: Int) {
        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        self.pointerBits = pointerBits
    }
}

// Cコンベンションのイベントタップコールバック
private func cgEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    // タップが無効化された場合は再有効化
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        return Unmanaged.passUnretained(event)
    }

    // keyDownイベントのみ処理
    if type == .keyDown {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let bridgedEvent = BridgedKeyEvent(keyCode: keyCode, flags: flags, type: type)

        let box = Unmanaged<ContinuationBox>.fromOpaque(userInfo).takeUnretainedValue()
        box.continuation.yield(bridgedEvent)
    }

    return Unmanaged.passUnretained(event)
}

// キーイベントのAsyncStreamを生成するファクトリ関数
// 戻り値がnilの場合はアクセシビリティ権限が未付与
@MainActor
func createKeyEventStream() -> (stream: AsyncStream<BridgedKeyEvent>, cancel: @Sendable () -> Void)?
{
    let (stream, continuation) = AsyncStream.makeStream(
        of: BridgedKeyEvent.self,
        bufferingPolicy: .bufferingNewest(64)
    )

    let box = ContinuationBox(continuation)
    let pointer = Unmanaged.passRetained(box).toOpaque()

    // keyDownイベントのみをリッスン
    let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

    guard
        let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: cgEventCallback,
            userInfo: pointer
        )
    else {
        // 権限未付与 — Unmanagedを解放してストリームを終了
        Unmanaged<ContinuationBox>.fromOpaque(pointer).release()
        continuation.finish()
        return nil
    }

    // メインRunLoopに追加
    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)!
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)

    // 非Sendable型をSendableボックスに格納してキャプチャ
    let tapBox = EventTapBox(
        eventTap: eventTap,
        runLoopSource: runLoopSource,
        pointerBits: Int(bitPattern: pointer)
    )

    // キャンセル時のクリーンアップクロージャ
    let cancel: @Sendable () -> Void = {
        CGEvent.tapEnable(tap: tapBox.eventTap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), tapBox.runLoopSource, .commonModes)
        let ptr = UnsafeMutableRawPointer(bitPattern: tapBox.pointerBits)!
        Unmanaged<ContinuationBox>.fromOpaque(ptr).release()
        continuation.finish()
    }

    return (stream, cancel)
}
