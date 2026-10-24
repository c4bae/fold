import XCTest
@testable import WindowNotch

final class SwitcherLayoutTests: XCTestCase {
    let layout = SwitcherLayout(screenSize: CGSize(width: 1500, height: 1000))

    func testColumnAndPreviewAreCenteredTogether() {
        let columnLeft = layout.columnCenterX - layout.columnWidth / 2
        let previewRight = layout.previewMinX + layout.maxPreviewWidth
        XCTAssertEqual(columnLeft, 1500 - previewRight, accuracy: 0.001)
        XCTAssertEqual(layout.previewMinX - (columnLeft + layout.columnWidth), SwitcherLayout.gap, accuracy: 0.001)
    }

    func testWidePreviewFillsAvailableWidth() {
        let size = layout.previewSize(for: CGSize(width: 1600, height: 1000))
        XCTAssertEqual(size.width, layout.maxPreviewWidth, accuracy: 0.001)
        XCTAssertEqual(size.height, layout.maxPreviewWidth * 0.625, accuracy: 0.001)
    }

    func testTallPreviewIsLimitedByHeight() {
        let size = layout.previewSize(for: CGSize(width: 400, height: 2000))
        XCTAssertEqual(size.height, layout.maxPreviewHeight, accuracy: 0.001)
        XCTAssertEqual(size.width, layout.maxPreviewHeight / 5, accuracy: 0.001)
    }

    func testTallestPreviewFitsBetweenMarginsWhenCentered() {
        let size = layout.previewSize(for: CGSize(width: 400, height: 2000))
        XCTAssertEqual(layout.centerY - size.height / 2, SwitcherLayout.topMargin, accuracy: 0.001)
        XCTAssertEqual(layout.centerY + size.height / 2, 1000 - SwitcherLayout.bottomMargin, accuracy: 0.001)
    }
}
