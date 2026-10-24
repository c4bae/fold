import CoreGraphics

/// Geometry of the switcher: a column of rows left of center and a preview
/// panel to its right, both vertically centered. All values are in the
/// overlay's coordinate space (top-left origin, screen-sized).
struct SwitcherLayout {
    let screenSize: CGSize

    static let gap: CGFloat = 40
    static let topMargin: CGFloat = 48
    static let bottomMargin: CGFloat = 32

    var columnWidth: CGFloat { screenSize.width * 0.38 }
    var maxColumnHeight: CGFloat { screenSize.height * 0.8 }
    var maxPreviewWidth: CGFloat { screenSize.width * 0.5 }
    var maxPreviewHeight: CGFloat { screenSize.height - Self.topMargin - Self.bottomMargin }

    private var left: CGFloat {
        (screenSize.width - (columnWidth + Self.gap + maxPreviewWidth)) / 2
    }

    var columnCenterX: CGFloat { left + columnWidth / 2 }

    /// Vertical center of the area between the margins, shared by the column
    /// and the preview.
    var centerY: CGFloat { (Self.topMargin + screenSize.height - Self.bottomMargin) / 2 }
    var previewMinX: CGFloat { left + columnWidth + Self.gap }

    /// The largest size with the window's aspect ratio that fits the preview
    /// area.
    func previewSize(for windowSize: CGSize) -> CGSize {
        guard windowSize.width > 0, windowSize.height > 0 else {
            return CGSize(width: maxPreviewWidth, height: maxPreviewWidth * 0.625)
        }
        let aspect = windowSize.height / windowSize.width
        var size = CGSize(width: maxPreviewWidth, height: maxPreviewWidth * aspect)
        if size.height > maxPreviewHeight {
            size = CGSize(width: maxPreviewHeight / aspect, height: maxPreviewHeight)
        }
        return size
    }

}
