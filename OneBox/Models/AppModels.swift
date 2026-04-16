import Foundation
import UniformTypeIdentifiers
import UIKit

struct QuickOperation: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct OperationItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

enum ImportedDocumentKind {
    case image
    case pdf
    case other
}

enum ImportSelectionSource: String {
    case photos
    case camera
    case files
}

struct ImportSelectionItem: Identifiable {
    let id = UUID()
    let name: String
    let source: ImportSelectionSource
    let previewImage: UIImage?
    let byteCount: Int?
    let fileURL: URL?
    let typeLabel: String
    let systemIcon: String

    static func fromPhoto(image: UIImage, byteCount: Int, index: Int) -> ImportSelectionItem {
        ImportSelectionItem(
            name: "Photo \(index + 1)",
            source: .photos,
            previewImage: image,
            byteCount: byteCount,
            fileURL: nil,
            typeLabel: "JPG",
            systemIcon: "photo"
        )
    }

    static func fromCamera(image: UIImage) -> ImportSelectionItem {
        ImportSelectionItem(
            name: "Captured Image",
            source: .camera,
            previewImage: image,
            byteCount: nil,
            fileURL: nil,
            typeLabel: "JPG",
            systemIcon: "camera"
        )
    }

    static func fromFile(url: URL) -> ImportSelectionItem {
        let ext = url.pathExtension.uppercased()
        let type = UTType(filenameExtension: url.pathExtension)
        let icon: String = {
            if type?.conforms(to: .image) == true { return "photo" }
            if type?.conforms(to: .pdf) == true { return "doc.richtext" }
            return "doc"
        }()

        return ImportSelectionItem(
            name: url.lastPathComponent,
            source: .files,
            previewImage: UIImage(contentsOfFile: url.path),
            byteCount: (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize),
            fileURL: url,
            typeLabel: ext.isEmpty ? "FILE" : ext,
            systemIcon: icon
        )
    }
}

struct ImportedDocument {
    let id = UUID()
    let name: String
    let typeLabel: String
    let sizeLabel: String
    let pagesLabel: String
    let sourceLabel: String
    let importedAtLabel: String
    let systemIcon: String
    let previewImage: UIImage?
    let previewURL: URL?
    let previewKey: String
    let kind: ImportedDocumentKind

    func withPreview(previewImage: UIImage?, previewURL: URL?, previewKey: String) -> ImportedDocument {
        ImportedDocument(
            name: name,
            typeLabel: typeLabel,
            sizeLabel: sizeLabel,
            pagesLabel: pagesLabel,
            sourceLabel: sourceLabel,
            importedAtLabel: importedAtLabel,
            systemIcon: systemIcon,
            previewImage: previewImage,
            previewURL: previewURL,
            previewKey: previewKey,
            kind: kind
        )
    }

    static func fromImportedFile(url: URL) -> ImportedDocument {
        let ext = url.pathExtension.uppercased()
        let type = UTType(filenameExtension: url.pathExtension)
        let kind: ImportedDocumentKind = {
            if type?.conforms(to: .image) == true { return .image }
            if type?.conforms(to: .pdf) == true { return .pdf }
            return .other
        }()

        let icon: String = {
            switch kind {
            case .image: return "photo"
            case .pdf: return "doc.richtext"
            case .other: return "doc"
            }
        }()

        let byteCount = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        let size = ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)

        return ImportedDocument(
            name: url.lastPathComponent,
            typeLabel: ext.isEmpty ? "FILE" : ext,
            sizeLabel: size,
            pagesLabel: kind == .pdf ? "PDF" : "-",
            sourceLabel: "Files",
            importedAtLabel: Date().formatted(date: .omitted, time: .shortened),
            systemIcon: icon,
            previewImage: nil,
            previewURL: kind == .pdf ? url : nil,
            previewKey: url.absoluteString,
            kind: kind
        )
    }

    static func fromPhotoLibraryImage(_ image: UIImage, byteCount: Int) -> ImportedDocument {
        ImportedDocument(
            name: "Photo Library Image",
            typeLabel: "JPG",
            sizeLabel: ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file),
            pagesLabel: "1",
            sourceLabel: "Photos",
            importedAtLabel: Date().formatted(date: .omitted, time: .shortened),
            systemIcon: "photo",
            previewImage: image,
            previewURL: nil,
            previewKey: UUID().uuidString,
            kind: .image
        )
    }

    static func fromPhotoLibraryImages(_ image: UIImage, totalCount: Int, totalByteCount: Int) -> ImportedDocument {
        ImportedDocument(
            name: totalCount > 1 ? "Photo Library Selection" : "Photo Library Image",
            typeLabel: "JPG",
            sizeLabel: ByteCountFormatter.string(fromByteCount: Int64(totalByteCount), countStyle: .file),
            pagesLabel: "\(max(totalCount, 1))",
            sourceLabel: "Photos",
            importedAtLabel: Date().formatted(date: .omitted, time: .shortened),
            systemIcon: "photo",
            previewImage: image,
            previewURL: nil,
            previewKey: UUID().uuidString,
            kind: .image
        )
    }

    static func fromCapturedImage(_ image: UIImage) -> ImportedDocument {
        ImportedDocument(
            name: "Captured Image",
            typeLabel: "JPG",
            sizeLabel: "-",
            pagesLabel: "1",
            sourceLabel: "Camera",
            importedAtLabel: Date().formatted(date: .omitted, time: .shortened),
            systemIcon: "camera",
            previewImage: image,
            previewURL: nil,
            previewKey: UUID().uuidString,
            kind: .image
        )
    }

    static func fromSelections(_ selections: [ImportSelectionItem]) -> ImportedDocument? {
        guard let first = selections.first else { return nil }

        if selections.count == 1, let fileURL = first.fileURL {
            return fromImportedFile(url: fileURL)
        }

        let sourceLabel: String = {
            let sources = Set(selections.map(\.source))
            if sources.count > 1 { return "Mixed" }
            switch sources.first {
            case .photos: return "Photos"
            case .camera: return "Camera"
            case .files: return "Files"
            case nil: return "Unknown"
            }
        }()

        let totalByteCount = selections.compactMap(\.byteCount).reduce(0, +)
        let sizeLabel = totalByteCount > 0
            ? ByteCountFormatter.string(fromByteCount: Int64(totalByteCount), countStyle: .file)
            : "-"

        let hasOnlyImages = selections.allSatisfy { item in
            if item.previewImage != nil { return true }
            if let url = item.fileURL {
                let type = UTType(filenameExtension: url.pathExtension)
                return type?.conforms(to: .image) == true
            }
            return false
        }

        return ImportedDocument(
            name: selections.count == 1 ? first.name : "\(selections.count) selected items",
            typeLabel: selections.count == 1 ? first.typeLabel : (hasOnlyImages ? "IMG" : "MIXED"),
            sizeLabel: sizeLabel,
            pagesLabel: "\(max(selections.count, 1))",
            sourceLabel: sourceLabel,
            importedAtLabel: Date().formatted(date: .omitted, time: .shortened),
            systemIcon: selections.count == 1 ? first.systemIcon : "doc.on.doc",
            previewImage: first.previewImage,
            previewURL: first.fileURL,
            previewKey: first.fileURL?.absoluteString ?? first.id.uuidString,
            kind: hasOnlyImages ? .image : .other
        )
    }
}

struct ToolCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
    let subtitle: String
    let tools: [OperationItem]

    init(id: String = UUID().uuidString, title: String, icon: String, subtitle: String, tools: [OperationItem]) {
        self.id = id
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.tools = tools
    }
}

let toolCategories: [ToolCategory] = [
    ToolCategory(
        title: "Image Tools",
        icon: "photo",
        subtitle: "Resize, convert, OCR, and optimize images",
        tools: [
            .init(icon: "arrow.left.arrow.right", title: "Resize", subtitle: "Change dimensions and dpi"),
            .init(icon: "rectangle.compress.vertical", title: "Compress", subtitle: "Reduce image file size"),
            .init(icon: "doc.richtext", title: "Image to PDF", subtitle: "Convert images into PDF"),
            .init(icon: "wand.and.stars", title: "Enhance", subtitle: "Auto improve clarity and lighting"),
            .init(icon: "text.viewfinder", title: "OCR", subtitle: "Extract text from images"),
            .init(icon: "paintbrush.pointed", title: "Background Remove", subtitle: "Isolate the subject")
        ]
    ),
    ToolCategory(
        title: "PDF Tools",
        icon: "doc.text",
        subtitle: "Everything for PDF workflows",
        tools: [
            .init(icon: "doc.richtext", title: "Image to PDF", subtitle: "Convert images into PDF"),
            .init(icon: "arrow.down.doc", title: "Compress PDF", subtitle: "Reduce PDF size quickly"),
            .init(icon: "doc.on.doc", title: "Merge PDF", subtitle: "Combine multiple PDFs"),
            .init(icon: "square.split.2x1", title: "Split PDF", subtitle: "Extract selected pages"),
            .init(icon: "signature", title: "Sign PDF", subtitle: "Add signatures and initials"),
            .init(icon: "lock.doc", title: "Protect PDF", subtitle: "Set password and permissions"),
            .init(icon: "text.viewfinder", title: "PDF OCR", subtitle: "Make scanned PDFs searchable")
        ]
    ),
    ToolCategory(
        title: "Document Tools",
        icon: "doc",
        subtitle: "Convert and manage office documents",
        tools: [
            .init(icon: "doc.badge.gearshape", title: "Convert Format", subtitle: "DOCX, TXT, RTF, and more"),
            .init(icon: "arrow.triangle.2.circlepath", title: "Batch Rename", subtitle: "Rename multiple files"),
            .init(icon: "text.justify", title: "Text Extract", subtitle: "Pull text content into plain text"),
            .init(icon: "archivebox", title: "Archive", subtitle: "Zip documents together"),
            .init(icon: "square.and.arrow.up", title: "Share Package", subtitle: "Share selected outputs"),
            .init(icon: "clock.arrow.circlepath", title: "Version Compare", subtitle: "Compare revisions")
        ]
    )
]
