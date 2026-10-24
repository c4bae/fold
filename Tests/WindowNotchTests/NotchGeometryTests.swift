import XCTest
@testable import WindowNotch

final class NotchGeometryTests: XCTestCase {
    // 14" MacBook Pro: 1512x982 points, notch ~185pt wide, 32pt tall.
    let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
    let left = CGRect(x: 0, y: 950, width: 663, height: 32)
    let right = CGRect(x: 849, y: 950, width: 663, height: 32)

    func testNotchRectSitsBetweenAuxiliaryAreas() {
        let rect = NotchGeometry.notchRect(screenFrame: screen, leftArea: left, rightArea: right)
        XCTAssertEqual(rect, CGRect(x: 663, y: 950, width: 186, height: 32))
    }

    func testNotchRectIsOffsetForNonOriginScreen() {
        let shifted = screen.offsetBy(dx: -1512, dy: 200)
        let rect = NotchGeometry.notchRect(screenFrame: shifted, leftArea: left, rightArea: right)
        XCTAssertEqual(rect, CGRect(x: -849, y: 1150, width: 186, height: 32))
    }

    func testNoNotchFallsBackToTopCenterZone() {
        let external = CGRect(x: 1512, y: 0, width: 2560, height: 1440)
        let rect = NotchGeometry.triggerRect(screenFrame: external, leftArea: nil, rightArea: nil)
        XCTAssertEqual(rect, CGRect(x: 1512 + 1180, y: 1430, width: 200, height: 10))
    }

    func testInclusiveContainsAcceptsTopEdge() {
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        XCTAssertTrue(NotchGeometry.rect(rect, containsInclusive: CGPoint(x: 5, y: 10)))
        XCTAssertFalse(rect.contains(CGPoint(x: 5, y: 10)))
        XCTAssertFalse(NotchGeometry.rect(rect, containsInclusive: CGPoint(x: 5, y: 10.5)))
    }
}
