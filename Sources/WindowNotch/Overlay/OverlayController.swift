import AppKit
import SwiftUI

/// Shows and hides the blurred overlay panel and handles dismissal.
@MainActor
final class OverlayController {
    /// Called once the overlay starts closing.
    var onDismiss: (() -> Void)?
    var onKey: ((OverlayKey) -> Void)?

    private(set) var isVisible = false

    private let panel = OverlayPanel()
    private let effectView = NSVisualEffectView()
    private var dismissal = PointerDismissal()
    private var mouseMonitors: [Any] = []
    /// Bumped on every show/hide so a stale fade-out never hides a newer show.
    private var generation = 0

    private static let fadeDuration: TimeInterval = 0.2

    init() {
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        // Stay dark in Light mode too; the content is white-on-dark.
        effectView.appearance = NSAppearance(named: .darkAqua)
        panel.contentView = effectView
        panel.onKey = { [weak self] key in
            guard let self else { return }
            if key == .escape {
                self.hide()
            } else {
                self.onKey?(key)
            }
        }
    }

    /// Replaces the SwiftUI content shown on top of the blur.
    func setContent<Content: View>(_ content: Content) {
        effectView.subviews.forEach { $0.removeFromSuperview() }
        let host = FirstMouseHostingView(rootView: content)
        host.frame = effectView.bounds
        host.autoresizingMask = [.width, .height]
        effectView.addSubview(host)
    }

    /// Updates the area (in screen coordinates) that keeps the overlay open
    /// while the cursor is over it.
    func setContentRect(_ rect: CGRect) {
        dismissal.contentRect = rect
    }

    /// Converts a rect in the hosting view's SwiftUI global space (top-left
    /// origin, window-relative) into screen coordinates.
    func screenRect(fromSwiftUIGlobal rect: CGRect) -> CGRect {
        let frame = panel.frame
        return CGRect(
            x: frame.minX + rect.minX,
            y: frame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    func show(on screen: NSScreen) {
        generation += 1
        isVisible = true
        dismissal.beginSession(notchRect: screen.notchTriggerRect)

        panel.setFrame(screen.frame, display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.fadeDuration
            panel.animator().alphaValue = 1
        }
        installMouseMonitors()
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
        generation += 1
        let hideGeneration = generation
        removeMouseMonitors()
        onDismiss?()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Self.fadeDuration
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.generation == hideGeneration else { return }
                self.panel.orderOut(nil)
            }
        })
    }

    private func installMouseMonitors() {
        removeMouseMonitors()
        let handler: () -> Void = { [weak self] in
            guard let self, self.isVisible else { return }
            if self.dismissal.pointerMoved(to: NSEvent.mouseLocation) {
                self.hide()
            }
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { event in
            handler()
            return event
        }) {
            mouseMonitors.append(local)
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved, handler: { _ in
            MainActor.assumeIsolated { handler() }
        }) {
            mouseMonitors.append(global)
        }
    }

    private func removeMouseMonitors() {
        mouseMonitors.forEach(NSEvent.removeMonitor)
        mouseMonitors.removeAll()
    }
}
