import CoreGraphics

/// Decides when the overlay should close because the cursor moved away.
///
/// The overlay opens with the cursor at the notch, not over the content, so
/// dismissal is only armed once the cursor has entered the content area.
struct PointerDismissal {
    /// Extra room around the content before moving away counts.
    static let margin: CGFloat = 40

    var contentRect: CGRect = .null
    var notchRect: CGRect = .null
    private(set) var isArmed = false

    init(contentRect: CGRect = .null, notchRect: CGRect = .null) {
        self.contentRect = contentRect
        self.notchRect = notchRect
    }

    /// Starts a new overlay session. The content rect is kept: SwiftUI only
    /// reports it when it changes, so it may not be reported again on reopen.
    mutating func beginSession(notchRect: CGRect) {
        self.notchRect = notchRect
        isArmed = false
    }

    /// Returns true when the overlay should be dismissed.
    mutating func pointerMoved(to point: CGPoint) -> Bool {
        guard !contentRect.isNull else { return false }
        let content = contentRect.insetBy(dx: -Self.margin, dy: -Self.margin)
        if content.contains(point) {
            isArmed = true
            return false
        }
        if !notchRect.isNull, NotchGeometry.rect(notchRect, containsInclusive: point) {
            return false
        }
        return isArmed
    }
}
