import XCTest
@testable import Fold

final class WindowFilterTests: XCTestCase {
    private func window(
        _ id: CGWindowID,
        layer: Int = 0,
        size: CGSize = CGSize(width: 800, height: 600),
        app: String = "App",
        bundleID: String? = "com.example.app"
    ) -> WindowCandidate {
        WindowCandidate(id: id, layer: layer, frame: CGRect(origin: .zero, size: size), appName: app, bundleID: bundleID)
    }

    func testDropsNonNormalLayersSmallWindowsAndUnnamedApps() {
        let result = WindowFilter.switchable(
            [
                window(1),
                window(2, layer: 25),
                window(3, size: CGSize(width: 100, height: 600)),
                window(4, size: CGSize(width: 800, height: 50)),
                window(5, app: ""),
            ],
            zOrder: [],
            ownBundleID: nil
        )
        XCTAssertEqual(result.map(\.id), [1])
    }

    func testExcludesOwnWindows() {
        let result = WindowFilter.switchable(
            [window(1, bundleID: "com.c4bae.Fold"), window(2)],
            zOrder: [],
            ownBundleID: "com.c4bae.Fold"
        )
        XCTAssertEqual(result.map(\.id), [2])
    }

    func testOrdersFrontToBackWithUnknownWindowsLast() {
        let result = WindowFilter.switchable(
            [window(1), window(2), window(3), window(4)],
            zOrder: [3, 99, 1],
            ownBundleID: nil
        )
        XCTAssertEqual(result.map(\.id), [3, 1, 2, 4])
    }
}

final class HighlightNavigationTests: XCTestCase {
    func testWrapsBothWays() {
        XCTAssertEqual(HighlightNavigation.index(from: 2, by: 1, count: 3), 0)
        XCTAssertEqual(HighlightNavigation.index(from: 0, by: -1, count: 3), 2)
        XCTAssertEqual(HighlightNavigation.index(from: 1, by: 1, count: 3), 2)
    }

    func testStartsFromEdgeWithoutCurrent() {
        XCTAssertEqual(HighlightNavigation.index(from: nil, by: 1, count: 3), 0)
        XCTAssertEqual(HighlightNavigation.index(from: nil, by: -1, count: 3), 2)
    }

    func testEmptyListHasNoHighlight() {
        XCTAssertNil(HighlightNavigation.index(from: nil, by: 1, count: 0))
    }
}
