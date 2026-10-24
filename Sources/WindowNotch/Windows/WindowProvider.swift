import AppKit
import ScreenCaptureKit

/// The switchable windows, plus the ScreenCaptureKit handles needed to
/// capture them.
struct WindowSnapshot {
    let windows: [WindowInfo]
    let captureTargets: [SCWindow]
}

/// Fetches the current list of switchable windows.
@MainActor
enum WindowProvider {
    static func fetchWindows() async throws -> WindowSnapshot {
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)

        var windowsByID: [CGWindowID: SCWindow] = [:]
        let candidates = content.windows.compactMap { window -> WindowCandidate? in
            guard let app = window.owningApplication else { return nil }
            windowsByID[window.windowID] = window
            return WindowCandidate(
                id: window.windowID,
                layer: window.windowLayer,
                frame: window.frame,
                appName: app.applicationName,
                bundleID: app.bundleIdentifier
            )
        }

        let ordered = WindowFilter.switchable(
            candidates,
            zOrder: frontToBackWindowIDs(),
            ownBundleID: Bundle.main.bundleIdentifier
        )

        var windows: [WindowInfo] = []
        var captureTargets: [SCWindow] = []
        for candidate in ordered {
            guard let window = windowsByID[candidate.id], let app = window.owningApplication else { continue }
            let pid = app.processID
            windows.append(WindowInfo(
                id: candidate.id,
                pid: pid,
                appName: candidate.appName,
                title: window.title ?? "",
                frame: candidate.frame,
                icon: NSRunningApplication(processIdentifier: pid)?.icon
            ))
            captureTargets.append(window)
        }
        return WindowSnapshot(windows: windows, captureTargets: captureTargets)
    }

    /// On-screen window IDs ordered front to back. ScreenCaptureKit does not
    /// guarantee an order, but the window server list does.
    private static func frontToBackWindowIDs() -> [CGWindowID] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return info.compactMap { $0[kCGWindowNumber as String] as? CGWindowID }
    }
}
