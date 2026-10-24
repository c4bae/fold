import AppKit
import SwiftUI

enum OverlayKey {
    case escape, up, down, select
}

/// Full-screen, borderless, non-activating panel that can still become key so
/// it receives keyboard input.
final class OverlayPanel: NSPanel {
    var onKey: ((OverlayKey) -> Void)?

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        acceptsMouseMovedEvents = true
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: onKey?(.escape)
        case 126: onKey?(.up)
        case 125: onKey?(.down)
        case 36, 76: onKey?(.select)
        default: super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        onKey?(.escape)
    }
}

/// Hosting view that accepts the first click, so a click on a strip works even
/// if the panel was not yet key.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
