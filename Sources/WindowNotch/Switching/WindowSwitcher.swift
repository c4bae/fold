import AppKit

/// Brings a window to the front. Behind a protocol so an Accessibility-based
/// implementation that raises the exact window can replace app activation.
@MainActor
protocol WindowSwitcher {
    func switchTo(_ window: WindowInfo)
}

/// Activates the window's app. The app decides which of its windows comes
/// forward.
struct AppActivationSwitcher: WindowSwitcher {
    func switchTo(_ window: WindowInfo) {
        guard let app = NSRunningApplication(processIdentifier: window.pid) else { return }
        // Since macOS 14 activation is cooperative: the active app must yield
        // before another app may activate.
        NSApp.yieldActivation(to: app)
        app.activate()
    }
}
