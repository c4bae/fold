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

/// Scroll position and sizes of an `NSScrollView`.
struct ScrollGeometry: Equatable {
    var offset: CGFloat
    var viewport: CGFloat
    var content: CGFloat
}

/// Reports the geometry of the enclosing `NSScrollView` whenever it scrolls or
/// resizes. Place it in the background of a SwiftUI `ScrollView`'s content.
///
/// SwiftUI geometry readers inside a macOS `ScrollView` are not re-evaluated
/// while scrolling (the `NSScrollView` just moves its clip view), so the
/// position has to come from AppKit. macOS 15's `onScrollGeometryChange`
/// would replace this.
struct ScrollGeometryObserver: NSViewRepresentable {
    let onChange: (ScrollGeometry) -> Void

    func makeNSView(context: Context) -> ObserverView {
        ObserverView()
    }

    func updateNSView(_ view: ObserverView, context: Context) {
        view.onChange = onChange
    }

    final class ObserverView: NSView {
        var onChange: ((ScrollGeometry) -> Void)?
        private var observers: [NSObjectProtocol] = []
        private weak var observedScrollView: NSScrollView?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            attach()
        }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            attach()
        }

        private func attach() {
            guard let scrollView = enclosingScrollView, scrollView !== observedScrollView else { return }
            detach()
            observedScrollView = scrollView

            let clipView = scrollView.contentView
            clipView.postsBoundsChangedNotifications = true
            clipView.postsFrameChangedNotifications = true
            scrollView.documentView?.postsFrameChangedNotifications = true

            let center = NotificationCenter.default
            let handler: (Notification) -> Void = { [weak self] _ in self?.report() }
            observers = [
                center.addObserver(forName: NSView.boundsDidChangeNotification, object: clipView, queue: .main, using: handler),
                center.addObserver(forName: NSView.frameDidChangeNotification, object: clipView, queue: .main, using: handler),
            ]
            if let documentView = scrollView.documentView {
                observers.append(
                    center.addObserver(forName: NSView.frameDidChangeNotification, object: documentView, queue: .main, using: handler)
                )
            }
            report()
        }

        private func detach() {
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
        }

        private func report() {
            guard let scrollView = observedScrollView else { return }
            let clipBounds = scrollView.contentView.bounds
            let geometry = ScrollGeometry(
                offset: clipBounds.origin.y,
                viewport: clipBounds.height,
                content: scrollView.documentView?.frame.height ?? 0
            )
            DispatchQueue.main.async { [weak self] in self?.onChange?(geometry) }
        }

        deinit {
            observers.forEach(NotificationCenter.default.removeObserver)
        }
    }
}
