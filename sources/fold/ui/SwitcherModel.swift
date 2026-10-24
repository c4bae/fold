import CoreGraphics
import Observation

/// State shown by the switcher overlay.
@MainActor
@Observable
final class SwitcherModel {
    enum Content {
        case loading
        case permissionNeeded
        case windows([WindowInfo])
        case failed(String)
    }

    private(set) var content: Content = .loading
    var highlightedID: CGWindowID?
    private(set) var thumbnails: [CGWindowID: CGImage] = [:]

    /// Bumped on every new session so a slow fetch from a previous open can't
    /// overwrite the current list.
    private(set) var session = 0

    var windows: [WindowInfo] {
        if case .windows(let windows) = content { return windows }
        return []
    }

    var highlightedWindow: WindowInfo? {
        windows.first { $0.id == highlightedID }
    }

    /// Starts a new session and returns its token.
    func beginSession() -> Int {
        session += 1
        content = .loading
        highlightedID = nil
        thumbnails = [:]
        return session
    }

    func showPermissionNeeded() {
        content = .permissionNeeded
    }

    func setWindows(_ windows: [WindowInfo], session: Int) {
        guard session == self.session else { return }
        content = .windows(windows)
        highlightedID = windows.first?.id
    }

    func setThumbnails(_ thumbnails: [CGWindowID: CGImage], session: Int) {
        guard session == self.session else { return }
        self.thumbnails = thumbnails
    }

    func setThumbnail(_ image: CGImage, for id: CGWindowID, session: Int) {
        guard session == self.session else { return }
        thumbnails[id] = image
    }

    func setFailure(_ message: String, session: Int) {
        guard session == self.session else { return }
        content = .failed(message)
    }

    func moveHighlight(by delta: Int) {
        let current = windows.firstIndex { $0.id == highlightedID }
        guard let next = HighlightNavigation.index(from: current, by: delta, count: windows.count) else { return }
        highlightedID = windows[next].id
    }
}

enum HighlightNavigation {
    /// Moves `delta` steps from `current`, wrapping around. With no current
    /// index, moving down starts at the top and moving up at the bottom.
    static func index(from current: Int?, by delta: Int, count: Int) -> Int? {
        guard count > 0 else { return nil }
        guard let current else { return delta >= 0 ? 0 : count - 1 }
        let next = (current + delta) % count
        return next < 0 ? next + count : next
    }
}
