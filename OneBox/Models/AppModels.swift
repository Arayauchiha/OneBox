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
    let kind: ImportedDocumentKind

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
            kind: .image
        )
    }
}

struct ToolCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let subtitle: String
    let tools: [OperationItem]
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
