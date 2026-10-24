import AppKit

/// Pure geometry for locating the notch trigger zone. All rects are in global
/// AppKit screen coordinates (origin bottom-left of the primary display).
enum NotchGeometry {
    /// Size of the trigger zone used when a screen has no notch.
    static let fallbackSize = CGSize(width: 200, height: 10)

    /// The notch rect, derived from the widths of the unobscured areas on
    /// either side of it. Returns nil when the screen has no notch.
    static func notchRect(screenFrame: CGRect, leftArea: CGRect?, rightArea: CGRect?) -> CGRect? {
        guard let leftArea, let rightArea else { return nil }
        let width = screenFrame.width - leftArea.width - rightArea.width
        let height = max(leftArea.height, rightArea.height)
        guard width > 0, height > 0 else { return nil }
        return CGRect(
            x: screenFrame.minX + leftArea.width,
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
    }

    /// The zone the cursor must dwell in to open the switcher.
    static func triggerRect(screenFrame: CGRect, leftArea: CGRect?, rightArea: CGRect?) -> CGRect {
        if let notch = notchRect(screenFrame: screenFrame, leftArea: leftArea, rightArea: rightArea) {
            return notch
        }
        return CGRect(
            x: screenFrame.midX - fallbackSize.width / 2,
            y: screenFrame.maxY - fallbackSize.height,
            width: fallbackSize.width,
            height: fallbackSize.height
        )
    }

    /// Like `CGRect.contains`, but includes the max edges. The cursor pinned
    /// to the top of the screen reports y == maxY, which `contains` rejects.
    static func rect(_ rect: CGRect, containsInclusive point: CGPoint) -> Bool {
        point.x >= rect.minX && point.x <= rect.maxX && point.y >= rect.minY && point.y <= rect.maxY
    }
}

extension NSScreen {
    var hasNotch: Bool {
        auxiliaryTopLeftArea != nil && auxiliaryTopRightArea != nil
    }

    /// The screen the switcher lives on: the built-in notched display if
    /// present, otherwise the primary (menu bar) display.
    static var switcherScreen: NSScreen? {
        screens.first(where: \.hasNotch) ?? screens.first
    }

    var notchTriggerRect: CGRect {
        NotchGeometry.triggerRect(
            screenFrame: frame,
            leftArea: auxiliaryTopLeftArea,
            rightArea: auxiliaryTopRightArea
        )
    }
}
