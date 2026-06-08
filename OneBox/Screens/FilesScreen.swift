import QuickLookThumbnailing
import SwiftUI

struct FilesScreen: View {
    @State private var searchText = ""
    @State private var storedFiles: [StoredAppFile] = []
    @State private var filePendingRename: StoredAppFile?
    @State private var renameText = ""
    @State private var showingRenameAlert = false

    private var visibleFiles: [StoredAppFile] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return storedFiles }

        return storedFiles.filter {
            $0.fileName.localizedCaseInsensitiveContains(query)
                || $0.typeLabel.localizedCaseInsensitiveContains(query)
        }
    }

    private var collections: [FileCollection] {
        [
            .init(title: "Recent", icon: "clock", count: storedFiles.count, filter: .recent),
            .init(title: "PDF", icon: "doc.richtext", count: storedFiles.filter { $0.kind == .pdf }.count, filter: .pdf),
            .init(title: "Images", icon: "photo", count: storedFiles.filter { $0.kind == .image }.count, filter: .images),
            .init(title: "Other", icon: "doc", count: storedFiles.filter { $0.kind == .other }.count, filter: .other)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Collections")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        ForEach(collections) { collection in
                            NavigationLink(value: collection.filter) {
                                collectionRow(collection)
                                    .oneBoxGlassCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("OneBox Outputs")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        if visibleFiles.isEmpty {
                            Text("No files yet. Generated outputs like Image to PDF will appear here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                                .oneBoxGlassCard()
                        } else {
                            ForEach(visibleFiles) { file in
                                NavigationLink(value: file) {
                                    fileRow(file)
                                        .oneBoxGlassCard()
                                }
                                .buttonStyle(.plain)
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
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
            .navigationTitle("Files")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search files"
            )
            .navigationDestination(for: StoredAppFile.self) { file in
                StoredFileDetailScreen(file: file)
            }
            .navigationDestination(for: FileCollectionFilter.self) { filter in
                CollectionFilesScreen(filter: filter)
            }
            .onAppear {
                reloadFiles()
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
        }
    }

    private func fileRow(_ file: StoredAppFile) -> some View {
        HStack(spacing: 14) {
            FileThumbnailView(file: file)

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

    private func collectionRow(_ collection: FileCollection) -> some View {
        HStack(spacing: 14) {
            Image(systemName: collection.icon)
                .font(.body.weight(.medium))
                .frame(width: 34, height: 34)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(collection.title)
                    .font(.subheadline.weight(.semibold))

                Text(collection.count == 1 ? "1 item" : "\(collection.count) items")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(collection.count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .oneBoxSecondaryPill(cornerRadius: 999)
        }
    }

    private func files(for filter: FileCollectionFilter) -> [StoredAppFile] {
        switch filter {
        case .recent:
            return storedFiles
        case .pdf:
            return storedFiles.filter { $0.kind == .pdf }
        case .images:
            return storedFiles.filter { $0.kind == .image }
        case .other:
            return storedFiles.filter { $0.kind == .other }
        }
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
            reloadFiles()
        } catch {
            // Keep the UI calm for now; we can add explicit error toast later.
        }

        filePendingRename = nil
        renameText = ""
    }

    private func deleteFile(_ file: StoredAppFile) {
        do {
            try OneBoxFileStore.delete(fileID: file.id)
            reloadFiles()
        } catch {
            // Keep the UI calm for now; we can add explicit error toast later.
        }
    }

    private func reloadFiles() {
        storedFiles = OneBoxFileStore.loadAll()
    }
}

private struct StoredFileDetailScreen: View {
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

private struct CollectionFilesScreen: View {
    let filter: FileCollectionFilter

    @State private var storedFiles: [StoredAppFile] = []
    @State private var filePendingRename: StoredAppFile?
    @State private var renameText = ""
    @State private var showingRenameAlert = false

    private var files: [StoredAppFile] {
        switch filter {
        case .recent:
            return storedFiles
        case .pdf:
            return storedFiles.filter { $0.kind == .pdf }
        case .images:
            return storedFiles.filter { $0.kind == .image }
        case .other:
            return storedFiles.filter { $0.kind == .other }
        }
    }

    var body: some View {
        List {
            if files.isEmpty {
                Text("No files in this collection yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(files) { file in
                    NavigationLink(value: file) {
                        HStack(spacing: 14) {
                            FileThumbnailView(file: file)

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
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
        .listStyle(.insetGrouped)
        .navigationTitle(filter.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: StoredAppFile.self) { file in
            StoredFileDetailScreen(file: file)
        }
        .onAppear {
            reloadFiles()
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
    }

    private func reloadFiles() {
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
            reloadFiles()
        } catch {
            // Keep the UI calm for now; we can add explicit error toast later.
        }

        filePendingRename = nil
        renameText = ""
    }

    private func deleteFile(_ file: StoredAppFile) {
        do {
            try OneBoxFileStore.delete(fileID: file.id)
            reloadFiles()
        } catch {
            // Keep the UI calm for now; we can add explicit error toast later.
        }
    }
}

private struct FileThumbnailView: View {
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

private enum FileCollectionFilter: Hashable {
    case recent
    case pdf
    case images
    case other

    var title: String {
        switch self {
        case .recent:
            return "Recent"
        case .pdf:
            return "PDF"
        case .images:
            return "Images"
        case .other:
            return "Other"
        }
    }
}

private struct FileCollection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let count: Int
    let filter: FileCollectionFilter
}
