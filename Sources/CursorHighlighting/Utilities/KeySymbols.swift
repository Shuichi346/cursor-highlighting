import CoreGraphics

// キーコードからディスプレイ文字列への変換ユーティリティ
enum KeySymbol {
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

    // キーコードからキー名を取得（US QWERTYレイアウト基準）
    static func keyName(from keyCode: Int64) -> String {
        let mapping: [Int64: String] = [
            // 文字キー
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
            // 特殊キー
            36: "↩", 48: "⇥", 49: "␣", 51: "⌫", 53: "⎋",
            76: "⌅", 52: "⌅",
            // 矢印キー
            123: "←", 124: "→", 125: "↓", 126: "↑",
            // ファンクションキー
            122: "F1", 120: "F2", 99: "F3", 118: "F4",
            96: "F5", 97: "F6", 98: "F7", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12",
            // その他
            117: "⌦", 114: "Help", 115: "↖", 119: "↘",
            116: "⇞", 121: "⇟", 71: "Clear",
        ]
        return mapping[keyCode] ?? "?"
    }

    // 修飾キー＋キーコードから表示用文字列を生成
    static func displayString(keyCode: Int64, modifiers: CGEventFlags) -> String {
        // 修飾キーのみのイベントは除外（keyCodeが有効な場合のみ組み合わせ表示）
        let mods = modifierSymbols(from: modifiers)
        let key = keyName(from: keyCode)
        return mods + key
    }
}
