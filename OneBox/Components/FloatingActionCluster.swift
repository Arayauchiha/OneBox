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
        ZStack(alignment: .bottomTrailing) {
            ForEach(Array(operations.enumerated()), id: \.element.id) { index, operation in
                let offset = itemOffset(index: index)
                let reveal = itemReveal(index: index)

                HStack(spacing: 10) {
                    Text(operation.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .opacity(reveal)

                    Button {
                        onOperationTap(operation)
                    } label: {
                        Image(systemName: operation.icon)
                            .font(.title3.weight(.semibold))
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 4)
                }
                .offset(offset)
                .scaleEffect(0.75 + (0.25 * reveal), anchor: .bottomTrailing)
                .opacity(reveal)
                .animation(.bouncy(duration: 0.36, extraBounce: 0.05).delay(Double(index) * 0.02), value: progress)
            }
        }
        .frame(width: 240, height: 430, alignment: .bottomTrailing)
        .opacity(progress)
    }
}
