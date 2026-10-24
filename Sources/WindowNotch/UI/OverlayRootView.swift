import SwiftUI

/// Root of the overlay: a click-to-dismiss backdrop with the switcher content
/// centered on top. Reports the content's frame so the overlay knows where
/// the cursor may roam.
@MainActor
struct OverlayRootView: View {
    let model: SwitcherModel
    let onSelect: (WindowInfo) -> Void
    let onBackgroundClick: () -> Void
    let onContentFrameChange: (CGRect) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onBackgroundClick)

                content(screenSize: proxy.size)
                    .background(
                        GeometryReader { contentProxy in
                            Color.clear
                                .onAppear { onContentFrameChange(contentProxy.frame(in: .global)) }
                                .onChange(of: contentProxy.frame(in: .global)) { _, frame in
                                    onContentFrameChange(frame)
                                }
                        }
                    )
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func content(screenSize: CGSize) -> some View {
        switch model.content {
        case .loading:
            Color.clear.frame(width: 1, height: 1)
        case .permissionNeeded:
            PermissionNeededCard()
        case .windows(let windows) where windows.isEmpty:
            MessageCard(text: "No open windows")
        case .windows(let windows):
            AccordionView(
                model: model,
                windows: windows,
                width: screenSize.width * 0.7,
                maxHeight: screenSize.height * 0.8,
                onSelect: onSelect
            )
        case .failed(let message):
            MessageCard(text: message)
        }
    }
}

private struct MessageCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3.weight(.medium))
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 40)
            .padding(.vertical, 24)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PermissionNeededCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("Screen Recording permission needed")
                .font(.title3.weight(.semibold))
            Text("WindowNotch needs it to read window titles and show previews.\nAfter granting it, quit and reopen WindowNotch.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
            Button("Open System Settings") {
                PermissionManager.requestScreenRecording()
            }
            .controlSize(.large)
        }
        .foregroundStyle(.white)
        .padding(32)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
