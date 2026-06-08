import SwiftUI
import PhotosUI
import VisionKit
import PDFKit
import Vision

struct OCRToolScreen: View {
    @State private var photoSelection: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var sourceFileURL: URL?
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var statusMessage = "Select an image or document to extract text."
    @State private var showDocumentScanner = false
    @State private var showFileImporter = false
    @State private var showCopyToast = false
    
    // Support for pre-selected items from Home Screen Hero Card
    private var initialItems: [ImportSelectionItem]?
    
    init(initialItems: [ImportSelectionItem]? = nil) {
        self.initialItems = initialItems
    }
    
    private let cardCornerRadius: CGFloat = 24

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inputCard
                
                if let image = selectedImage {
                    previewCard(image)
                    actionCard
                }
                
                if !recognizedText.isEmpty {
                    resultCard
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("OCR Text Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadInitialItems()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .onChange(of: photoSelection) { _, newItem in
            Task {
                await handlePhotoSelection(newItem)
            }
        }
        .sheet(isPresented: $showDocumentScanner) {
            DocumentScannerView(
                onCancel: { statusMessage = "Scan cancelled." },
                onFail: { _ in statusMessage = "Scanner failed." },
                onComplete: { images in
                    if let first = images.first {
                        selectedImage = first
                        sourceFileURL = nil
                        recognizedText = ""
                        statusMessage = "Image ready for OCR."
                    }
                }
            )
        }
        .overlay(alignment: .bottom) {
            if showCopyToast {
                toastView
            }
        }
    }

    // MARK: - UI Components

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Import Source")
                .font(.headline)

            HStack(spacing: 10) {
                PhotosPicker(selection: $photoSelection, matching: .images) {
                    Label("Photos", systemImage: "photo.on.rectangle")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    showDocumentScanner = true
                } label: {
                    Label("Scan", systemImage: "doc.viewfinder")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    showFileImporter = true
                } label: {
                    Label("Files", systemImage: "folder")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private func previewCard(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .frame(maxWidth: .infinity)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Extraction")
                .font(.headline)
            
            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await startExtraction()
                }
            } label: {
                HStack {
                    if isProcessing {
                        ProgressView().tint(.white).padding(.trailing, 8)
                    }
                    Text(isProcessing ? "Analyzing..." : "Extract Text")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isProcessing ? Color.gray.opacity(0.3) : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isProcessing || selectedImage == nil)
            .buttonStyle(.plain)
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private func startExtraction() async {
        await MainActor.run {
            isProcessing = true
            statusMessage = "Analyzing with local AI..."
        }
        
        // 1. Try Native OCR first
        let nativeText = await performNativeOCR()
        
        if !nativeText.isEmpty {
            await MainActor.run {
                recognizedText = nativeText
                isProcessing = false
                statusMessage = "Extraction Complete (Local)."
            }
        } else {
            // 2. Fallback to Cloud if Native fails
            await MainActor.run {
                statusMessage = "Local AI struggled. Switching to Cloud AI..."
            }
            
            do {
                let cloudText = try await performCloudOCR()
                await MainActor.run {
                    recognizedText = cloudText
                    isProcessing = false
                    statusMessage = "Extraction Complete (Cloud)."
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    statusMessage = "Extraction Failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func performNativeOCR() async -> String {
        guard let image = selectedImage, let cgImage = image.cgImage else { return "" }
        
        return await withCheckedContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: "")
                    return
                }
                
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: extractedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    private func performCloudOCR() async throws -> String {
        let urlToProcess: URL?
        
        if let existingURL = sourceFileURL {
            urlToProcess = existingURL
        } else if let image = selectedImage {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ocr_input.jpg")
            guard let data = image.jpegData(compressionQuality: 0.8) else { 
                throw NSError(domain: "OCR", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not process image."])
            }
            try? data.write(to: tempURL)
            urlToProcess = tempURL
        } else {
            throw NSError(domain: "OCR", code: 2, userInfo: [NSLocalizedDescriptionKey: "No source found."])
        }
        
        guard let finalURL = urlToProcess else { 
            throw NSError(domain: "OCR", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid file path."])
        }
        
        let isPDF = finalURL.pathExtension.lowercased() == "pdf"
        return try await PDFCoService.performOCR(at: finalURL, isPDF: isPDF)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Extracted Text")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = recognizedText
                    withAnimation { showCopyToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showCopyToast = false }
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1), in: Capsule())
                }
            }
            
            Text(recognizedText)
                .font(.system(.subheadline, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .cardContainer(cornerRadius: cardCornerRadius)
    }

    private var toastView: some View {
        Text("Copied to clipboard")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Logic & Handlers

    private func loadInitialItems() {
        guard let items = initialItems, !items.isEmpty, selectedImage == nil else { return }
        
        if let first = items.first {
            if let url = first.fileURL {
                let secured = url.startAccessingSecurityScopedResource()
                defer { if secured { url.stopAccessingSecurityScopedResource() } }
                
                if url.pathExtension.lowercased() == "pdf" {
                    if let doc = PDFDocument(url: url), let page = doc.page(at: 0) {
                        self.selectedImage = page.thumbnail(of: CGSize(width: 300, height: 400), for: .mediaBox)
                    }
                    self.sourceFileURL = url
                    self.statusMessage = "PDF imported. Ready for OCR."
                } else if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    self.selectedImage = image
                    self.sourceFileURL = nil
                    self.statusMessage = "Image imported. Ready for OCR."
                }
            } else if let image = first.previewImage {
                self.selectedImage = image
                self.sourceFileURL = nil
                self.statusMessage = "Image imported. Ready for OCR."
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            
            if url.pathExtension.lowercased() == "pdf" {
                if let doc = PDFDocument(url: url), let page = doc.page(at: 0) {
                    selectedImage = page.thumbnail(of: CGSize(width: 300, height: 400), for: .mediaBox)
                }
                sourceFileURL = url
                recognizedText = ""
                statusMessage = "PDF loaded from Files."
            } else if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                selectedImage = image
                sourceFileURL = nil
                recognizedText = ""
                statusMessage = "Image loaded from Files."
            }
        case .failure(let error):
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                selectedImage = image
                sourceFileURL = nil
                recognizedText = ""
                statusMessage = "Image loaded. Ready for OCR."
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
