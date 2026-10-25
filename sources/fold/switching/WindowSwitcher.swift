import AppKit
import ApplicationServices

/// Brings a window to the front.
@MainActor
protocol WindowSwitcher {
    func switchTo(_ window: WindowInfo)
}

/// Activates the window's app. The app decides which of its windows comes
/// forward, so on its own this can't pick between two windows of one app.
struct AppActivationSwitcher: WindowSwitcher {
    func switchTo(_ window: WindowInfo) {
        guard let app = NSRunningApplication(processIdentifier: window.pid) else { return }
        // Since macOS 14 activation is cooperative: the active app must yield
        // before another app may activate.
        NSApp.yieldActivation(to: app)
        app.activate()
    }
}

/// Raises the exact window through the Accessibility API, then activates its
/// app. Without Accessibility permission this only activates the app.
struct AccessibilityWindowSwitcher: WindowSwitcher {
    private let activation = AppActivationSwitcher()

    func switchTo(_ window: WindowInfo) {
        if PermissionManager.hasAccessibility, let element = Self.element(for: window) {
            // Main makes it the app's front window, so activation keeps it
            // there; raise reorders it above the app's other windows.
            AXUIElementSetAttributeValue(element, kAXMainAttribute as CFString, kCFBooleanTrue)
            AXUIElementPerformAction(element, kAXRaiseAction as CFString)
        }
        activation.switchTo(window)
    }

    private static func element(for window: WindowInfo) -> AXUIElement? {
        let app = AXUIElementCreateApplication(window.pid)
        // Don't let an unresponsive app stall the main thread for the
        // default six seconds.
        AXUIElementSetMessagingTimeout(app, 0.5)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
              let elements = value as? [AXUIElement] else { return nil }

        let candidates = elements.map { element in
            WindowMatcher.Candidate(
                windowID: windowID(of: element),
                title: string(element, kAXTitleAttribute) ?? "",
                frame: frame(of: element) ?? .null
            )
        }
        let target = WindowMatcher.Target(id: window.id, title: window.title, frame: window.frame)
        return WindowMatcher.index(of: target, in: candidates).map { elements[$0] }
    }

    private static func windowID(of element: AXUIElement) -> CGWindowID? {
        var id: CGWindowID = 0
        return _AXUIElementGetWindow(element, &id) == .success ? id : nil
    }

    private static func string(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    /// Top-left-origin global coordinates, the same space as window-server frames.
    private static func frame(of element: AXUIElement) -> CGRect? {
        var position = CGPoint.zero
        var size = CGSize.zero
        guard let positionValue = axValue(element, kAXPositionAttribute),
              let sizeValue = axValue(element, kAXSizeAttribute),
              AXValueGetValue(positionValue, .cgPoint, &position),
              AXValueGetValue(sizeValue, .cgSize, &size) else { return nil }
        return CGRect(origin: position, size: size)
    }

    private static func axValue(_ element: AXUIElement, _ attribute: String) -> AXValue? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (value as! AXValue)
    }
}

/// Private but long-stable HIServices call (used by most window switchers):
/// the window-server ID behind an Accessibility window. The public API has no
/// equivalent, and matching by title and frame alone is ambiguous.
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ id: UnsafeMutablePointer<CGWindowID>) -> AXError
