import AppKit

/// Owns the notch trigger and the overlay, and wires them together.
@MainActor
final class AppCoordinator {
    private let trigger = NotchTrigger()
    private let overlay = OverlayController()

    func start() {
        trigger.onTrigger = { [weak self] in self?.openSwitcher() }
        overlay.onDismiss = { [weak self] in
            self?.trigger.requireExit()
            self?.trigger.isEnabled = true
        }
        overlay.setContent(
            OverlayRootView(
                onBackgroundClick: { [weak self] in self?.overlay.hide() },
                onContentFrameChange: { [weak self] frame in
                    guard let self else { return }
                    self.overlay.setContentRect(self.overlay.screenRect(fromSwiftUIGlobal: frame))
                }
            )
        )
        trigger.start()
    }

    func openSwitcher() {
        guard !overlay.isVisible, let screen = NSScreen.switcherScreen else { return }
        trigger.isEnabled = false
        overlay.show(on: screen)
    }
}
