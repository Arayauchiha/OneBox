import SwiftUI

struct ImportedHeroCard: View {
    let document: ImportedDocument
    let onReplaceFromPhotos: () -> Void
    let onReplaceFromCamera: () -> Void
    let onReplaceFromFiles: () -> Void
    let onCancel: () -> Void
    let onContinue: () -> Void
    var showActionButtons: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Menu {
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
            } label: {
                DocumentPreview(document: document)
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
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                        }
                        .buttonStyle(.plain)

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
            .frame(maxWidth: .infinity, minHeight: 162, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
    }
}
