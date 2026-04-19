import AppKit
import CoreGraphics

// スポットライトエフェクトを描画するカスタムNSView
@MainActor
final class SpotlightOverlayView: NSView {
    // カーソル位置（ビュー座標系、左上原点）
    var cursorPosition: NSPoint = .zero {
        didSet { needsDisplay = true }
    }
    var spotlightRadius: CGFloat = 150
    var blurRadius: CGFloat = 30
    var overlayOpacity: CGFloat = 0.5
    var spotlightColor: NSColor = .white

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Even-Oddフィルルールでスポットライト切り抜きを描画
        let path = CGMutablePath()
        // 外枠（ビュー全体）
        path.addRect(bounds)
        // 内側の楕円（カーソル位置を中心とした円）
        let circleRect = CGRect(
            x: cursorPosition.x - spotlightRadius,
            y: cursorPosition.y - spotlightRadius,
            width: spotlightRadius * 2,
            height: spotlightRadius * 2
        )
        path.addEllipse(in: circleRect)

        // 暗幕を描画（円の部分は切り抜かれる）
        context.setFillColor(NSColor.black.withAlphaComponent(overlayOpacity).cgColor)
        context.addPath(path)
        context.fillPath(using: .evenOdd)

        // ぼかしエフェクト: 円の境界にグラデーションリングを描画
        if blurRadius > 0 {
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

        // スポットライトカラーが白でない場合、円内に微妙なカラーティントを追加
        if spotlightColor != .white {
            let tintColor = spotlightColor.withAlphaComponent(0.15)
            context.setFillColor(tintColor.cgColor)
            context.fillEllipse(in: circleRect)
        }
    }
}
