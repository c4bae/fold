import AppKit

/// A switchable window, as shown in the overlay.
struct WindowInfo: Identifiable {
    let id: CGWindowID
    let pid: pid_t
    let appName: String
    let title: String
    let frame: CGRect
    let icon: NSImage?

    /// "App - Title", or just the app name when the window has no title.
    var displayTitle: String {
        title.isEmpty ? appName : "\(appName) - \(title)"
    }
}
