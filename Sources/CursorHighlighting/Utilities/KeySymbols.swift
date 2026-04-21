import Carbon
import CoreGraphics

// キーコードからディスプレイ文字列への変換ユーティリティ
enum KeySymbol {
    private static let modifierOnlyKeyCodes: Set<Int64> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]

    // 修飾キーフラグからmacOS標準の記号文字列を生成
    static func modifierSymbols(from flags: CGEventFlags) -> String {
        var result = ""
        if flags.contains(.maskControl) { result += "⌃" }
        if flags.contains(.maskAlternate) { result += "⌥" }
        if flags.contains(.maskShift) { result += "⇧" }
        if flags.contains(.maskCommand) { result += "⌘" }
        if flags.contains(.maskAlphaShift) { result += "⇪" }
        if flags.contains(.maskSecondaryFn) { result += "fn" }
        return result
    }

    // 特殊キー（配列非依存）のマッピング
    private static let specialKeyMapping: [Int64: String] = [
        // 制御キー
        36: "↩", 48: "⇥", 49: "␣", 51: "⌫", 53: "⎋",
        76: "⌅", 52: "⌅",
        // 矢印キー
        123: "←", 124: "→", 125: "↓", 126: "↑",
        // ファンクションキー
        122: "F1", 120: "F2", 99: "F3", 118: "F4",
        96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12",
        // F13〜F20
        105: "F13", 107: "F14", 113: "F15", 106: "F16",
        64: "F17", 79: "F18", 80: "F19", 90: "F20",
        // ナビゲーション・編集キー
        117: "⌦", 114: "Help", 115: "↖", 119: "↘",
        116: "⇞", 121: "⇟",
        // テンキー
        71: "Clear",
        75: "÷", 67: "×", 78: "−", 69: "+",
        81: "=", 65: ".",
        82: "0", 83: "1", 84: "2", 85: "3",
        86: "4", 87: "5", 88: "6", 89: "7",
        91: "8", 92: "9",
        // JIS固有キー
        102: "英数", 104: "かな",
    ]

    // UCKeyTranslateを使い、現在のキーボードレイアウトからキーコードを文字に変換
    private static func characterFromKeyboard(_ keyCode: Int64) -> String? {
        // 日本語IME等ではTISCopyCurrentKeyboardInputSourceがレイアウトデータを持たないため、
        // TISCopyCurrentKeyboardLayoutInputSourceを使用する
        let inputSource = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        guard
            let layoutDataPtr = TISGetInputSourceProperty(
                inputSource, kTISPropertyUnicodeKeyLayoutData)
        else {
            return nil
        }
        let layoutData = unsafeBitCast(layoutDataPtr, to: CFData.self)
        let keyboardLayoutPtr = unsafeBitCast(
            CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)

        var deadKeyState: UInt32 = 0
        var actualStringLength = 0
        var unicodeString = [UniChar](repeating: 0, count: 4)

        let status = UCKeyTranslate(
            keyboardLayoutPtr,
            UInt16(keyCode),
            UInt16(kUCKeyActionDown),
            0,
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            unicodeString.count,
            &actualStringLength,
            &unicodeString
        )

        guard status == noErr, actualStringLength > 0 else { return nil }

        let result = String(utf16CodeUnits: unicodeString, count: actualStringLength)

        // 制御文字は表示不可なのでnilを返す
        if let scalar = result.unicodeScalars.first,
            scalar.value < 0x20 || scalar.value == 0x7F
        {
            return nil
        }

        return result.uppercased()
    }

    // キーコードからキー名を取得（CGEventの文字列、キーボードレイアウト、フォールバックの順で解決）
    static func keyName(from keyCode: Int64, characters: String = "") -> String {
        // 特殊キーは配列に依存しないため固定テーブルから返す
        if let special = specialKeyMapping[keyCode] {
            return special
        }

        // CGEventから取得した文字列を最優先で使用（最も正確）
        if !characters.isEmpty {
            let trimmed = characters.trimmingCharacters(in: .controlCharacters)
            if !trimmed.isEmpty {
                return trimmed.uppercased()
            }
        }

        // UCKeyTranslateによるキーボードレイアウト対応変換
        if let character = characterFromKeyboard(keyCode) {
            return character
        }

        // 最終フォールバック: US QWERTYテーブル
        return usQwertyFallback[keyCode] ?? "?"
    }

    // 修飾キー＋キーコードから表示用文字列を生成
    static func displayString(keyCode: Int64, modifiers: CGEventFlags, characters: String = "")
        -> String
    {
        let mods = modifierSymbols(from: modifiers)
        if modifierOnlyKeyCodes.contains(keyCode) {
            return mods
        }

        let key = keyName(from: keyCode, characters: characters)
        return mods + key
    }

    // US QWERTYフォールバックテーブル（UCKeyTranslateも失敗した場合の最終手段）
    private static let usQwertyFallback: [Int64: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H",
        5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3",
        21: "4", 22: "6", 23: "5", 24: "=", 25: "9",
        26: "7", 27: "-", 28: "8", 29: "0", 30: "]",
        31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";",
        42: "\\", 43: ",", 44: "/", 45: "N", 46: "M",
        47: ".", 50: "`",
    ]
}
