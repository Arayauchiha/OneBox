import SwiftUI

struct FloatingActionCluster: View {
    let operations: [QuickOperation]
    let progress: CGFloat
    let onOperationTap: (QuickOperation) -> Void

    private func itemOffset(index: Int) -> CGSize {
        let spacing: CGFloat = 60
        let start: CGFloat = 12
        let y = -((start + (CGFloat(index) * spacing)) * progress)
        return CGSize(width: 0, height: y)
    }

    private func itemReveal(index: Int) -> CGFloat {
        let threshold = CGFloat(index) * 0.06
        let range = max(1 - threshold, 0.001)
        return min(max((progress - threshold) / range, 0), 1)
    }

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 12) {
                    clusterContent
                }
            } else {
                clusterContent
            }
        }
        .frame(width: 240, height: 430, alignment: .bottomTrailing)
        .opacity(progress)
    }

    private var clusterContent: some View {
        ZStack(alignment: .bottomTrailing) {
            ForEach(Array(operations.enumerated()), id: \.element.id) { index, operation in
                let offset = itemOffset(index: index)
                let reveal = itemReveal(index: index)

                HStack(spacing: 10) {
                    operationLabel(operation)
                        .opacity(reveal)

                    Button {
                        onOperationTap(operation)
                    } label: {
                        Image(systemName: operation.icon)
                            .font(.title3.weight(.semibold))
                            .frame(width: 50, height: 50)
                    }
                    .buttonStyle(.plain)
                    .modifier(LiquidGlassFABButtonStyle())
                    .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 4)
                }
                .offset(offset)
                .scaleEffect(0.75 + (0.25 * reveal), anchor: .bottomTrailing)
                .opacity(reveal)
                .animation(.bouncy(duration: 0.36, extraBounce: 0.05).delay(Double(index) * 0.02), value: progress)
            }
        }
    }

    private func operationLabel(_ operation: QuickOperation) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(operation.title)
                .font(.caption.weight(.semibold))
            Text(operation.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.trailing)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .modifier(LiquidGlassFABLabelStyle())
    }
}

private struct LiquidGlassFABButtonStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(.regularMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
    }
}

private struct LiquidGlassFABLabelStyle: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}
