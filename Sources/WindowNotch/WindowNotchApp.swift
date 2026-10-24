import SwiftUI

@main
struct WindowNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("WindowNotch", systemImage: "rectangle.stack") {
            Button("Open Switcher") {
                appDelegate.coordinator.openSwitcher()
            }
            Divider()
            Button("Quit WindowNotch") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.start()
    }
}
