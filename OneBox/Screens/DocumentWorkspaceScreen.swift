import SwiftUI

struct DocumentWorkspaceScreen: View {
    let document: ImportedDocument
    let previewDocument: ImportedDocument?
    let selectedItems: [ImportSelectionItem]
    let activeSelectedItemID: UUID?
    let onReplaceFromPhotos: () -> Void
    let onReplaceFromCamera: () -> Void
    let onReplaceFromFiles: () -> Void
    let onCancelDocument: () -> Void
    let onRemoveSelectedItem: (UUID) -> Void
    let onSelectSelectedItem: (UUID) -> Void
    private let cardCornerRadius: CGFloat = 24

    private var suggestedOperations: [OperationItem] {
        switch document.kind {
        case .image:
            return [
                .init(icon: "person.badge.minus", title: "Background Remove", subtitle: "Lift subject from photo"),
                .init(icon: "text.viewfinder", title: "OCR", subtitle: "Run AI text extraction"),
                .init(icon: "doc.richtext", title: "Convert to PDF", subtitle: "Create a shareable document")
            ]
        case .pdf:
            return [
                .init(icon: "arrow.down.doc", title: "Compress", subtitle: "Reduce file size"),
                .init(icon: "square.split.2x1", title: "Split PDF", subtitle: "Extract specific pages"),
                .init(icon: "signature", title: "Sign", subtitle: "Add your signature")
            ]
        case .other:
            return [
                .init(icon: "doc.badge.gearshape", title: "Convert", subtitle: "Change output format"),
                .init(icon: "lock.doc", title: "Protect", subtitle: "Secure with password"),
                .init(icon: "square.and.arrow.up", title: "Share", subtitle: "Send to other apps")
            ]
        }
    }

    private var allOperations: [OperationItem] {
        [
            .init(icon: "person.badge.minus", title: "Background Remove", subtitle: "AI subject lifting"),
            .init(icon: "text.viewfinder", title: "OCR", subtitle: "Text extraction"),
            .init(icon: "arrow.left.arrow.right", title: "Resize", subtitle: "Dimensions and quality"),
            .init(icon: "arrow.down.doc", title: "Compress", subtitle: "Make file smaller"),
            .init(icon: "doc.on.doc", title: "Merge", subtitle: "Combine with other docs"),
            .init(icon: "square.split.2x1", title: "Split", subtitle: "Break into parts"),
            .init(icon: "signature", title: "Sign", subtitle: "Add signature"),
            .init(icon: "lock.doc", title: "Protect", subtitle: "Password and permissions"),
            .init(icon: "square.and.arrow.up", title: "Export", subtitle: "Share or save output")
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ImportedHeroCard(
                    document: document,
                    previewDocument: previewDocument,
                    selectedItems: selectedItems,
                    activeSelectedItemID: activeSelectedItemID,
                    onReplaceFromPhotos: onReplaceFromPhotos,
                    onReplaceFromCamera: onReplaceFromCamera,
                    onReplaceFromFiles: onReplaceFromFiles,
                    onCancel: {},
                    onContinue: {},
                    showActionButtons: false,
                    onRemoveSelectedItem: onRemoveSelectedItem,
                    onSelectSelectedItem: onSelectSelectedItem
                )

                sectionHeader("Suggested")
                operationList(suggestedOperations)

                sectionHeader("All Operations")
                operationList(allOperations)
            }
            .padding()
        }
        .navigationTitle("Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") {
                    onCancelDocument()
                }
                .foregroundStyle(.red)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 2)
    }

    private func operationList(_ operations: [OperationItem]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(operations) { item in
                NavigationLink {
                    destinationFor(item)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: item.icon)
                            .font(.body.weight(.medium))
                            .frame(width: 38, height: 38)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .oneBoxGlassCard()
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func destinationFor(_ item: OperationItem) -> some View {
        ToolDestinationScreen(tool: item, initialItems: selectedItems)
    }
}
