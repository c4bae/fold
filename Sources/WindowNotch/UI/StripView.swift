import SwiftUI

/// One window as a wide, short strip: app icon and title.
struct StripView: View {
    let window: WindowInfo
    let isHighlighted: Bool
    let height: CGFloat

    var body: some View {
        HStack(spacing: 12) {
            if let icon = window.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            Text(window.displayTitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(isHighlighted ? 0.22 : 0.08))
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}
