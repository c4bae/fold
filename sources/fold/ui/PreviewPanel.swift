import SwiftUI

/// Large preview of the highlighted window, shown beside the row column.
struct PreviewPanel: View {
    let window: WindowInfo
    let thumbnail: CGImage?

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 12) }

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(decorative: thumbnail, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.white.opacity(0.08)
                if let icon = window.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .opacity(0.8)
                }
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.15), lineWidth: 1))
        // Rasterize (and scale the large thumbnail) on the GPU instead of on
        // the CPU every frame. Comes before the shadow so it isn't clipped.
        .drawingGroup()
        .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
        .contentShape(shape)
    }
}
