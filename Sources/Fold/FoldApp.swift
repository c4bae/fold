import SwiftUI

@main
struct FoldApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Fold", systemImage: "rectangle.stack") {
            Button("Open Switcher") {
                appDelegate.coordinator.openSwitcher()
            }
            Divider()
            Toggle("Launch at Login", isOn: Binding(
                get: { appDelegate.launchAtLogin.isEnabled },
                set: { appDelegate.launchAtLogin.setEnabled($0) }
            ))
            Button("Welcome Guide…") {
                appDelegate.onboarding.show()
            }
            Divider()
            Button("Quit Fold") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()
    let onboarding = OnboardingWindowController()
    let launchAtLogin = LaunchAtLogin()

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.start()
        if !PermissionManager.hasScreenRecording {
            onboarding.show()
        }
    }
}
