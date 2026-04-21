import AppKit

@MainActor
extension NSScreen {
    static func containing(_ point: NSPoint) -> NSScreen? {
        screens.first { $0.frame.insetBy(dx: -1, dy: -1).contains(point) }
            ?? screens.min {
                $0.frame.distanceSquared(to: point) < $1.frame.distanceSquared(to: point)
            }
    }
}

extension NSRect {
    fileprivate func distanceSquared(to point: NSPoint) -> CGFloat {
        let dx: CGFloat
        if point.x < minX {
            dx = minX - point.x
        } else if point.x > maxX {
            dx = point.x - maxX
        } else {
            dx = 0
        }

        let dy: CGFloat
        if point.y < minY {
            dy = minY - point.y
        } else if point.y > maxY {
            dy = point.y - maxY
        } else {
            dy = 0
        }

        return (dx * dx) + (dy * dy)
    }
}
