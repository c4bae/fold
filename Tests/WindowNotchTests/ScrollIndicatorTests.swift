import AppKit
import SwiftUI
import XCTest
@testable import WindowNotch

final class ScrollIndicatorTests: XCTestCase {
    func testHiddenWhenContentFits() {
        XCTAssertNil(ScrollIndicatorMetrics(viewport: 500, content: 500, offset: 0))
        XCTAssertNil(ScrollIndicatorMetrics(viewport: 500, content: 300, offset: 0))
    }

    func testThumbIsProportionalAndTracksOffset() {
        let top = ScrollIndicatorMetrics(viewport: 400, content: 1600, offset: 0)
        XCTAssertEqual(top, ScrollIndicatorMetrics(viewport: 400, content: 1600, offset: -50))
        XCTAssertEqual(top?.thumbHeight, 100)
        XCTAssertEqual(top?.thumbOffset, 0)

        XCTAssertEqual(ScrollIndicatorMetrics(viewport: 400, content: 1600, offset: 600)?.thumbOffset, 150)
        XCTAssertEqual(ScrollIndicatorMetrics(viewport: 400, content: 1600, offset: 1200)?.thumbOffset, 300)
        XCTAssertEqual(ScrollIndicatorMetrics(viewport: 400, content: 1600, offset: 5000)?.thumbOffset, 300)
    }

    func testThumbHasMinimumHeight() {
        let metrics = ScrollIndicatorMetrics(viewport: 400, content: 100_000, offset: 0)
        XCTAssertEqual(metrics?.thumbHeight, ScrollIndicatorMetrics.minThumbHeight)
    }
}

@MainActor
final class ScrollGeometryObserverTests: XCTestCase {
    private final class Box { var geometry: ScrollGeometry? }

    func testReportsOffsetWhenScrollViewScrolls() {
        let box = Box()
        let view = ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<50) { Text("Row \($0)").frame(height: 40) }
            }
            .background(ScrollGeometryObserver { box.geometry = $0 })
        }
        .frame(width: 300, height: 400)

        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 300, height: 400), styleMask: .borderless, backing: .buffered, defer: false)
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
        window.contentView = host
        spin(host)

        XCTAssertEqual(box.geometry?.offset, 0)
        XCTAssertEqual(box.geometry?.viewport, 400)
        XCTAssertEqual(box.geometry?.content, 2000)

        let scrollView = findScrollView(in: host)
        scrollView?.contentView.scroll(to: CGPoint(x: 0, y: 500))
        spin(host)
        XCTAssertEqual(box.geometry?.offset, 500)
    }

    private func spin(_ host: NSView) {
        for _ in 0..<5 {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    private func findScrollView(in view: NSView) -> NSScrollView? {
        (view as? NSScrollView) ?? view.subviews.lazy.compactMap { self.findScrollView(in: $0) }.first
    }
}
