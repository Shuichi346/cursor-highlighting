import CoreGraphics
import Testing
@testable import CursorHighlighting

@Test("A windowless event keeps its recorded screen location")
func windowlessEventLocation() {
    let recorded = CGPoint(x: 120, y: 340)

    #expect(
        screenLocation(
            eventLocation: recorded,
            convertWindowPointToScreen: nil
        ) == recorded
    )
}

@Test("A window event is converted from window to screen coordinates")
func windowEventLocation() {
    let converted = screenLocation(
        eventLocation: CGPoint(x: 12, y: 34),
        convertWindowPointToScreen: { point in
            CGPoint(x: point.x + 100, y: point.y + 200)
        }
    )

    #expect(converted == CGPoint(x: 112, y: 234))
}

@Test("Screen reconciliation classifies added, removed, and retained displays")
func screenReconciliation() {
    let result = ScreenReconciliation(
        existing: Set([1, 2, 3]),
        current: Set([2, 3, 4])
    )

    #expect(result.added == Set([4]))
    #expect(result.removed == Set([1]))
    #expect(result.retained == Set([2, 3]))
}
