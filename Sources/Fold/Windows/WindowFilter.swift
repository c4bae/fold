import CoreGraphics

/// The fields of a window needed to decide whether it is switchable.
struct WindowCandidate: Equatable {
    let id: CGWindowID
    let layer: Int
    let frame: CGRect
    let appName: String
    let bundleID: String?
}

enum WindowFilter {
    static let minimumSize: CGFloat = 100

    /// Keeps normal app windows (layer 0, larger than the minimum size, owned
    /// by a named app other than `ownBundleID`), ordered front to back by
    /// `zOrder`. Windows missing from `zOrder` go last, in their input order.
    static func switchable(
        _ candidates: [WindowCandidate],
        zOrder: [CGWindowID],
        ownBundleID: String?
    ) -> [WindowCandidate] {
        let rank = Dictionary(zOrder.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return candidates
            .filter { window in
                window.layer == 0
                    && window.frame.width > minimumSize
                    && window.frame.height > minimumSize
                    && !window.appName.isEmpty
                    && (ownBundleID == nil || window.bundleID != ownBundleID)
            }
            .enumerated()
            .sorted { lhs, rhs in
                let l = rank[lhs.element.id] ?? Int.max
                let r = rank[rhs.element.id] ?? Int.max
                return l != r ? l < r : lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
