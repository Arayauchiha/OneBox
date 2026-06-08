import SwiftUI

struct ToolDestinationScreen: View {
    let tool: OperationItem
    var initialItems: [ImportSelectionItem]? = nil
    
    @AppStorage("favorite_tool_titles") private var favoriteToolTitlesStorage = ""

    var body: some View {
        Group {
            switch tool.title {
            case "Image to PDF", "Convert to PDF":
                ImageToPDFToolScreen(initialItems: initialItems)
            case "Merge PDF", "Merge":
                MergePDFToolScreen()
            case "Compress PDF", "Compress":
                CompressPDFToolScreen()
            case "OCR":
                OCRToolScreen(initialItems: initialItems)
            case "Background Remove":
                BackgroundRemovalToolScreen(initialItems: initialItems)
            case "Resize":
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .primary)
                }
            }
        }
    }
    
    private var isFavorite: Bool {
        let favorites = decodeFavorites(favoriteToolTitlesStorage)
        return favorites.contains(tool.title)
    }
    
    private func toggleFavorite() {
        var favorites = decodeFavorites(favoriteToolTitlesStorage)
        if favorites.contains(tool.title) {
            favorites.remove(tool.title)
        } else {
            favorites.insert(tool.title)
        }
        favoriteToolTitlesStorage = encodeFavorites(favorites)
    }
    
    private func decodeFavorites(_ value: String) -> Set<String> {
        let items = value.split(separator: "|").map(String.init)
        return Set(items)
    }

    private func encodeFavorites(_ favorites: Set<String>) -> String {
        favorites.sorted().joined(separator: "|")
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
