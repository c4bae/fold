import SwiftUI

/// Vertical column of window strips. Scrolls when there are too many to fit.
@MainActor
struct AccordionView: View {
    let model: SwitcherModel
    let windows: [WindowInfo]
    let width: CGFloat
    let maxHeight: CGFloat
    let onSelect: (WindowInfo) -> Void

    static let stripHeight: CGFloat = 80
    static let spacing: CGFloat = 6

    var body: some View {
        ScrollViewReader { scroller in
            ViewThatFits(in: .vertical) {
                column
                ScrollView(.vertical, showsIndicators: false) {
                    column
                }
            }
            .frame(width: width)
            .frame(maxHeight: maxHeight)
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: model.highlightedID) { _, id in
                guard let id else { return }
                withAnimation(.easeOut(duration: 0.15)) {
                    scroller.scrollTo(id)
                }
            }
        }
    }

    private var column: some View {
        VStack(spacing: Self.spacing) {
            ForEach(windows) { window in
                StripView(
                    window: window,
                    isHighlighted: window.id == model.highlightedID,
                    height: Self.stripHeight
                )
                .id(window.id)
                .onHover { hovering in
                    if hovering { model.highlightedID = window.id }
                }
                .onTapGesture { onSelect(window) }
            }
        }
    }
}
