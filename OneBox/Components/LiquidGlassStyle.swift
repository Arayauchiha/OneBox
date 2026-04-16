import SwiftUI

extension View {
    @ViewBuilder
    func oneBoxGlassCard(cornerRadius: CGFloat = 18, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            if interactive {
                self
                    .background(Color(.secondarySystemGroupedBackground).opacity(0.28), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self
                    .background(Color(.secondarySystemGroupedBackground).opacity(0.28), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            self
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    func oneBoxSecondaryPill(cornerRadius: CGFloat = 999) -> some View {
        if #available(iOS 26, *) {
            self
                .background(Color(.tertiarySystemGroupedBackground).opacity(0.3), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    func oneBoxFloatingButton() -> some View {
        if #available(iOS 26, *) {
            self
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            self
                .background(.regularMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
    }
}
