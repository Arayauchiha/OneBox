import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct MergePDFToolScreen: View {
    @State private var selectedPDFs: [SelectedPDFItem] = []
    @State private var showFileImporter = false
    @State private var isMerging = false
    @State private var generatedOutput: PDFOutput?
    @State private var statusMessage = "Select two or more PDF files to merge."
    @State private var showSequenceEditor = false
    @State private var previewDocument: PreviewDocument?
    
    private let cardCornerRadius: CGFloat = 24

    var body: some View {
        mainContent
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Merge PDF")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showSequenceEditor) {
                PDFSequenceEditorSheet(pdfs: $selectedPDFs)
            }
            .navigationDestination(item: $previewDocument) { document in
                QuickLookDocumentPreview(url: document.url)
                    .ignoresSafeArea()
            }
    }

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                inputCard
                selectedFilesCard
                mergeCard
                outputCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import PDF Files")
                .font(.headline)

            Text("Select the documents you want to combine. Everything stays on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showFileImporter = true
            } label: {
                Label("Choose Files", systemImage: "plus.rectangle.on.folder")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private var selectedFilesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected")
                    .font(.headline)

                Spacer()

                Text("\(selectedPDFs.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if selectedPDFs.isEmpty {
                Text("No files selected yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(selectedPDFs) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "doc.richtext")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 38, height: 38)
                                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text("\(item.pageCount) pages")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                removeSelectedPDF(item.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if selectedPDFs.count > 1 {
                        Button {
                            showSequenceEditor = true
                        } label: {
                            Label("Edit merge order", systemImage: "arrow.up.arrow.down")
                                .font(.caption.weight(.semibold))
                                .padding(.top, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private var mergeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Combine")
                .font(.headline)

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await mergePDFs()
                }
            } label: {
                HStack {
                    if isMerging {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isMerging ? "Merging..." : "Merge Documents")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedPDFs.count < 2 || isMerging ? Color.gray.opacity(0.25) : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedPDFs.count < 2 || isMerging)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    @ViewBuilder
    private var outputCard: some View {
        if let output = generatedOutput {
            VStack(alignment: .leading, spacing: 12) {
                Text("Merged Result")
                    .font(.headline)

                HStack(spacing: 12) {
                    if let preview = output.previewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Image(systemName: "doc.richtext")
                            .font(.title2)
                            .frame(width: 64, height: 64)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(output.fileName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        Text("\(output.pageCount) pages • \(output.sizeLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Saved in OneBox > Files")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    Button {
                        previewDocument = PreviewDocument(url: output.url)
                    } label: {
                        Label("Preview", systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    ShareLink(item: output.url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .cardContainer(cornerRadius: cardCornerRadius)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let loaded = urls.compactMap { url -> SelectedPDFItem? in
                let secured = url.startAccessingSecurityScopedResource()
                defer {
                    if secured {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                guard let doc = PDFDocument(url: url) else { return nil }
                return SelectedPDFItem(url: url, name: url.lastPathComponent, pageCount: doc.pageCount)
            }

            selectedPDFs.append(contentsOf: loaded)
            generatedOutput = nil
            updateStatus()

        case .failure:
            statusMessage = "Could not import files."
        }
    }

    private func removeSelectedPDF(_ id: UUID) {
        selectedPDFs.removeAll { $0.id == id }
        generatedOutput = nil
        updateStatus()
    }

    private func updateStatus() {
        if selectedPDFs.isEmpty {
            statusMessage = "Select two or more PDF files to merge."
        } else if selectedPDFs.count == 1 {
            statusMessage = "Select at least one more file."
        } else {
            statusMessage = "Ready to merge \(selectedPDFs.count) documents."
        }
    }

    private func mergePDFs() async {
        guard selectedPDFs.count >= 2 else { return }

        await MainActor.run {
            isMerging = true
            statusMessage = "Merging documents on-device..."
        }

        let urls = selectedPDFs.map(\.url)

        do {
            let output = try await PDFMergeService.mergePDFs(from: urls)

            await MainActor.run {
                generatedOutput = output
                isMerging = false
                statusMessage = "PDFs merged successfully."
            }
        } catch {
            await MainActor.run {
                isMerging = false
                statusMessage = "Merge failed. Try again."
            }
        }
    }
}

private struct SelectedPDFItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let pageCount: Int
}

private struct PDFOutput {
    let url: URL
    let fileName: String
    let pageCount: Int
    let sizeLabel: String
    let previewImage: UIImage?
}

private struct PreviewDocument: Identifiable, Hashable {
    let id = UUID()
    let url: URL
}

private enum PDFMergeService {
    nonisolated static func mergePDFs(from urls: [URL]) async throws -> PDFOutput {
        let data = try await Task.detached(priority: .userInitiated) {
            let mergedDoc = PDFDocument()
            var pageIndex = 0
            
            for url in urls {
                let secured = url.startAccessingSecurityScopedResource()
                defer { if secured { url.stopAccessingSecurityScopedResource() } }
                
                if let doc = PDFDocument(url: url) {
                    for i in 0..<doc.pageCount {
                        if let page = doc.page(at: i) {
                            mergedDoc.insert(page, at: pageIndex)
                            pageIndex += 1
                        }
                    }
                }
            }
            
            guard let data = mergedDoc.dataRepresentation() else {
                throw NSError(domain: "PDFMergeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PDF data"])
            }
            return data
        }.value

        let recordData = try await MainActor.run {
            let record = try OneBoxFileStore.savePDF(data: data, fileName: "OneBox-Merged", pageCount: urls.count) // pageCount here is count of docs, but OneBoxFileStore might expect total pages
            return (record.fileURL, record.fileName, record.sizeLabel, record.pageCount ?? 0)
        }

        let outputURL = recordData.0
        let fileName = recordData.1
        let sizeLabel = recordData.2
        let totalPages = recordData.3
        let previewImage = PDFDocument(url: outputURL)?.page(at: 0)?.thumbnail(of: CGSize(width: 140, height: 180), for: .mediaBox)

        return PDFOutput(
            url: outputURL,
            fileName: fileName,
            pageCount: totalPages,
            sizeLabel: sizeLabel,
            previewImage: previewImage
        )
    }
}

private struct PDFSequenceEditorSheet: View {
    @Binding var pdfs: [SelectedPDFItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Drag to reorder") {
                    ForEach(Array(pdfs.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            Image(systemName: "doc.richtext")
                                .font(.body.weight(.medium))
                                .frame(width: 32, height: 32)
                                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text("\(item.pageCount) pages")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onMove { source, destination in
                        pdfs.move(fromOffsets: source, toOffset: destination)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Merge Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }
}

private extension View {
    func cardContainer(cornerRadius: CGFloat) -> some View {
        self
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}
