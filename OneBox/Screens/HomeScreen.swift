import PhotosUI
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

struct HomeScreen: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var showFileImporter = false
    @State private var showPhotosPicker = false
    @State private var showCameraPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImportItems: [ImportSelectionItem] = []
    @State private var activeSelectionID: UUID?
    @State private var showImportOptions = false
    @State private var importStatusText = "No recent import"
    @State private var importedDocument: ImportedDocument?
    @State private var showWorkspace = false
    @State private var storedFiles: [StoredAppFile] = []
    @State private var filePendingRename: StoredAppFile?
    @State private var renameText = ""
    @State private var showingRenameAlert = false

    private var recentFiles: [StoredAppFile] {
        Array(storedFiles.prefix(6))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    heroContent
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                Section("Recent Outputs") {
                    if recentFiles.isEmpty {
                        Text("No outputs yet. Generate something from a tool and it will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentFiles) { file in
                            NavigationLink(value: file) {
                                recentFileRow(file)
                            }
                            .contextMenu {
                                Button {
                                    beginRename(file)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }

                                ShareLink(item: file.fileURL) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }

                                Button(role: .destructive) {
                                    deleteFile(file)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteFile(file)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    beginRename(file)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Home")
            .navigationDestination(isPresented: $showWorkspace, destination: workspaceDestination)
            .navigationDestination(for: StoredAppFile.self) { file in
                HomeRecentFileDetailScreen(file: file)
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .photosPicker(
                isPresented: $showPhotosPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: nil,
                matching: .images
            )
            .sheet(isPresented: $showCameraPicker) {
                CameraPickerView(isPresented: $showCameraPicker) { image in
                    if let image {
                        selectedImportItems = [ImportSelectionItem.fromCamera(image: image)]
                        refreshImportedDocumentFromSelections()
                        importStatusText = "Captured 1 photo"
                    } else {
                        importStatusText = "Camera cancelled"
                    }
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItems) { _, newItems in
                handlePhotoSelections(newItems)
            }
            .onAppear {
                reloadRecentFiles()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    reloadRecentFiles()
                }
            }
            .alert("Rename File", isPresented: $showingRenameAlert) {
                TextField("New file name", text: $renameText)
                Button("Cancel", role: .cancel) {
                    filePendingRename = nil
                    renameText = ""
                }
                Button("Save") {
                    commitRename()
                }
            } message: {
                Text("Enter a new file name. Extension is kept automatically.")
            }
            .confirmationDialog("Import Document", isPresented: $showImportOptions, titleVisibility: .visible) {
                Button {
                    showPhotosPicker = true
                } label: {
                    Label("Photo Library", systemImage: "photo.on.rectangle")
                }

                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCameraPicker = true
                    } else {
                        importStatusText = "Camera not available"
                    }
                } label: {
                    Label("Take Photo or Video", systemImage: "camera")
                }

                Button {
                    showFileImporter = true
                } label: {
                    Label("Choose File", systemImage: "folder")
                }
            }
        }
    }

    private func recentFileRow(_ file: StoredAppFile) -> some View {
        HStack(spacing: 14) {
            HomeFileThumbnailView(file: file)

            VStack(alignment: .leading, spacing: 5) {
                Text(file.fileName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                let pagesText = file.pageCount.map { " • \($0) pages" } ?? ""
                Text("\(file.createdAt.formatted(date: .abbreviated, time: .shortened)) • \(file.sizeLabel)\(pagesText)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(file.typeLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .oneBoxSecondaryPill(cornerRadius: 999)
        }
            .padding(.vertical, 10)
    }

    @ViewBuilder
    private var heroContent: some View {
        if let document = importedDocument {
            ImportedHeroCard(
                document: document,
                previewDocument: heroPreviewDocument,
                selectedItems: selectedImportItems,
                activeSelectedItemID: activeSelectionID,
                onReplaceFromPhotos: {
                    showPhotosPicker = true
                },
                onReplaceFromCamera: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCameraPicker = true
                    } else {
                        importStatusText = "Camera not available"
                    }
                },
                onReplaceFromFiles: {
                    showFileImporter = true
                },
                onCancel: {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedImportItems = []
                        importedDocument = nil
                        importStatusText = "No recent import"
                    }
                },
                onContinue: {
                    showWorkspace = true
                },
                showActionButtons: true,
                onRemoveSelectedItem: { id in
                    selectedImportItems.removeAll { $0.id == id }
                    if activeSelectionID == id {
                        activeSelectionID = selectedImportItems.first?.id
                    }
                    refreshImportedDocumentFromSelections()
                    if selectedImportItems.isEmpty {
                        importStatusText = "No recent import"
                    }
                }
                ,
                onSelectSelectedItem: { id in
                    activeSelectionID = id
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            importMenuCard
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    private var importMenuCard: some View {
        Button {
            showImportOptions = true
        } label: {
            ImportHeroLabel(statusText: importStatusText)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func workspaceDestination() -> some View {
        if let document = importedDocument {
            DocumentWorkspaceScreen(
                document: document,
                previewDocument: heroPreviewDocument,
                selectedItems: selectedImportItems,
                activeSelectedItemID: activeSelectionID,
                onReplaceFromPhotos: {
                    showWorkspace = false
                    DispatchQueue.main.async {
                        showPhotosPicker = true
                    }
                },
                onReplaceFromCamera: {
                    showWorkspace = false
                    DispatchQueue.main.async {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCameraPicker = true
                        } else {
                            importStatusText = "Camera not available"
                        }
                    }
                },
                onReplaceFromFiles: {
                    showWorkspace = false
                    DispatchQueue.main.async {
                        showFileImporter = true
                    }
                },
                onCancelDocument: {
                    showWorkspace = false
                    selectedImportItems = []
                    importedDocument = nil
                    importStatusText = "No recent import"
                },
                onRemoveSelectedItem: { id in
                    selectedImportItems.removeAll { $0.id == id }
                    if activeSelectionID == id {
                        activeSelectionID = selectedImportItems.first?.id
                    }
                    refreshImportedDocumentFromSelections()
                    if selectedImportItems.isEmpty {
                        showWorkspace = false
                        importStatusText = "No recent import"
                    }
                }
                ,
                onSelectSelectedItem: { id in
                    activeSelectionID = id
                }
            )
        } else {
            EmptyView()
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importStatusText = "Imported \(urls.count) file\(urls.count == 1 ? "" : "s")"
            selectedImportItems = urls.map(ImportSelectionItem.fromFile)
            activeSelectionID = selectedImportItems.first?.id
            refreshImportedDocumentFromSelections()
        case .failure:
            importStatusText = "Import failed"
        }
    }

    private func handlePhotoSelections(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            var loadedImages: [(image: UIImage, bytes: Int)] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append((image, data.count))
                }
            }

            await MainActor.run {
                if !loadedImages.isEmpty {
                    selectedImportItems = loadedImages.enumerated().map { index, element in
                        ImportSelectionItem.fromPhoto(image: element.image, byteCount: element.bytes, index: index)
                    }
                    activeSelectionID = selectedImportItems.first?.id
                    refreshImportedDocumentFromSelections()
                    importStatusText = "Imported \(loadedImages.count) photo\(loadedImages.count == 1 ? "" : "s")"
                } else {
                    importStatusText = "Photo import failed"
                }
                selectedPhotoItems = []
            }
        }
    }

    private func refreshImportedDocumentFromSelections() {
        importedDocument = ImportedDocument.fromSelections(selectedImportItems)
    }

    private var heroPreviewDocument: ImportedDocument? {
        guard let document = importedDocument else { return nil }
        guard let activeSelectionID,
              let selectedItem = selectedImportItems.first(where: { $0.id == activeSelectionID }) else {
            return document
        }

        return document.withPreview(
            previewImage: selectedItem.previewImage,
            previewURL: selectedItem.fileURL,
            previewKey: activeSelectionID.uuidString
        )
    }

    private func reloadRecentFiles() {
        storedFiles = OneBoxFileStore.loadAll()
    }

    private func beginRename(_ file: StoredAppFile) {
        filePendingRename = file
        renameText = (file.fileName as NSString).deletingPathExtension
        showingRenameAlert = true
    }

    private func commitRename() {
        guard let file = filePendingRename else { return }
        let newName = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }

        do {
            _ = try OneBoxFileStore.rename(fileID: file.id, newName: newName)
            reloadRecentFiles()
        } catch {
            // Keep the UI calm for now; we can add explicit error toast later.
        }

        filePendingRename = nil
        renameText = ""
    }

    private func deleteFile(_ file: StoredAppFile) {
        do {
            try OneBoxFileStore.delete(fileID: file.id)
            reloadRecentFiles()
        } catch {
            // Keep the UI calm for now; we can add explicit error toast later.
        }
    }
}

private struct HomeRecentFileDetailScreen: View {
    let file: StoredAppFile

    var body: some View {
        QuickLookDocumentPreview(url: file.fileURL)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(file.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: file.fileURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
    }
}

private struct HomeFileThumbnailView: View {
    let file: StoredAppFile

    @Environment(\.displayScale) private var displayScale
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: file.iconName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                    .background(Color(.tertiarySystemGroupedBackground))
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(.separator).opacity(0.25), lineWidth: 0.5)
        )
        .task(id: file.id) {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let request = QLThumbnailGenerator.Request(
            fileAt: file.fileURL,
            size: CGSize(width: 84, height: 84),
            scale: max(displayScale, 1),
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
            guard let representation else { return }
            DispatchQueue.main.async {
                thumbnail = representation.uiImage
            }
        }
    }
}
