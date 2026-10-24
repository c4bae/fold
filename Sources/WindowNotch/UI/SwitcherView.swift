import SwiftUI

/// The window list: a column of rows with a preview of the highlighted window
/// beside it, both centered vertically. Reports the combined frame of both so
/// the overlay stays open while the cursor is over either.
@MainActor
struct SwitcherView: View {
    let model: SwitcherModel
    let windows: [WindowInfo]
    let screenSize: CGSize
    let onSelect: (WindowInfo) -> Void
    let onContentFrameChange: (CGRect) -> Void

    @State private var columnFrame: CGRect = .zero

    static let rowHeight: CGFloat = 80
    static let spacing: CGFloat = 6
    /// Resizes the preview between windows of different shapes; snappy so it
    /// keeps up with fast navigation.
    private static let previewSpring = Animation.spring(response: 0.22, dampingFraction: 0.9)

    private var layout: SwitcherLayout { SwitcherLayout(screenSize: screenSize) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            rowList
                .position(x: layout.columnCenterX, y: layout.centerY)

            if let window = model.highlightedWindow {
                let preview = previewFrame(for: window)
                PreviewPanel(window: window, thumbnail: model.thumbnails[window.id])
                    .frame(width: preview.width, height: preview.height)
                    .position(x: preview.midX, y: preview.midY)
                    .animation(Self.previewSpring, value: preview)
                    .onTapGesture { onSelect(window) }
                    .transition(.opacity)
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .onAppear { onContentFrameChange(contentFrame) }
        .onChange(of: contentFrame) { _, frame in onContentFrameChange(frame) }
    }

    private var rowList: some View {
        ScrollViewReader { scroller in
            ViewThatFits(in: .vertical) {
                rows
                ScrollView(.vertical, showsIndicators: false) {
                    rows
                }
            }
            .frame(width: layout.columnWidth)
            .frame(maxHeight: layout.maxColumnHeight)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { columnFrame = proxy.frame(in: .global) }
                        .onChange(of: proxy.frame(in: .global)) { _, frame in columnFrame = frame }
                }
            )
            .onChange(of: model.highlightedID) { _, id in
                guard let id else { return }
                withAnimation(.easeOut(duration: 0.15)) {
                    scroller.scrollTo(id)
                }
            }
        }
    }

    private var rows: some View {
        VStack(spacing: Self.spacing) {
            ForEach(windows) { window in
                StripView(
                    window: window,
                    isHighlighted: window.id == model.highlightedID,
                    height: Self.rowHeight
                )
                .id(window.id)
                .onHover { hovering in
                    if hovering { model.highlightedID = window.id }
                }
                .onTapGesture { onSelect(window) }
            }
        }
    }

    private func previewFrame(for window: WindowInfo) -> CGRect {
        let size = layout.previewSize(for: window.frame.size)
        return CGRect(
            x: layout.previewMinX,
            y: layout.centerY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private var contentFrame: CGRect {
        guard let window = model.highlightedWindow else { return columnFrame }
        return columnFrame.union(previewFrame(for: window))
    }
}
