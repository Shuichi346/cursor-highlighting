@preconcurrency import CoreFoundation
@preconcurrency import CoreGraphics
import Foundation

// CGEventTapコールバックからAsyncStreamへの安全なブリッジ型
struct BridgedKeyEvent: Sendable {
    let keyCode: Int64
    let flags: CGEventFlags
    let type: CGEventType
    // CGEventから直接取得したUnicode文字列（キーボードレイアウト反映済み）
    let characters: String
}

// AsyncStream.ContinuationをCコールバックに渡すためのボックス型
// Cコールバック境界に限定して安全性を管理する
final class EventTapContext: @unchecked Sendable {
    let continuation: AsyncStream<BridgedKeyEvent>.Continuation
    var eventTap: CFMachPort?

    init(_ continuation: AsyncStream<BridgedKeyEvent>.Continuation) {
        self.continuation = continuation
    }
}

// CGEventからUnicode文字列を抽出する
private func extractCharacters(from event: CGEvent) -> String {
    var length = 0
    // まず文字列長を取得
    event.keyboardGetUnicodeString(
        maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
    guard length > 0 else { return "" }
    var chars = [UniChar](repeating: 0, count: length)
    event.keyboardGetUnicodeString(
        maxStringLength: length, actualStringLength: &length, unicodeString: &chars)
    return String(utf16CodeUnits: chars, count: length)
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

    let context = Unmanaged<EventTapContext>.fromOpaque(userInfo).takeUnretainedValue()

    // タップが一時的に無効化された場合は再有効化
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let eventTap = context.eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    // keyDownイベントのみ処理
    if type == .keyDown {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let characters = extractCharacters(from: event)
        let bridgedEvent = BridgedKeyEvent(
            keyCode: keyCode, flags: flags, type: type, characters: characters)
        context.continuation.yield(bridgedEvent)
    }

    return Unmanaged.passUnretained(event)
}

// キーイベントのAsyncStreamを生成するファクトリ関数
// 戻り値がnilの場合はアクセシビリティ権限が未付与
@MainActor
func createKeyEventStream() -> (
    stream: AsyncStream<BridgedKeyEvent>,
    cancel: @MainActor () -> Void
)?
{
    let (stream, continuation) = AsyncStream.makeStream(
        of: BridgedKeyEvent.self,
        bufferingPolicy: .bufferingNewest(64)
    )

    let context = EventTapContext(continuation)
    let pointer = Unmanaged.passRetained(context).toOpaque()

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
        Unmanaged<EventTapContext>.fromOpaque(pointer).release()
        continuation.finish()
        return nil
    }

    context.eventTap = eventTap

    // メインRunLoopに追加
    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)!
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)

    // イベントタップはメインRunLoop上にあるため、同じMainActorから破棄する
    var isCancelled = false
    let cancel: @MainActor @Sendable () -> Void = {
        guard !isCancelled else { return }
        isCancelled = true
        CGEvent.tapEnable(tap: eventTap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        Unmanaged<EventTapContext>.fromOpaque(pointer).release()
        continuation.finish()
    }

    return (stream, cancel)
}
