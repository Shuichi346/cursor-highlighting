import AppKit
import QuartzCore

// クリック時のリングアニメーションを描画するビュー
@MainActor
final class ClickRingView: NSView {
    private let ringLayer = CAShapeLayer()
    private let ringColor: NSColor
    private let maxRadius: CGFloat

    init(center: NSPoint, color: NSColor, maxRadius: CGFloat) {
        self.ringColor = color
        self.maxRadius = maxRadius

        // ビューのフレームをリングの最大サイズに設定
        let size = maxRadius * 2 + 10
        let origin = NSPoint(x: center.x - size / 2, y: center.y - size / 2)
        super.init(frame: NSRect(origin: origin, size: NSSize(width: size, height: size)))

        wantsLayer = true
        setupRingLayer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)は使用不可")
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    // リングレイヤーの初期設定
    private func setupRingLayer() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let initialRadius: CGFloat = 5.0
        let initialPath = CGPath(
            ellipseIn: CGRect(
                x: center.x - initialRadius,
                y: center.y - initialRadius,
                width: initialRadius * 2,
                height: initialRadius * 2
            ),
            transform: nil
        )

        ringLayer.path = initialPath
        ringLayer.strokeColor = ringColor.cgColor
        ringLayer.fillColor = nil
        ringLayer.lineWidth = 3.0
        ringLayer.opacity = 1.0
        layer?.addSublayer(ringLayer)
    }

    // リングのアニメーションを開始
    func animate() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        // 最終パス
        let finalPath = CGPath(
            ellipseIn: CGRect(
                x: center.x - maxRadius,
                y: center.y - maxRadius,
                width: maxRadius * 2,
                height: maxRadius * 2
            ),
            transform: nil
        )

        // パスアニメーション（拡大）
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.toValue = finalPath

        // 透明度アニメーション（フェードアウト）
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.toValue = 0.0

        // 線幅アニメーション（細くなる）
        let lineWidthAnimation = CABasicAnimation(keyPath: "lineWidth")
        lineWidthAnimation.toValue = 1.0

        // アニメーショングループ
        let group = CAAnimationGroup()
        group.animations = [pathAnimation, opacityAnimation, lineWidthAnimation]
        group.duration = 0.4
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards

        ringLayer.add(group, forKey: "ringAnimation")

        // アニメーション完了後にビューを削除
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            self?.removeFromSuperview()
        }
    }
}
