import AppKit
import CoreGraphics

// スポットライトエフェクトを描画するカスタムNSView
@MainActor
final class SpotlightOverlayView: NSView {
    private var cursorPosition: NSPoint?
    private var spotlightRadius: CGFloat = 30
    private var blurRadius: CGFloat = 0
    private var overlayOpacity: CGFloat = 0
    private var spotlightColor = NSColor(
        srgbRed: 1.0,
        green: 0.0,
        blue: 0.0,
        alpha: 0.5
    )
    private var dimmingGradient: CGGradient?

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func configure(
        spotlightRadius: CGFloat,
        blurRadius: CGFloat,
        overlayOpacity: CGFloat,
        spotlightColor: NSColor
    ) {
        self.spotlightRadius = max(0, spotlightRadius)
        self.blurRadius = max(0, blurRadius)
        self.overlayOpacity = min(max(0, overlayOpacity), 1)
        self.spotlightColor = spotlightColor
        rebuildDimmingGradient()
        needsDisplay = true
    }

    func setCursorPosition(_ position: NSPoint?) {
        guard cursorPosition != position else { return }
        cursorPosition = position
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.saveGState()
        defer { context.restoreGState() }
        context.clip(to: dirtyRect)

        guard let cursorPosition else {
            if overlayOpacity > 0 {
                context.setFillColor(NSColor.black.withAlphaComponent(overlayOpacity).cgColor)
                context.fill(bounds)
            }
            return
        }

        if overlayOpacity > 0 {
            if blurRadius > 0, let dimmingGradient {
                context.drawRadialGradient(
                    dimmingGradient,
                    startCenter: cursorPosition,
                    startRadius: spotlightRadius,
                    endCenter: cursorPosition,
                    endRadius: spotlightRadius + blurRadius,
                    options: .drawsAfterEndLocation
                )
            } else {
                let path = CGMutablePath()
                path.addRect(bounds)
                path.addEllipse(
                    in: CGRect(
                        x: cursorPosition.x - spotlightRadius,
                        y: cursorPosition.y - spotlightRadius,
                        width: spotlightRadius * 2,
                        height: spotlightRadius * 2
                    ))

                context.setFillColor(NSColor.black.withAlphaComponent(overlayOpacity).cgColor)
                context.addPath(path)
                context.fillPath(using: .evenOdd)
            }
        }

        let convertedColor = spotlightColor.usingColorSpace(.sRGB) ?? spotlightColor
        if convertedColor.alphaComponent > 0 {
            context.setFillColor(convertedColor.cgColor)
            context.fillEllipse(
                in: CGRect(
                    x: cursorPosition.x - spotlightRadius,
                    y: cursorPosition.y - spotlightRadius,
                    width: spotlightRadius * 2,
                    height: spotlightRadius * 2
                ))
        }
    }

    private func rebuildDimmingGradient() {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            dimmingGradient = nil
            return
        }

        let progress: [CGFloat] = [0, 0.25, 0.5, 0.75, 1]
        let colors = progress.map { value in
            NSColor.black.withAlphaComponent(overlayOpacity * value * value).cgColor
        } as CFArray
        dimmingGradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors,
            locations: progress
        )
    }
}
