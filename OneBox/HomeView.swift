//
//  HomeView.swift
//  OneBox
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct HomeView: View {
    @State private var searchText = ""
    @State private var isImporting = false
    @State private var selectedFile: URL? = nil
    @State private var selectedType: OperationType? = nil
    
    let tools: [DocumentTool] = allTools
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // 1. Magic Drop Zone
                    if let file = selectedFile {
                        ActiveFileZone(file: file, type: selectedType ?? .document) {
                            withAnimation { selectedFile = nil }
                        }
                    } else {
                        DropZone(isImporting: $isImporting)
                    }
                    
                    // 2. Intelligent Layer
                    if let type = selectedType {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("COMMONLY USED")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(tools.filter { $0.type == type }) { tool in
                                        OperationPill(tool: tool)
                                    }
                                }
                            }
                        }
                    }
                    
                    // 3. Studio Toolkit (Tile List)
                    VStack(alignment: .leading, spacing: 18) {
                        Text("STUDIO TOOLSET")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 12) {
                            ForEach(tools.prefix(5)) { tool in
                                ToolTile(tool: tool)
                            }
                        }
                    }
                    
                    // 4. Activity
                    VStack(alignment: .leading, spacing: 18) {
                        Text("RECENT ACTIVITY")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 1) {
                            ActivityRow(name: "design_file.pdf", date: "1h ago", icon: "doc.fill", color: .red)
                            ActivityRow(name: "photo_edit.png", date: "4h ago", icon: "photo.fill", color: .blue)
                        }
                        .background(.white, in: .rect(cornerRadius: 22))
                    }
                    
                    // Clear space for the bottom dock
                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 22) // Standard Native Margin
                .padding(.top, 16)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search tools...")
            .background(Color(.systemGroupedBackground))
            .navigationTitle("OneBox")
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.item]) { result in
                if case .success(let url) = result {
                    withAnimation {
                        selectedFile = url
                        selectedType = url.pathExtension.lowercased() == "pdf" ? .pdf : (["png", "jpg"].contains(url.pathExtension.lowercased()) ? .image : .document)
                    }
                }
            }
        }
    }
}

struct ToolTile: View {
    let tool: DocumentTool
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: tool.icon).font(.title3).foregroundStyle(.white)
                .frame(width: 46, height: 46).background(tool.color.gradient, in: .rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 1) {
                Text(tool.name).font(.system(size: 15, weight: .bold))
                Text("Tap to open tool").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.gray.opacity(0.3))
        }
        .padding(14).background(.white, in: .rect(cornerRadius: 20)).shadow(color: .black.opacity(0.02), radius: 5)
    }
}

struct DropZone: View {
    @Binding var isImporting: Bool
    var body: some View {
        Button { isImporting = true } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill").font(.system(size: 32)).foregroundStyle(.blue)
                VStack(spacing: 2) {
                    Text("Magic Drop Zone").font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Import any file to start").font(.system(size: 13)).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 40).frame(maxWidth: .infinity).background(.white, in: .rect(cornerRadius: 30)).shadow(color: .black.opacity(0.03), radius: 8)
        }.buttonStyle(.plain)
    }
}

struct ActiveFileZone: View {
    let file: URL; let type: OperationType; let onClear: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                HStack(spacing: 10) { Image(systemName: type == .image ? "photo.fill" : "doc.fill").foregroundStyle(.blue); Text(file.lastPathComponent).font(.system(size: 14, weight: .bold)).lineLimit(1) }
                Spacer(); Button(action: onClear) { Image(systemName: "xmark.circle.fill").foregroundStyle(.gray.opacity(0.3)) }
            }
            Divider()
            Text("Ready to process").font(.system(size: 12, weight: .bold)).foregroundStyle(.blue)
        }.padding(18).background(.white, in: .rect(cornerRadius: 28)).shadow(color: Color.black.opacity(0.03), radius: 10)
    }
}

struct ActivityRow: View {
    let name: String; let date: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 34, height: 34).background(color.opacity(0.05), in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 1) { Text(name).font(.system(size: 14, weight: .bold)); Text(date).font(.system(size: 12)).foregroundStyle(.secondary) }
            Spacer()
        }.padding(14).overlay(Divider().padding(.leading, 64), alignment: .bottom)
    }
}

struct OperationPill: View {
    let tool: DocumentTool
    var body: some View {
        HStack(spacing: 6) { Image(systemName: tool.icon); Text(tool.name) }.font(.system(size: 13, weight: .bold)).padding(.horizontal, 14).padding(.vertical, 8).background(tool.color.opacity(0.1), in: .capsule).foregroundStyle(tool.color)
    }
}
