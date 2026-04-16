import QuickLookThumbnailing
import SwiftUI

struct ImportedHeroCard: View {
    let document: ImportedDocument
    var previewDocument: ImportedDocument? = nil
    var selectedItems: [ImportSelectionItem] = []
    var activeSelectedItemID: UUID? = nil
    let onReplaceFromPhotos: () -> Void
    let onReplaceFromCamera: () -> Void
    let onReplaceFromFiles: () -> Void
    let onCancel: () -> Void
    let onContinue: () -> Void
    var showActionButtons: Bool = true
    var onRemoveSelectedItem: ((UUID) -> Void)? = nil
    var onSelectSelectedItem: ((UUID) -> Void)? = nil

    @State private var showSourceOptions = false

    private let cardCornerRadius: CGFloat = 24
    private let selectionThumbCornerRadius: CGFloat = 12

    private var activeSelectionItem: ImportSelectionItem? {
        guard let activeSelectedItemID else { return selectedItems.first }
        return selectedItems.first(where: { $0.id == activeSelectedItemID }) ?? selectedItems.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                Button {
                    showSourceOptions = true
                } label: {
                    HeroSelectionPreviewView(
                        item: activeSelectionItem,
                        fallbackDocument: previewDocument ?? document
                    )
                        .id(activeSelectionItem?.id.uuidString ?? document.previewKey)
                        .frame(width: 126, height: 162)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    Text(document.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .layoutPriority(1)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                        metadataCapsule(title: "Type", value: document.typeLabel)
                        metadataCapsule(title: "Size", value: document.sizeLabel)
                        metadataCapsule(title: "Pages", value: document.pagesLabel)
                        metadataCapsule(title: "Source", value: document.sourceLabel)
                    }

                    metadataCapsule(title: "Imported", value: document.importedAtLabel)

                    if showActionButtons {
                        HStack(spacing: 8) {
                            cancelButton
                            continueButton
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 162, alignment: .topLeading)
            }

            if !selectedItems.isEmpty {
                selectedItemsStrip
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .oneBoxGlassCard(cornerRadius: cardCornerRadius)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .confirmationDialog("Replace Import", isPresented: $showSourceOptions, titleVisibility: .visible) {
            Button {
                onReplaceFromPhotos()
            } label: {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }

            Button {
                onReplaceFromCamera()
            } label: {
                Label("Take Photo or Video", systemImage: "camera")
            }

            Button {
                onReplaceFromFiles()
            } label: {
                Label("Choose File", systemImage: "folder")
            }
        }
    }

    private var selectedItemsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected items (\(selectedItems.count))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(selectedItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Button {
                                onSelectSelectedItem?(item.id)
                            } label: {
                                SelectionThumbnailView(
                                    item: item,
                                    isSelected: item.id == activeSelectedItemID
                                )
                                    .frame(width: 96, height: 96)
                            }
                            .buttonStyle(.plain)
                            .overlay(alignment: .topTrailing) {
                                if let onRemoveSelectedItem {
                                    Button {
                                        onRemoveSelectedItem(item.id)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.primary)
                                            .padding(6)
                                            .background(.ultraThinMaterial, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(8)
                                }
                            }

                            Text(item.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                                .frame(width: 96, alignment: .leading)
                        }
                        .frame(width: 96, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func metadataCapsule(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 6)
            Text(value)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 38)
        .oneBoxSecondaryPill(cornerRadius: 999)
    }

    private var cancelButton: some View {
        Group {
            if #available(iOS 26, *) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.glass)
            } else {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var continueButton: some View {
        Group {
            if #available(iOS 26, *) {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.glassProminent)
            } else {
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.blue, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SelectionThumbnailView: View {
    let item: ImportSelectionItem
    let isSelected: Bool

    @Environment(\.displayScale) private var displayScale
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else if let image = item.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: item.systemIcon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.accentColor.opacity(0.9), lineWidth: 2)
                .opacity(isSelected ? 1 : 0)
        )
        .task(id: item.id) {
            await loadThumbnailIfNeeded()
        }
    }

    private func loadThumbnailIfNeeded() async {
        guard thumbnail == nil,
              item.previewImage == nil,
              let url = item.fileURL else {
            return
        }

        let scale = max(displayScale, 1)

        let result = await Task.detached(priority: .utility) {
            let secured = url.startAccessingSecurityScopedResource()
            defer {
                if secured {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let request = QLThumbnailGenerator.Request(
                fileAt: url,
                size: CGSize(width: 176, height: 176),
                scale: scale,
                representationTypes: .thumbnail
            )

            return await withCheckedContinuation { continuation in
                QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
                    continuation.resume(returning: representation?.uiImage)
                }
            }
        }.value

        await MainActor.run {
            thumbnail = result
        }
    }
}

private struct HeroSelectionPreviewView: View {
    let item: ImportSelectionItem?
    let fallbackDocument: ImportedDocument

    var body: some View {
        if let item {
            SelectionThumbnailView(item: item, isSelected: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            DocumentPreview(document: fallbackDocument)
        }
    }
}
