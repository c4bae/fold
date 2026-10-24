import AppKit
import CoreGraphics

/// Screen Recording permission, needed for window titles and thumbnails.
enum PermissionManager {
    static var hasScreenRecording: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Adds the app to the Screen Recording list (prompting the first time)
    /// and opens that System Settings pane.
    static func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
