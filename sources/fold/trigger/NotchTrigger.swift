import AppKit

/// Watches the cursor and fires `onTrigger` after it dwells in the notch zone.
@MainActor
final class NotchTrigger {
    var onTrigger: (() -> Void)?

    /// While disabled (e.g. the overlay is open) the trigger never fires.
    var isEnabled = true {
        didSet { if !isEnabled { cancelDwell() } }
    }

    private(set) var triggerRect: CGRect = .zero

    private let dwell: TimeInterval
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var screenObserver: NSObjectProtocol?
    private var dwellWork: DispatchWorkItem?
    /// Set after firing; cleared once the cursor leaves the zone, so resting
    /// in the notch doesn't reopen the switcher right after it closes.
    private var needsExit = false

    init(dwell: TimeInterval = 0.18) {
        self.dwell = dwell
    }

    func start() {
        updateTriggerRect()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            MainActor.assumeIsolated { self?.mouseMoved() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.mouseMoved()
            return event
        }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateTriggerRect() }
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        globalMonitor = nil
        localMonitor = nil
        screenObserver = nil
        cancelDwell()
    }

    /// Call after the switcher closes; the cursor must leave the zone before
    /// the trigger can fire again.
    func requireExit() {
        needsExit = true
    }

    private func updateTriggerRect() {
        triggerRect = NSScreen.switcherScreen?.notchTriggerRect ?? .zero
    }

    private func isInside(_ point: CGPoint) -> Bool {
        NotchGeometry.rect(triggerRect, containsInclusive: point)
    }

    private func mouseMoved() {
        let inside = isInside(NSEvent.mouseLocation)
        if !inside {
            needsExit = false
            cancelDwell()
            return
        }
        guard isEnabled, !needsExit, dwellWork == nil else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.dwellWork = nil
            guard self.isEnabled, self.isInside(NSEvent.mouseLocation) else { return }
            self.needsExit = true
            self.onTrigger?()
        }
        dwellWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + dwell, execute: work)
    }

    private func cancelDwell() {
        dwellWork?.cancel()
        dwellWork = nil
    }
}
