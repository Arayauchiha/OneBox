//
//  Models.swift
//  OneBox
//

import SwiftUI

protocol MorphingTabProtocol: CaseIterable, Hashable, RawRepresentable where RawValue == String {
    var symbolImage: String { get }
}

enum AppTab: String, MorphingTabProtocol {
    case home = "Home"
    case search = "Search"
    case notifications = "Notification"
    case settings = "Settings"

    var symbolImage: String {
        return switch self {
        case .home: "house.fill"
        case .search: "magnifyingglass"
        case .notifications: "bell.fill"
        case .settings: "gearshape.fill"
        }
    }
}

enum OperationType {
    case image, pdf, document, text
}

struct DocumentTool: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let type: OperationType
}

let allTools: [DocumentTool] = [
    DocumentTool(name: "Remove BG", icon: "person.fill.viewfinder", color: .blue, type: .image),
    DocumentTool(name: "Compress", icon: "arrow.down.right.and.arrow.up.left", color: .blue, type: .image),
    DocumentTool(name: "Resize", icon: "aspectratio.fill", color: .blue, type: .image),
    DocumentTool(name: "Merge PDF", icon: "plus.rectangle.fill.on.rectangle.fill", color: .red, type: .pdf),
    DocumentTool(name: "Split PDF", icon: "scissors", color: .red, type: .pdf),
    DocumentTool(name: "Protect", icon: "lock.fill", color: .red, type: .pdf),
    DocumentTool(name: "OCR Scan", icon: "text.viewfinder", color: .orange, type: .text),
    DocumentTool(name: "Zip Archive", icon: "archivebox.fill", color: .gray, type: .document),
    DocumentTool(name: "Convert", icon: "arrow.triangle.2.circlepath.doc.fill", color: .gray, type: .document)
]
