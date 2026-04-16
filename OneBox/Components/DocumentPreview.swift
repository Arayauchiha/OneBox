import QuickLookThumbnailing
import SwiftUI

struct DocumentPreview: View {
    let document: ImportedDocument
    private let previewCornerRadius: CGFloat = 14
    private let plateCornerRadius: CGFloat = 11
    @Environment(\.displayScale) private var displayScale
    @State private var pdfThumbnail: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))

            RoundedRectangle(cornerRadius: plateCornerRadius, style: .continuous)
                .fill(Color(.quaternarySystemFill).opacity(0.72))
                .padding(8)

            if let image = document.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
            } else if let pdfThumbnail {
                Image(uiImage: pdfThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: document.systemIcon)
                        .font(.system(size: 34, weight: .semibold))
                    Text(document.typeLabel)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.secondary)
                .padding(12)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .task(id: document.previewKey) {
            await loadPDFThumbnailIfNeeded()
        }
        .onChange(of: document.previewKey) { _, _ in
            pdfThumbnail = nil
        }
    }

    private func loadPDFThumbnailIfNeeded() async {
        guard pdfThumbnail == nil,
              document.previewImage == nil,
              let url = document.previewURL,
              url.pathExtension.lowercased() == "pdf" else {
            return
        }

        let scale = max(displayScale, 1)
        let thumbnail = await Task.detached(priority: .utility) {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let request = QLThumbnailGenerator.Request(
                fileAt: url,
                size: CGSize(width: 240, height: 320),
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
            pdfThumbnail = thumbnail
        }
    }
}
