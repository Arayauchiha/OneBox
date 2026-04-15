import Foundation

struct StoredAppFile: Identifiable, Codable, Hashable {
    let id: UUID
    let fileName: String
    let relativePath: String
    let kind: StoredAppFileKind
    let sizeBytes: Int64
    let pageCount: Int?
    let createdAt: Date

    var fileURL: URL {
        OneBoxFileStore.documentsDirectory.appendingPathComponent(relativePath)
    }

    var sizeLabel: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    var typeLabel: String {
        switch kind {
        case .pdf: return "PDF"
        case .image: return "IMG"
        case .other: return "FILE"
        }
    }

    var iconName: String {
        switch kind {
        case .pdf: return "doc.richtext"
        case .image: return "photo"
        case .other: return "doc"
        }
    }
}

enum StoredAppFileKind: String, Codable, Hashable {
    case pdf
    case image
    case other
}

enum OneBoxFileStore {
    static let outputsFolderName = "GeneratedOutputs"

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var outputsDirectory: URL {
        documentsDirectory.appendingPathComponent(outputsFolderName, isDirectory: true)
    }

    private static var recordsURL: URL {
        documentsDirectory.appendingPathComponent("onebox-files.json")
    }

    static func savePDF(data: Data, fileName: String, pageCount: Int) throws -> StoredAppFile {
        try FileManager.default.createDirectory(at: outputsDirectory, withIntermediateDirectories: true)

        let normalizedName = sanitizedFileName(fileName)
        let uniqueName = makeUniqueFileName(baseName: normalizedName, ext: "pdf")
        let relativePath = "\(outputsFolderName)/\(uniqueName)"
        let targetURL = documentsDirectory.appendingPathComponent(relativePath)

        try data.write(to: targetURL, options: .atomic)

        let record = StoredAppFile(
            id: UUID(),
            fileName: uniqueName,
            relativePath: relativePath,
            kind: .pdf,
            sizeBytes: Int64(data.count),
            pageCount: pageCount,
            createdAt: Date()
        )

        try append(record)
        return record
    }

    static func loadAll() -> [StoredAppFile] {
        guard let data = try? Data(contentsOf: recordsURL),
              let files = try? JSONDecoder().decode([StoredAppFile].self, from: data) else {
            return []
        }

        return files.sorted { $0.createdAt > $1.createdAt }
    }

    static func rename(fileID: UUID, newName: String) throws -> StoredAppFile {
        var current = loadAll()
        guard let index = current.firstIndex(where: { $0.id == fileID }) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let original = current[index]
        let ext = (original.fileName as NSString).pathExtension
        let base = sanitizedFileName(newName)
        let uniqueName = makeUniqueFileName(baseName: base, ext: ext.isEmpty ? "pdf" : ext)
        let newRelativePath = "\(outputsFolderName)/\(uniqueName)"

        try FileManager.default.createDirectory(at: outputsDirectory, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: original.fileURL, to: documentsDirectory.appendingPathComponent(newRelativePath))

        let updated = StoredAppFile(
            id: original.id,
            fileName: uniqueName,
            relativePath: newRelativePath,
            kind: original.kind,
            sizeBytes: original.sizeBytes,
            pageCount: original.pageCount,
            createdAt: original.createdAt
        )

        current[index] = updated
        try writeAll(current)
        return updated
    }

    static func delete(fileID: UUID) throws {
        var current = loadAll()
        guard let index = current.firstIndex(where: { $0.id == fileID }) else {
            return
        }

        let file = current[index]
        if FileManager.default.fileExists(atPath: file.fileURL.path) {
            try FileManager.default.removeItem(at: file.fileURL)
        }

        current.remove(at: index)
        try writeAll(current)
    }

    private static func append(_ file: StoredAppFile) throws {
        var current = loadAll()
        current.removeAll { $0.fileURL.path == file.fileURL.path }
        current.insert(file, at: 0)

        try writeAll(current)
    }

    private static func writeAll(_ files: [StoredAppFile]) throws {
        let data = try JSONEncoder().encode(files)
        try data.write(to: recordsURL, options: .atomic)
    }

    private static func makeUniqueFileName(baseName: String, ext: String) -> String {
        let extWithDot = ".\(ext)"
        let trimmed = baseName.replacingOccurrences(of: extWithDot, with: "")
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(trimmed)-\(timestamp)\(extWithDot)"
    }

    private static func sanitizedFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let transformed = value
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }

        let compact = String(transformed)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return compact.isEmpty ? "OneBox-Output" : compact
    }
}
