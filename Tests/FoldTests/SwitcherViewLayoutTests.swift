import AppKit
import SwiftUI
import XCTest
@testable import Fold

@MainActor
final class SwitcherViewLayoutTests: XCTestCase {
    private func makeWindows(_ count: Int) -> [WindowInfo] {
        (0..<count).map { index in
            WindowInfo(
                id: CGWindowID(index + 1),
                pid: 1,
                appName: "App",
                title: "Window \(index)",
                frame: CGRect(x: 0, y: 0, width: 1200, height: 800),
                icon: nil
            )
        }
    }

    /// Renders the switcher on a screen-sized host and returns the column
    /// frame it reports (the content frame without a highlighted window).
    private func reportedFrame(windowCount: Int, screen: CGSize) -> CGRect {
        let model = SwitcherModel()
        let session = model.beginSession()
        let windows = makeWindows(windowCount)
        model.setWindows(windows, session: session)
        model.highlightedID = nil

        var reported = CGRect.null
        let view = SwitcherView(
            model: model,
            windows: windows,
            screenSize: screen,
            onSelect: { _ in },
            onContentFrameChange: { reported = $0 }
        )
        let window = NSWindow(contentRect: CGRect(origin: .zero, size: screen), styleMask: .borderless, backing: .buffered, defer: false)
        let host = NSHostingView(rootView: view)
        host.frame = CGRect(origin: .zero, size: screen)
        window.contentView = host
        for _ in 0..<5 {
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        return reported
    }

    func testOverflowingListIsLimitedToMaxColumnHeight() {
        let screen = CGSize(width: 1512, height: 982)
        let frame = reportedFrame(windowCount: 20, screen: screen)
        let layout = SwitcherLayout(screenSize: screen)
        XCTAssertFalse(frame.isNull)
        XCTAssertLessThanOrEqual(frame.height, layout.maxColumnHeight + 0.5)
    }

    func testShortListUsesItsNaturalHeight() {
        let screen = CGSize(width: 1512, height: 982)
        let frame = reportedFrame(windowCount: 3, screen: screen)
        XCTAssertEqual(frame.height, 3 * SwitcherView.rowHeight + 2 * SwitcherView.spacing, accuracy: 0.5)
    }
}
