import AppKit
import ApplicationServices
import CoreGraphics

/// The permissions Fold uses: Screen Recording for window titles and
/// thumbnails, Accessibility for raising a specific window.
enum PermissionManager {
    static var hasScreenRecording: Bool {
        CGPreflightScreenCaptureAccess()
    }

    static var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    /// Adds the app to the Screen Recording list (prompting the first time)
    /// and opens that System Settings pane.
    static func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
        openPrivacyPane("Privacy_ScreenCapture")
    }

    /// Adds the app to the Accessibility list and opens that System Settings
    /// pane. Only the prompt option adds the app to the list; macOS shows its
    /// alert just the first time, so the pane is opened as well.
    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openPrivacyPane("Privacy_Accessibility")
    }

    private static func openPrivacyPane(_ anchor: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") {
            NSWorkspace.shared.open(url)
        }
    }
}
