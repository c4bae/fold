import CoreGraphics

/// Finds which of an app's Accessibility windows is the window the user picked.
enum WindowMatcher {
    struct Target {
        let id: CGWindowID
        let title: String
        let frame: CGRect
    }

    /// An Accessibility window. `windowID` is nil when it couldn't be read.
    struct Candidate {
        let windowID: CGWindowID?
        let title: String
        let frame: CGRect
    }

    /// The window ID decides when known. Otherwise fall back to title and
    /// frame together, then to a frame only one candidate has. Returns nil
    /// rather than guess between equally good matches.
    static func index(of target: Target, in candidates: [Candidate]) -> Int? {
        if let index = candidates.firstIndex(where: { $0.windowID == target.id }) {
            return index
        }
        let unknown = candidates.indices.filter { candidates[$0].windowID == nil }
        let sameFrame = unknown.filter { framesMatch(candidates[$0].frame, target.frame) }
        let sameTitleAndFrame = sameFrame.filter { candidates[$0].title == target.title }
        if sameTitleAndFrame.count == 1 { return sameTitleAndFrame[0] }
        if sameFrame.count == 1 { return sameFrame[0] }
        return nil
    }

    /// Accessibility and window-server frames can differ by rounding.
    private static func framesMatch(_ a: CGRect, _ b: CGRect) -> Bool {
        let tolerance: CGFloat = 1
        return abs(a.minX - b.minX) <= tolerance && abs(a.minY - b.minY) <= tolerance
            && abs(a.width - b.width) <= tolerance && abs(a.height - b.height) <= tolerance
    }
}
