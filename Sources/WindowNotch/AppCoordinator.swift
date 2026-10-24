import AppKit

/// Owns the notch trigger, the overlay, and the switcher model, and wires
/// them together.
@MainActor
final class AppCoordinator {
    private let trigger = NotchTrigger()
    private let overlay = OverlayController()
    private let model = SwitcherModel()
    private let switcher: WindowSwitcher = AppActivationSwitcher()

    func start() {
        trigger.onTrigger = { [weak self] in self?.openSwitcher() }
        overlay.onDismiss = { [weak self] in
            self?.trigger.requireExit()
            self?.trigger.isEnabled = true
        }
        overlay.onKey = { [weak self] key in self?.handle(key) }
        overlay.setContent(
            OverlayRootView(
                model: model,
                onSelect: { [weak self] window in self?.select(window) },
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
        let session = model.beginSession()
        overlay.show(on: screen)

        guard PermissionManager.hasScreenRecording else {
            model.showPermissionNeeded()
            return
        }
        Task {
            do {
                let windows = try await WindowProvider.fetchWindows()
                model.setWindows(windows, session: session)
            } catch {
                model.setFailure("Couldn't list windows: \(error.localizedDescription)", session: session)
            }
        }
    }

    private func handle(_ key: OverlayKey) {
        switch key {
        case .up: model.moveHighlight(by: -1)
        case .down: model.moveHighlight(by: 1)
        case .select:
            if let window = model.highlightedWindow { select(window) }
        case .escape: overlay.hide()
        }
    }

    private func select(_ window: WindowInfo) {
        overlay.hide()
        switcher.switchTo(window)
    }
}
