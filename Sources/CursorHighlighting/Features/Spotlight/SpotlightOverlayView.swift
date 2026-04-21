import AppKit
import CoreGraphics

// スポットライトエフェクトを描画するカスタムNSView
@MainActor
final class SpotlightOverlayView: NSView {
    // カーソル位置（ビュー座標系、左上原点）
    var cursorPosition: NSPoint = .zero {
        didSet { needsDisplay = true }
    }
    var spotlightRadius: CGFloat = 30
    var blurRadius: CGFloat = 0
    var overlayOpacity: CGFloat = 0.0
    var spotlightColor: NSColor = NSColor(srgbRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let circleRect = CGRect(
            x: cursorPosition.x - spotlightRadius,
            y: cursorPosition.y - spotlightRadius,
            width: spotlightRadius * 2,
            height: spotlightRadius * 2
        )

        // 背景の暗幕を描画（opacity > 0 の場合のみ）
        if overlayOpacity > 0 {
            if blurRadius > 0 {
                // ぼかしあり: 内側（完全透明）から外側（完全暗幕）へ滑らかに遷移
                let gradientSteps = 30
                for i in 0..<gradientSteps {
                    let progress = CGFloat(i) / CGFloat(gradientSteps)
                    // ぼかし領域の内縁から外縁へ
                    let innerRadius = spotlightRadius + (blurRadius * progress)
                    let outerRadius =
                        spotlightRadius + (blurRadius * (progress + 1.0 / CGFloat(gradientSteps)))
                    // 不透明度は0からoverlayOpacityへ滑らかに増加（イージング適用）
                    let easedProgress = progress * progress
                    let alpha = overlayOpacity * easedProgress

                    let ringPath = CGMutablePath()
                    // 外側の楕円
                    ringPath.addEllipse(
                        in: CGRect(
                            x: cursorPosition.x - outerRadius,
                            y: cursorPosition.y - outerRadius,
                            width: outerRadius * 2,
                            height: outerRadius * 2
                        ))
                    // 内側の楕円（even-oddで切り抜き）
                    ringPath.addEllipse(
                        in: CGRect(
                            x: cursorPosition.x - innerRadius,
                            y: cursorPosition.y - innerRadius,
                            width: innerRadius * 2,
                            height: innerRadius * 2
                        ))

                    context.setFillColor(NSColor.black.withAlphaComponent(alpha).cgColor)
                    context.addPath(ringPath)
                    context.fillPath(using: .evenOdd)
                }

                // ぼかし領域の外側は完全な暗幕
                let outerCutoffRadius = spotlightRadius + blurRadius
                let outerPath = CGMutablePath()
                outerPath.addRect(bounds)
                outerPath.addEllipse(
                    in: CGRect(
                        x: cursorPosition.x - outerCutoffRadius,
                        y: cursorPosition.y - outerCutoffRadius,
                        width: outerCutoffRadius * 2,
                        height: outerCutoffRadius * 2
                    ))

                context.setFillColor(NSColor.black.withAlphaComponent(overlayOpacity).cgColor)
                context.addPath(outerPath)
                context.fillPath(using: .evenOdd)
            } else {
                // ぼかしなし: シャープな切り抜き
                let path = CGMutablePath()
                path.addRect(bounds)
                path.addEllipse(in: circleRect)

                context.setFillColor(NSColor.black.withAlphaComponent(overlayOpacity).cgColor)
                context.addPath(path)
                context.fillPath(using: .evenOdd)
            }
        }

        // スポットライト色を円内に描画（alphaが0より大きい場合）
        let convertedColor = spotlightColor.usingColorSpace(.sRGB) ?? spotlightColor
        if convertedColor.alphaComponent > 0 {
            context.setFillColor(convertedColor.cgColor)
            context.fillEllipse(in: circleRect)
        }
    }
}
