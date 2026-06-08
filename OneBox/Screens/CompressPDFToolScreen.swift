import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct CompressPDFToolScreen: View {
    @State private var selectedPDF: URL?
    @State private var showFileImporter = false
    @State private var isCompressing = false
    @State private var generatedOutput: PDFOutput?
    @State private var statusMessage = "Select a PDF file to compress."
    @State private var previewDocument: PreviewDocument?
    @State private var compressionLevel: CompressionLevel = .medium
    
    private let cardCornerRadius: CGFloat = 24

    enum CompressionLevel: String, CaseIterable, Identifiable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var id: String { rawValue }
        var description: String {
            switch self {
            case .low: return "Better quality, larger size"
            case .medium: return "Balanced quality and size"
            case .high: return "Minimum size, lower quality"
            }
        }
    }

    var body: some View {
        mainContent
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Compress PDF")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
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
                optionsCard
                compressCard
                outputCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import PDF")
                .font(.headline)

            if let selectedPDF {
                HStack(spacing: 12) {
                    Image(systemName: "doc.richtext")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 38, height: 38)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedPDF.lastPathComponent)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        
                        if let size = try? selectedPDF.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button("Change") {
                        showFileImporter = true
                    }
                    .font(.caption.weight(.bold))
                }
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground).opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
            } else {
                Button {
                    showFileImporter = true
                } label: {
                    Label("Choose File", systemImage: "doc.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Compression Level")
                .font(.headline)

            Picker("Level", selection: $compressionLevel) {
                ForEach(CompressionLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Text(compressionLevel.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
        .disabled(selectedPDF == nil)
        .opacity(selectedPDF == nil ? 0.5 : 1)
    }

    private var compressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimize")
                .font(.headline)

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await compressPDF()
                }
            } label: {
                HStack {
                    if isCompressing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isCompressing ? "Compressing..." : "Start Compression")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedPDF == nil || isCompressing ? Color.gray.opacity(0.25) : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedPDF == nil || isCompressing)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    @ViewBuilder
    private var outputCard: some View {
        if let output = generatedOutput {
            VStack(alignment: .leading, spacing: 12) {
                Text("Result")
                    .font(.headline)

                HStack(spacing: 12) {
                    if let preview = output.previewImage {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(output.fileName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        Text("\(output.pageCount) pages • \(output.sizeLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let savings = output.savingsLabel {
                            Text("Reduced by \(savings)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green)
                        }
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
            guard let url = urls.first else { return }
            selectedPDF = url
            generatedOutput = nil
            statusMessage = "Ready to compress file."
        case .failure:
            statusMessage = "Could not import file."
        }
    }

    private func compressPDF() async {
        guard let url = selectedPDF else { return }

        await MainActor.run {
            isCompressing = true
            statusMessage = "Compressing PDF on-device..."
        }

        do {
            let output = try await PDFCompressionService.compressPDF(at: url, level: compressionLevel)

            await MainActor.run {
                generatedOutput = output
                isCompressing = false
                statusMessage = "PDF compressed successfully."
            }
        } catch {
            await MainActor.run {
                isCompressing = false
                statusMessage = "Compression failed. Try again."
            }
        }
    }
}

private struct PDFOutput {
    let url: URL
    let fileName: String
    let pageCount: Int
    let sizeLabel: String
    let previewImage: UIImage?
    let savingsLabel: String?
}

private struct PreviewDocument: Identifiable, Hashable {
    let id = UUID()
    let url: URL
}

private enum PDFCompressionService {
    nonisolated static func compressPDF(at url: URL, level: CompressPDFToolScreen.CompressionLevel) async throws -> PDFOutput {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        
        let originalSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        
        // --- HYBRID COMPRESSION LOGIC ---
        // 1. Try Professional API First
        // 2. Fallback to Native Rasterization if API key is missing or request fails
        
        var finalData: Data?
        var finalPageCount: Int = 0
        var wasAPISuccess = false
        
        if await OneBoxSecrets.hasValidPDFCoKey {
            do {
                finalData = try await PDFCoService.compressPDF(at: url)
                finalPageCount = PDFDocument(data: finalData!)?.pageCount ?? 0
                wasAPISuccess = true
            } catch {
                print("PDF.co API failed, falling back to native: \(error)")
            }
        }
        
        // Fallback to Native if API didn't happen or failed
        if finalData == nil {
            let (data, pageCount) = try await performNativeCompression(at: url, level: level)
            finalData = data
            finalPageCount = pageCount
        }
        
        guard let data = finalData else {
            throw NSError(domain: "PDFCompressionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to generate compressed PDF"])
        }

        let recordData = try await MainActor.run {
            let prefix = wasAPISuccess ? "OneBox-Pro" : "OneBox-Native"
            let record = try OneBoxFileStore.savePDF(data: data, fileName: prefix, pageCount: finalPageCount)
            return (record.fileURL, record.fileName, record.sizeLabel, record.pageCount ?? 0)
        }

        let outputURL = recordData.0
        let fileName = recordData.1
        let sizeLabel = recordData.2
        let totalPagesResult = recordData.3
        
        let newSize = (try? outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        let savings: String? = {
            if originalSize > newSize && originalSize > 0 {
                let diff = Double(originalSize - newSize) / Double(originalSize) * 100
                return String(format: "%.1f%%", diff)
            }
            return nil
        }()
        
        let previewImage = PDFDocument(url: outputURL)?.page(at: 0)?.thumbnail(of: CGSize(width: 140, height: 180), for: .mediaBox)

        return PDFOutput(
            url: outputURL,
            fileName: fileName,
            pageCount: totalPagesResult,
            sizeLabel: sizeLabel,
            previewImage: previewImage,
            savingsLabel: savings
        )
    }
    
    /// Our high-quality native fallback method
    private static func performNativeCompression(at url: URL, level: CompressPDFToolScreen.CompressionLevel) async throws -> (Data, Int) {
        guard let doc = PDFDocument(url: url) else {
            throw NSError(domain: "PDFCompressionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open PDF"])
        }
        
        let pageCount = doc.pageCount
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: .zero, format: format)
        
        let scale: CGFloat
        let quality: CGFloat
        
        switch level {
        case .low: scale = 2.0; quality = 0.8
        case .medium: scale = 1.5; quality = 0.5
        case .high: scale = 1.0; quality = 0.3
        }
        
        let pdfData = renderer.pdfData { context in
            for i in 0..<pageCount {
                guard let page = doc.page(at: i) else { continue }
                let mediaBox = page.bounds(for: .mediaBox)
                context.beginPage(withBounds: mediaBox, pageInfo: [:])
                let thumbSize = CGSize(width: mediaBox.width * scale, height: mediaBox.height * scale)
                let thumb = page.thumbnail(of: thumbSize, for: .mediaBox)
                if let compressedData = thumb.jpegData(compressionQuality: quality),
                   let compressedImage = UIImage(data: compressedData) {
                    compressedImage.draw(in: mediaBox)
                } else {
                    page.draw(with: .mediaBox, to: context.cgContext)
                }
            }
        }
        return (pdfData, pageCount)
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
