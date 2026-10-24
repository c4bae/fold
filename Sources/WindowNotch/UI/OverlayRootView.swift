import SwiftUI

/// Root of the overlay: a click-to-dismiss backdrop with the switcher content
/// centered on top and an author credit at the bottom. Reports the area
/// spanning both so the overlay knows where the cursor may roam.
@MainActor
struct OverlayRootView: View {
    let model: SwitcherModel
    let onSelect: (WindowInfo) -> Void
    let onBackgroundClick: () -> Void
    let onCreditClick: () -> Void
    let onContentFrameChange: (CGRect) -> Void

    @State private var contentFrame: CGRect = .null
    @State private var creditFrame: CGRect = .null

    /// Covers the content, the credit, and the space between them, so moving
    /// from the windows down to the credit doesn't dismiss the overlay.
    private var reportedFrame: CGRect { contentFrame.union(creditFrame) }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onBackgroundClick)

                content(screenSize: proxy.size)

                CreditLink(action: onCreditClick)
                    .background(frameReader { creditFrame = $0 })
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
        .onChange(of: reportedFrame) { _, frame in onContentFrameChange(frame) }
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
                onContentFrameChange: { contentFrame = $0 }
            )
        case .failed(let message):
            reportingFrame(MessageCard(text: message))
        }
    }

    private func reportingFrame(_ card: some View) -> some View {
        card.background(frameReader { contentFrame = $0 })
    }

    private func frameReader(_ update: @escaping (CGRect) -> Void) -> some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { update(proxy.frame(in: .global)) }
                .onChange(of: proxy.frame(in: .global)) { _, frame in update(frame) }
        }
    }
}

private struct CreditLink: View {
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text("by c4bae")
                .font(.system(size: 12, weight: .medium))
                .underline(isHovered)
                .foregroundStyle(.white.opacity(isHovered ? 0.85 : 0.45))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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
