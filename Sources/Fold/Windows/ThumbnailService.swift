import CoreGraphics
import ScreenCaptureKit

/// Captures window thumbnails in parallel and keeps the latest one per window
/// so a reopened switcher can show it immediately.
@MainActor
final class ThumbnailService {
    /// Target thumbnail width in pixels; height follows the window's aspect.
    nonisolated static let width = 1400

    private var cache: [CGWindowID: CGImage] = [:]

    func cachedThumbnails(for ids: [CGWindowID]) -> [CGWindowID: CGImage] {
        cache.filter { ids.contains($0.key) }
    }

    /// Captures every window, calling `onImage` as each one finishes. Drops
    /// cache entries for windows that no longer exist.
    func capture(_ windows: [SCWindow], onImage: (CGWindowID, CGImage) -> Void) async {
        let live = Set(windows.map(\.windowID))
        cache = cache.filter { live.contains($0.key) }

        await withTaskGroup(of: (CGWindowID, CGImage?).self) { group in
            for window in windows {
                group.addTask {
                    (window.windowID, try? await Self.captureImage(of: window))
                }
            }
            for await (id, image) in group {
                guard let image else { continue }
                cache[id] = image
                onImage(id, image)
            }
        }
    }

    private nonisolated static func captureImage(of window: SCWindow) async throws -> CGImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        let aspect = window.frame.height / max(window.frame.width, 1)
        config.width = width
        config.height = max(1, Int((CGFloat(width) * aspect).rounded()))
        config.showsCursor = false
        config.ignoreShadowsSingleWindow = true
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }
}
