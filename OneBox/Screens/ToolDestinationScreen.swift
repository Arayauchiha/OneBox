import SwiftUI

struct ToolDestinationScreen: View {
    let tool: OperationItem

    var body: some View {
        switch tool.title {
        case "Image to PDF":
            ImageToPDFToolScreen()
        case "Resize", "Compress", "Background Remove":
            ToolPlannedScreen(
                tool: tool,
                nextStepTitle: nextStepTitle(for: tool.title),
                nextStepSubtitle: nextStepSubtitle(for: tool.title)
            )
        default:
            ToolPlannedScreen(
                tool: tool,
                nextStepTitle: "Tool Integration Planned",
                nextStepSubtitle: "This operation is queued for a native on-device implementation."
            )
        }
    }

    private func nextStepTitle(for title: String) -> String {
        switch title {
        case "Resize":
            return "Resize + Compress Flow"
        case "Compress":
            return "Compression Presets Flow"
        case "Background Remove":
            return "On-device Background Removal"
        default:
            return "Tool Integration Planned"
        }
    }

    private func nextStepSubtitle(for title: String) -> String {
        switch title {
        case "Resize":
            return "Using UIGraphicsImageRenderer and ImageIO with live size preview."
        case "Compress":
            return "Using ImageIO quality controls and optimized output encoding."
        case "Background Remove":
            return "Using Vision foreground instance masks (iOS 17+)."
        default:
            return "This operation is queued for a native on-device implementation."
        }
    }
}

private struct ToolPlannedScreen: View {
    let tool: OperationItem
    let nextStepTitle: String
    let nextStepSubtitle: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: tool.icon)
                            .font(.title3)
                            .frame(width: 34, height: 34)
                            .foregroundStyle(.primary)

                        Text(tool.title)
                            .font(.title3.weight(.semibold))
                    }

                    Text(tool.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(nextStepTitle)
                        .font(.headline)

                    Text(nextStepSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            }
            .padding(16)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(tool.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
