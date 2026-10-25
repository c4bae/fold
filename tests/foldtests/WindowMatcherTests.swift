import XCTest
@testable import Fold

final class WindowMatcherTests: XCTestCase {
    private let frameA = CGRect(x: 0, y: 25, width: 800, height: 600)
    private let frameB = CGRect(x: 100, y: 125, width: 800, height: 600)

    private func target(_ id: CGWindowID = 7, title: String = "Docs", frame: CGRect? = nil) -> WindowMatcher.Target {
        WindowMatcher.Target(id: id, title: title, frame: frame ?? frameA)
    }

    func testPrefersMatchingWindowID() {
        let candidates = [
            WindowMatcher.Candidate(windowID: 3, title: "Docs", frame: frameA),
            WindowMatcher.Candidate(windowID: 7, title: "Other", frame: frameB),
        ]
        XCTAssertEqual(WindowMatcher.index(of: target(), in: candidates), 1)
    }

    func testCandidateWithDifferentKnownIDNeverMatches() {
        let candidates = [WindowMatcher.Candidate(windowID: 3, title: "Docs", frame: frameA)]
        XCTAssertNil(WindowMatcher.index(of: target(), in: candidates))
    }

    func testFallsBackToTitleAndFrameWhenIDUnknown() {
        let candidates = [
            WindowMatcher.Candidate(windowID: nil, title: "Docs", frame: frameB),
            WindowMatcher.Candidate(windowID: nil, title: "Docs", frame: frameA),
        ]
        XCTAssertEqual(WindowMatcher.index(of: target(), in: candidates), 1)
    }

    func testFrameMatchToleratesRounding() {
        let nearlyA = frameA.offsetBy(dx: 0.5, dy: -0.5)
        let candidates = [WindowMatcher.Candidate(windowID: nil, title: "Docs", frame: nearlyA)]
        XCTAssertEqual(WindowMatcher.index(of: target(), in: candidates), 0)
    }

    func testFallsBackToUniqueFrameWhenTitleChanged() {
        let candidates = [
            WindowMatcher.Candidate(windowID: nil, title: "Renamed", frame: frameA),
            WindowMatcher.Candidate(windowID: nil, title: "Other", frame: frameB),
        ]
        XCTAssertEqual(WindowMatcher.index(of: target(), in: candidates), 0)
    }

    func testAmbiguousFallbackMatchesNothing() {
        let candidates = [
            WindowMatcher.Candidate(windowID: nil, title: "One", frame: frameA),
            WindowMatcher.Candidate(windowID: nil, title: "Two", frame: frameA),
        ]
        XCTAssertNil(WindowMatcher.index(of: target(), in: candidates))
    }
}
