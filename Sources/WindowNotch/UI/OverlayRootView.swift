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
            reportingFrame(PermissionNeededCard())
        case .windows(let windows) where windows.isEmpty:
            reportingFrame(MessageCard(text: "No open windows"))
        case .windows(let windows):
            SwitcherView(
                model: model,
                windows: windows,
                screenSize: screenSize,
                onSelect: onSelect,
                onContentFrameChange: onContentFrameChange
            )
        case .failed(let message):
            reportingFrame(MessageCard(text: message))
        }
    }

    private func reportingFrame(_ card: some View) -> some View {
        card.background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { onContentFrameChange(proxy.frame(in: .global)) }
                    .onChange(of: proxy.frame(in: .global)) { _, frame in
                        onContentFrameChange(frame)
                    }
            }
        )
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
