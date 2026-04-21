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
// Continuationはスレッドセーフ（yieldはどのスレッドからでも安全に呼べる）
// @unchecked Sendableはこのアプリケーション全体で唯一ここだけ使用
final class EventTapContext: @unchecked Sendable {
    let continuation: AsyncStream<BridgedKeyEvent>.Continuation
    var eventTap: CFMachPort?

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
    private let lock = NSLock()
    private var isCancelled = false

    init(eventTap: CFMachPort, runLoopSource: CFRunLoopSource, pointerBits: Int) {
        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        self.pointerBits = pointerBits
    }

    func cancel(_ continuation: AsyncStream<BridgedKeyEvent>.Continuation) {
        lock.lock()
        defer { lock.unlock() }

        guard !isCancelled else { return }
        isCancelled = true

        CGEvent.tapEnable(tap: eventTap, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)

        let ptr = UnsafeMutableRawPointer(bitPattern: pointerBits)!
        Unmanaged<EventTapContext>.fromOpaque(ptr).release()
        continuation.finish()
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
func createKeyEventStream() -> (stream: AsyncStream<BridgedKeyEvent>, cancel: @Sendable () -> Void)?
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

    // 非Sendable型をSendableボックスに格納してキャプチャ
    let tapBox = EventTapBox(
        eventTap: eventTap,
        runLoopSource: runLoopSource,
        pointerBits: Int(bitPattern: pointer)
    )

    // キャンセル時のクリーンアップクロージャ
    let cancel: @Sendable () -> Void = {
        tapBox.cancel(continuation)
    }

    return (stream, cancel)
}
