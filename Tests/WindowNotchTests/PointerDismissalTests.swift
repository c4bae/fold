import XCTest
@testable import WindowNotch

final class PointerDismissalTests: XCTestCase {
    let content = CGRect(x: 200, y: 200, width: 600, height: 400)
    let notch = CGRect(x: 450, y: 950, width: 100, height: 32)

    func testDoesNotDismissBeforeCursorReachesContent() {
        var dismissal = PointerDismissal(contentRect: content, notchRect: notch)
        XCTAssertFalse(dismissal.pointerMoved(to: CGPoint(x: 500, y: 960)))
        XCTAssertFalse(dismissal.pointerMoved(to: CGPoint(x: 500, y: 800)))
        XCTAssertFalse(dismissal.isArmed)
    }

    func testDismissesAfterLeavingContent() {
        var dismissal = PointerDismissal(contentRect: content, notchRect: notch)
        XCTAssertFalse(dismissal.pointerMoved(to: CGPoint(x: 500, y: 400)))
        XCTAssertTrue(dismissal.isArmed)
        XCTAssertTrue(dismissal.pointerMoved(to: CGPoint(x: 50, y: 50)))
    }

    func testMarginAroundContentKeepsOverlayOpen() {
        var dismissal = PointerDismissal(contentRect: content, notchRect: notch)
        _ = dismissal.pointerMoved(to: CGPoint(x: 500, y: 400))
        XCTAssertFalse(dismissal.pointerMoved(to: CGPoint(x: content.maxX + PointerDismissal.margin - 1, y: 400)))
    }

    func testNotchKeepsOverlayOpenAfterArming() {
        var dismissal = PointerDismissal(contentRect: content, notchRect: notch)
        _ = dismissal.pointerMoved(to: CGPoint(x: 500, y: 400))
        XCTAssertFalse(dismissal.pointerMoved(to: CGPoint(x: 500, y: 982)))
    }

    func testNoContentNeverDismisses() {
        var dismissal = PointerDismissal(notchRect: notch)
        XCTAssertFalse(dismissal.pointerMoved(to: CGPoint(x: 0, y: 0)))
    }
}

extension PointerDismissalTests {
    func testNewSessionKeepsContentRectAndDisarms() {
        var dismissal = PointerDismissal(contentRect: content, notchRect: notch)
        _ = dismissal.pointerMoved(to: CGPoint(x: 500, y: 400))
        XCTAssertTrue(dismissal.isArmed)

        let newNotch = CGRect(x: 0, y: 990, width: 200, height: 10)
        dismissal.beginSession(notchRect: newNotch)
        XCTAssertFalse(dismissal.isArmed)
        XCTAssertEqual(dismissal.notchRect, newNotch)

        // Content rect survives, so the new session can still arm and dismiss.
        XCTAssertFalse(dismissal.pointerMoved(to: CGPoint(x: 500, y: 400)))
        XCTAssertTrue(dismissal.pointerMoved(to: CGPoint(x: 50, y: 50)))
    }
}
