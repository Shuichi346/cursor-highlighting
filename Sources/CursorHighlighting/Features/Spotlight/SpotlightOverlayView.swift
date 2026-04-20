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
            // Even-Oddフィルルールでスポットライト切り抜きを描画
            let path = CGMutablePath()
            path.addRect(bounds)
            path.addEllipse(in: circleRect)

            context.setFillColor(NSColor.black.withAlphaComponent(overlayOpacity).cgColor)
            context.addPath(path)
            context.fillPath(using: .evenOdd)
        }

        // ぼかしエフェクト: 円の境界にグラデーションリングを描画
        if blurRadius > 0 && overlayOpacity > 0 {
            let gradientSteps = 20
            for i in 0..<gradientSteps {
                let progress = CGFloat(i) / CGFloat(gradientSteps)
                let currentRadius = spotlightRadius + (blurRadius * progress)
                let alpha = overlayOpacity * progress * 0.5

                let ringRect = CGRect(
                    x: cursorPosition.x - currentRadius,
                    y: cursorPosition.y - currentRadius,
                    width: currentRadius * 2,
                    height: currentRadius * 2
                )

                context.setStrokeColor(NSColor.black.withAlphaComponent(alpha).cgColor)
                context.setLineWidth(blurRadius / CGFloat(gradientSteps))
                context.strokeEllipse(in: ringRect)
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
