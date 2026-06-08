import PDFKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import VisionKit
import CoreImage
import CoreImage.CIFilterBuiltins
struct ImageToPDFToolScreen: View {
    @State private var photoSelections: [PhotosPickerItem] = []
    @State private var selectedImages: [SelectedImageItem] = []
    @State private var showFileImporter = false
    @State private var showDocumentScanner = false
    @State private var isGenerating = false
    @State private var generatedOutput: PDFOutput?
    @State private var statusMessage = "Select one or more images to generate a PDF."
    @State private var selectedFilter: PDFImageFilter = .none
    @State private var showSequenceEditor = false
    @State private var previewDocument: PreviewDocument?
    
    // New: Support for pre-selected images from workspace
    private var initialItems: [ImportSelectionItem]?
    
    init(initialItems: [ImportSelectionItem]? = nil) {
        self.initialItems = initialItems
    }

    private let cardCornerRadius: CGFloat = 24

    var body: some View {
        mainContent
            .onAppear {
                loadInitialItems()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Image to PDF")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .onChange(of: photoSelections) { _, newItems in
                Task {
                    await handlePhotoSelections(newItems)
                }
            }
            .sheet(isPresented: $showSequenceEditor) {
                ImageSequenceEditorSheet(images: $selectedImages)
            }
            .sheet(isPresented: $showDocumentScanner) {
                DocumentScannerView(
                    onCancel: {
                        statusMessage = "Scan cancelled."
                    },
                    onFail: { _ in
                        statusMessage = "Scanner failed. Try again."
                    },
                    onComplete: { scannedImages in
                        appendScannedImages(scannedImages)
                    }
                )
            }
            .navigationDestination(item: $previewDocument) { document in
                QuickLookDocumentPreview(url: document.url)
                    .ignoresSafeArea()
            }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inputCard
                selectedImagesCard
                generateCard
                outputCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }
    
    private func loadInitialItems() {
        guard let items = initialItems, !selectedImages.isEmpty == false else { return }
        
        let loaded = items.compactMap { item -> SelectedImageItem? in
            if let image = item.previewImage {
                return SelectedImageItem(image: image, name: item.name)
            } else if let url = item.fileURL {
                let secured = url.startAccessingSecurityScopedResource()
                defer {
                    if secured {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else {
                    return nil
                }
                return SelectedImageItem(image: image, name: item.name)
            }
            return nil
        }
        
        if !loaded.isEmpty {
            selectedImages = loaded
            statusMessage = "Ready to generate a \(loaded.count)-page PDF."
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(PDFImageFilter.allCases) { filter in
                Text(filter.label).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import Images")
                .font(.headline)

            Text("Choose from Photos, Files, or Scan. Everything is processed on-device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                PhotosPicker(selection: $photoSelections, maxSelectionCount: nil, matching: .images) {
                    Label("Photos", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    if VNDocumentCameraViewController.isSupported {
                        showDocumentScanner = true
                    } else {
                        statusMessage = "Scanner is not supported on this device."
                    }
                } label: {
                    Label("Scan", systemImage: "doc.viewfinder")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    showFileImporter = true
                } label: {
                    Label("Files", systemImage: "folder")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private var selectedImagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected")
                    .font(.headline)

                Spacer()

                Text("\(selectedImages.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    showSequenceEditor = true
                } label: {
                    Label("Edit sequence", systemImage: "arrow.up.arrow.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedImages.count > 1 ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(selectedImages.count <= 1)

                Spacer()

                Text("Filter: \(selectedFilter.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            filterPicker

            if selectedImages.isEmpty {
                Text("No images selected yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(selectedImages) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: ImageToPDFService.filteredImage(for: item.image, filter: selectedFilter))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 108, height: 108)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                    Button {
                                        removeSelectedImage(item.id)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.primary)
                                            .padding(6)
                                            .background(.ultraThinMaterial, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(5)
                                }

                                Text(item.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 108)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private var generateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create PDF")
                .font(.headline)

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await openNativePreviewFromBuild()
                }
            } label: {
                Label("Open Native PDF Preview", systemImage: "doc.viewfinder")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedImages.isEmpty || isGenerating)

            Button {
                Task {
                    await generatePDF()
                }
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isGenerating ? "Generating..." : "Generate PDF")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedImages.isEmpty || isGenerating ? Color.gray.opacity(0.25) : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedImages.isEmpty || isGenerating)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    @ViewBuilder
    private var outputCard: some View {
        if let output = generatedOutput {
            VStack(alignment: .leading, spacing: 12) {
                Text("Output")
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

                        if output.savedInOneBox {
                            Text("Saved in OneBox > Files")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                ShareLink(item: output.url) {
                    Label("Share or Save", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .cardContainer(cornerRadius: cardCornerRadius)
        }
    }

    private func handlePhotoSelections(_ newItems: [PhotosPickerItem]) async {
        guard !newItems.isEmpty else { return }

        var loaded: [SelectedImageItem] = []
        for (index, item) in newItems.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(
                    SelectedImageItem(
                        image: image,
                        name: "Photo \(index + 1)"
                    )
                )
            }
        }

        await MainActor.run {
            selectedImages = loaded
            generatedOutput = nil
            statusMessage = loaded.isEmpty
                ? "Could not load selected photos."
                : "Ready to generate a \(loaded.count)-page PDF."
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let loaded = urls.compactMap { url -> SelectedImageItem? in
                let secured = url.startAccessingSecurityScopedResource()
                defer {
                    if secured {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else {
                    return nil
                }

                return SelectedImageItem(image: image, name: url.lastPathComponent)
            }

            selectedImages = loaded
            generatedOutput = nil
            statusMessage = loaded.isEmpty
                ? "Could not load selected files."
                : "Ready to generate a \(loaded.count)-page PDF."

        case .failure:
            statusMessage = "Could not import files."
        }
    }

    private func removeSelectedImage(_ id: UUID) {
        selectedImages.removeAll { $0.id == id }
        generatedOutput = nil
        statusMessage = selectedImages.isEmpty
            ? "Select one or more images to generate a PDF."
            : "Ready to generate a \(selectedImages.count)-page PDF."
    }

    private func appendScannedImages(_ scannedImages: [UIImage]) {
        guard !scannedImages.isEmpty else {
            statusMessage = "No pages were scanned."
            return
        }

        let baseCount = selectedImages.count
        let appended = scannedImages.enumerated().map { index, image in
            SelectedImageItem(image: image, name: "Scan \(baseCount + index + 1)")
        }

        selectedImages.append(contentsOf: appended)
        generatedOutput = nil
        statusMessage = "Scanned \(scannedImages.count) page\(scannedImages.count == 1 ? "" : "s"). Ready to generate a \(selectedImages.count)-page PDF."
    }

    private func generatePDF() async {
        guard !selectedImages.isEmpty else { return }

        await MainActor.run {
            isGenerating = true
            statusMessage = "Generating PDF on-device..."
        }

        let images = selectedImages.map(\.image)

        do {
            let filter = selectedFilter
            let output = try await ImageToPDFService.generatePDF(from: images, filter: filter)

            await MainActor.run {
                generatedOutput = output
                isGenerating = false
                statusMessage = "PDF generated successfully."
            }
        } catch {
            await MainActor.run {
                isGenerating = false
                statusMessage = "PDF generation failed. Try again."
            }
        }
    }

    private func openNativePreviewFromBuild() async {
        guard !selectedImages.isEmpty else { return }

        let images = selectedImages.map(\.image)
        let filter = selectedFilter

        do {
            let data = try await Task.detached(priority: .userInitiated) {
                try ImageToPDFService.makePDFData(from: images, filter: filter)
            }.value

            let fileName = "OneBox-Preview-\(Int(Date().timeIntervalSince1970)).pdf"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: url, options: .atomic)

            await MainActor.run {
                previewDocument = PreviewDocument(url: url)
            }
        } catch {
            await MainActor.run {
                statusMessage = "Could not open native preview."
            }
        }
    }
}

private struct PreviewDocument: Identifiable, Hashable {
    let id = UUID()
    let url: URL
}

private struct SelectedImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let name: String
}

private struct PDFOutput {
    let url: URL
    let fileName: String
    let pageCount: Int
    let sizeLabel: String
    let previewImage: UIImage?
    let savedInOneBox: Bool
}

enum PDFImageFilter: String, CaseIterable, Identifiable {
    case none
    case mono
    case vivid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .mono: return "Mono"
        case .vivid: return "Vivid"
        }
    }
}

private enum ImageToPDFService {
    nonisolated static func generatePDF(from images: [UIImage], filter: PDFImageFilter) async throws -> PDFOutput {
        let data = try await Task.detached(priority: .userInitiated) {
            try makePDFData(from: images, filter: filter)
        }.value

        let recordData = try await MainActor.run {
            let record = try OneBoxFileStore.savePDF(data: data, fileName: "OneBox-Image-to-PDF", pageCount: images.count)
            return (record.fileURL, record.fileName, record.sizeLabel)
        }

        let outputURL = recordData.0
        let fileName = recordData.1
        let sizeLabel = recordData.2
        let previewImage = PDFDocument(url: outputURL)?.page(at: 0)?.thumbnail(of: CGSize(width: 140, height: 180), for: .mediaBox)

        return PDFOutput(
            url: outputURL,
            fileName: fileName,
            pageCount: images.count,
            sizeLabel: sizeLabel,
            previewImage: previewImage,
            savedInOneBox: true
        )
    }

    nonisolated static func makePDFData(from images: [UIImage], filter: PDFImageFilter) throws -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            for image in images {
                context.beginPage()
                let drawRect = fittedRect(for: image.size, in: pageRect.insetBy(dx: 24, dy: 24))
                filteredImage(for: image, filter: filter).draw(in: drawRect)
            }
        }
    }

    nonisolated static func filteredImage(for image: UIImage, filter: PDFImageFilter) -> UIImage {
        guard filter != .none, let cgImage = image.cgImage else {
            return image
        }

        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)

        let output: CIImage?
        switch filter {
        case .none:
            output = ciImage
        case .mono:
            let f = CIFilter.colorControls()
            f.inputImage = ciImage
            f.saturation = 0
            f.contrast = 1.1
            output = f.outputImage
        case .vivid:
            let f = CIFilter.colorControls()
            f.inputImage = ciImage
            f.saturation = 1.35
            f.contrast = 1.08
            f.brightness = 0.02
            output = f.outputImage
        }

        guard let finalImage = output,
              let outputCG = context.createCGImage(finalImage, from: finalImage.extent) else {
            return image
        }

        return UIImage(cgImage: outputCG, scale: image.scale, orientation: image.imageOrientation)
    }

    nonisolated private static func fittedRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }

        let imageAspect = imageSize.width / imageSize.height
        let boundsAspect = bounds.width / bounds.height

        if imageAspect > boundsAspect {
            let width = bounds.width
            let height = width / imageAspect
            return CGRect(
                x: bounds.minX,
                y: bounds.midY - height / 2,
                width: width,
                height: height
            )
        } else {
            let height = bounds.height
            let width = height * imageAspect
            return CGRect(
                x: bounds.midX - width / 2,
                y: bounds.minY,
                width: width,
                height: height
            )
        }
    }
}

private struct ImageSequenceEditorSheet: View {
    @Binding var images: [SelectedImageItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Drag to reorder") {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            Image(uiImage: item.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Page \(index + 1)")
                                    .font(.subheadline.weight(.semibold))
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onMove { source, destination in
                        images.move(fromOffsets: source, toOffset: destination)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Image Sequence")
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
