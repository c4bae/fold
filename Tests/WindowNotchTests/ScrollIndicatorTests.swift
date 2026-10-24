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
