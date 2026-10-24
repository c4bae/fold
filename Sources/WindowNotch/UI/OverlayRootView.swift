import SwiftUI

/// Root of the overlay: a click-to-dismiss backdrop with the switcher content
/// centered on top. Reports the content's frame so the overlay knows where
/// the cursor may roam.
struct OverlayRootView: View {
    let onBackgroundClick: () -> Void
    let onContentFrameChange: (CGRect) -> Void

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onBackgroundClick)

            Text("WindowNotch")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 28)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { onContentFrameChange(proxy.frame(in: .global)) }
                            .onChange(of: proxy.frame(in: .global)) { _, frame in
                                onContentFrameChange(frame)
                            }
                    }
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
