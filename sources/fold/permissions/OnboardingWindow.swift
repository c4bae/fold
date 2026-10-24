import AppKit
import SwiftUI

/// The welcome window: explains how to use Fold and walks through
/// granting Screen Recording permission.
@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?

    func show() {
        let window = self.window ?? makeWindow()
        self.window = window
        window.center()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Fold"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: OnboardingView())
        return window
    }
}

private struct OnboardingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to Fold")
                        .font(.title2.weight(.semibold))
                    Text("Rest your cursor on the notch to see all your open windows. Click one to switch to it.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Screen Recording permission")
                    .font(.headline)
                Text("macOS requires it for Fold to read window titles and show previews. Previews stay in memory on your Mac: nothing is recorded, saved, or sent anywhere.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 14) {
                Step(number: 1, text: "Turn on Fold under Privacy & Security > Screen Recording.") {
                    Button("Open System Settings") {
                        PermissionManager.requestScreenRecording()
                    }
                }
                Step(number: 2, text: "Relaunch Fold so the permission takes effect.") {
                    Button("Relaunch Fold") {
                        AppRelauncher.relaunch()
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 36)
        .padding(.bottom, 28)
        .frame(width: 480)
    }
}

private struct Step<Action: View>: View {
    let number: Int
    let text: String
    @ViewBuilder let action: Action

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.callout.weight(.semibold).monospacedDigit())
                .frame(width: 22, height: 22)
                .background(Circle().fill(.quaternary))
            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .fixedSize(horizontal: false, vertical: true)
                action
            }
        }
    }
}
