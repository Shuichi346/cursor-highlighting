import AppKit
import Defaults
import SwiftUI

// Defaults互換のCodable対応カラー型
struct CodableColor: Codable, Sendable, Equatable, Defaults.Serializable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    // NSColorから生成
    init(nsColor: NSColor) {
        let converted = nsColor.usingColorSpace(.sRGB) ?? nsColor
        self.red = Double(converted.redComponent)
        self.green = Double(converted.greenComponent)
        self.blue = Double(converted.blueComponent)
        self.alpha = Double(converted.alphaComponent)
    }

    // 直接値から生成
    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    // NSColorへ変換
    var nsColor: NSColor {
        NSColor(
            srgbRed: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha)
        )
    }

    // SwiftUI Colorへ変換
    var color: Color {
        Color(nsColor: nsColor)
    }

    // Hex文字列を返す（UI表示用）
    var hexString: String {
        String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }

    // Hex文字列からパース（"#RRGGBB" 形式）
    static func fromHex(_ hex: String) -> CodableColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else {
            return CodableColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        }

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return CodableColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        return CodableColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    // デフォルトカラー定義
    static let blue = CodableColor.fromHex("#007AFF")
    static let red = CodableColor.fromHex("#FF3B30")
    static let spotlightDefault = CodableColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
}
