import AppKit

/// Owns the notch trigger, the overlay, and the switcher model, and wires
/// them together.
@MainActor
final class AppCoordinator {
    private let trigger = NotchTrigger()
    private let overlay = OverlayController()
    private let model = SwitcherModel()
    private let switcher: WindowSwitcher = AppActivationSwitcher()
    private let thumbnailService = ThumbnailService()

    private static let authorURL = URL(string: "https://github.com/c4bae")!

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
                onCreditClick: { [weak self] in
                    self?.overlay.hide()
                    NSWorkspace.shared.open(Self.authorURL)
                },
                onOpenPermissionSettings: { [weak self] in
                    // Close first; the overlay would cover System Settings.
                    self?.overlay.hide()
                    PermissionManager.requestScreenRecording()
                },
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
                let snapshot = try await WindowProvider.fetchWindows()
                let ids = snapshot.windows.map(\.id)
                model.setThumbnails(thumbnailService.cachedThumbnails(for: ids), session: session)
                model.setWindows(snapshot.windows, session: session)
                await thumbnailService.capture(snapshot.captureTargets) { id, image in
                    model.setThumbnail(image, for: id, session: session)
                }
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
