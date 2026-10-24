import SwiftUI

/// Size and position of a scroll indicator thumb.
struct ScrollIndicatorMetrics: Equatable {
    static let minThumbHeight: CGFloat = 28

    let thumbHeight: CGFloat
    let thumbOffset: CGFloat

    /// - Parameters:
    ///   - viewport: Visible height of the scroll view.
    ///   - content: Total height of the scrolled content.
    ///   - offset: How far the content is scrolled (0 at the top).
    /// Returns nil when the content fits and there is nothing to scroll.
    init?(viewport: CGFloat, content: CGFloat, offset: CGFloat) {
        guard viewport > 0, content > viewport else { return nil }
        let height = min(viewport, max(Self.minThumbHeight, viewport * viewport / content))
        let progress = min(max(offset / (content - viewport), 0), 1)
        thumbHeight = height
        thumbOffset = (viewport - height) * progress
    }
}

/// Always-visible scroll bar (the system one auto-hides unless the user has
/// set "Show scroll bars: Always").
struct ScrollIndicator: View {
    let metrics: ScrollIndicatorMetrics

    static let width: CGFloat = 5

    var body: some View {
        ZStack(alignment: .top) {
            Capsule().fill(.white.opacity(0.08))
            Capsule()
                .fill(.white.opacity(0.45))
                .frame(height: metrics.thumbHeight)
                .offset(y: metrics.thumbOffset)
        }
        .frame(width: Self.width)
        .allowsHitTesting(false)
    }
}
