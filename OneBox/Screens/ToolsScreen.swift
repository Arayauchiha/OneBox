import SwiftUI

struct ToolsScreen: View {
    @State private var searchText = ""
    @AppStorage("favorite_tool_titles") private var favoriteToolTitlesStorage = ""
    @State private var favoriteToolTitles: Set<String> = []
    @State private var selectedCategory: ToolCategory?
    @State private var showCategoryDetail = false
    @State private var selectedTool: OperationItem?
    @State private var showToolDestination = false

    private var categoryColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160), spacing: 14)]
    }
    private let pageHorizontalPadding: CGFloat = 16
    private let cardCornerRadius: CGFloat = 24
    private let categoryCardCornerRadius: CGFloat = 20

    private var allTools: [OperationItem] {
        toolCategories.flatMap(\.tools)
    }

    private var favoriteTools: [OperationItem] {
        allTools.filter { favoriteToolTitles.contains($0.title) }
    }

    private var generalTools: [OperationItem] {
        [
            "Image to PDF",
            "Compress PDF",
            "Merge PDF",
            "Resize",
            "OCR",
            "Sign PDF",
            "Background Remove",
            "Convert Format"
        ].compactMap { title in
            allTools.first(where: { $0.title == title })
        }
    }

    private var favoriteCategory: ToolCategory {
        ToolCategory(
            id: "favorites",
            title: "Favorites",
            icon: "star.fill",
            subtitle: favoriteTools.isEmpty ? "Pin tools to see them here" : "Your pinned tools",
            tools: favoriteTools
        )
    }

    private var categoriesForList: [ToolCategory] {
        toolCategories + [favoriteCategory]
    }

    private var filteredTools: [OperationItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        return allTools.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    if !searchText.isEmpty {
                        Text("Results")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if filteredTools.isEmpty {
                            Text("No tools found")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                                .oneBoxGlassCard()
                        } else {
                            ForEach(filteredTools) { tool in
                                Button {
                                    selectedTool = tool
                                    showToolDestination = true
                                } label: {
                                    toolListCard([tool])
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Text("Categories")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)

                        LazyVGrid(columns: categoryColumns, spacing: 14) {
                            ForEach(categoriesForList) { category in
                                Button {
                                    selectedCategory = category
                                    showCategoryDetail = true
                                } label: {
                                    categoryCard(category)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("General Tools")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)

                        ForEach(generalTools) { tool in
                            Button {
                                selectedTool = tool
                                showToolDestination = true
                            } label: {
                                toolListCard([tool])
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, pageHorizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tools")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search for a tool"
            )
            .navigationDestination(isPresented: $showCategoryDetail) {
                if let category = selectedCategory {
                    ToolCategoryDetailScreen(category: category, favoriteToolTitles: $favoriteToolTitles)
                } else {
                    EmptyView()
                }
            }
            .navigationDestination(isPresented: $showToolDestination) {
                if let tool = selectedTool {
                    ToolDestinationScreen(tool: tool)
                } else {
                    EmptyView()
                }
            }
            .onAppear {
                favoriteToolTitles = decodeFavorites(favoriteToolTitlesStorage)
            }
            .onChange(of: favoriteToolTitlesStorage) { _, newValue in
                favoriteToolTitles = decodeFavorites(newValue)
            }
            .onChange(of: favoriteToolTitles) { _, newValue in
                favoriteToolTitlesStorage = encodeFavorites(newValue)
            }
        }
    }
    

    private func toolListCard(_ tools: [OperationItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(tools.enumerated()), id: \.element.id) { index, tool in
                toolRow(tool)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTool = tool
                        showToolDestination = true
                    }

                if index < tools.count - 1 {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .oneBoxGlassCard(cornerRadius: cardCornerRadius)
    }

    private func toolRow(_ tool: OperationItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tool.icon)
                .font(.body.weight(.medium))
                .frame(width: 34, height: 34)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 5) {
                Text(tool.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(tool.subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
    }

    private func categoryCard(_ category: ToolCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(width: 24, height: 24)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            Text(category.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(category.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(14)
        .oneBoxGlassCard(cornerRadius: categoryCardCornerRadius)
    }

    private func toggleFavorite(_ tool: OperationItem) {
        if favoriteToolTitles.contains(tool.title) {
            favoriteToolTitles.remove(tool.title)
        } else {
            favoriteToolTitles.insert(tool.title)
        }
    }

    private func decodeFavorites(_ value: String) -> Set<String> {
        let items = value.split(separator: "|").map(String.init)
        return Set(items)
    }

    private func encodeFavorites(_ favorites: Set<String>) -> String {
        favorites.sorted().joined(separator: "|")
    }
}

struct ToolCategoryDetailScreen: View {
    private enum ToolLayoutMode {
        case list
        case grid
    }

    let category: ToolCategory
    @Binding var favoriteToolTitles: Set<String>
    @State private var searchText = ""
    @State private var layoutMode: ToolLayoutMode = .grid
    @State private var selectedTool: OperationItem?
    @State private var showToolDestination = false

    private var toolGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: 12)]
    }
    private let cardCornerRadius: CGFloat = 24
    private let pageHorizontalPadding: CGFloat = 16

    private var visibleTools: [OperationItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return category.tools }

        return category.tools.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            detailContent
            .padding(.horizontal, pageHorizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    layoutMode = layoutMode == .list ? .grid : .list
                } label: {
                    Image(systemName: layoutMode == .list ? "square.grid.2x2" : "list.bullet")
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search in \(category.title)"
        )
        .navigationDestination(isPresented: $showToolDestination) {
            if let tool = selectedTool {
                ToolDestinationScreen(tool: tool)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 16) {
                detailSections
            }
        } else {
            detailSections
        }
    }

    private var detailSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            if visibleTools.isEmpty {
                Text("No tools found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                    .oneBoxGlassCard()
            } else if layoutMode == .list {
                ForEach(visibleTools) { tool in
                    toolListCard([tool])
                }
            } else {
                LazyVGrid(columns: toolGridColumns, spacing: 14) {
                    ForEach(visibleTools) { tool in
                        toolGridCard(tool)
                    }
                }
            }
        }
    }

    private func toolListCard(_ tools: [OperationItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(tools.enumerated()), id: \.element.id) { index, tool in
                toolListRow(tool)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTool = tool
                        showToolDestination = true
                    }

                if index < tools.count - 1 {
                    Divider()
                        .padding(.leading, 66)
                }
            }
        }
        .oneBoxGlassCard(cornerRadius: cardCornerRadius)
    }

    private func toggleFavorite(_ tool: OperationItem) {
        if favoriteToolTitles.contains(tool.title) {
            favoriteToolTitles.remove(tool.title)
        } else {
            favoriteToolTitles.insert(tool.title)
        }
    }

    private func toolListRow(_ tool: OperationItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tool.icon)
                .font(.body.weight(.medium))
                .frame(width: 34, height: 34)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 5) {
                Text(tool.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(tool.subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private func toolGridCard(_ tool: OperationItem) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.tertiarySystemGroupedBackground).opacity(0.4))
                    .frame(width: 72, height: 72)
                
                Image(systemName: tool.icon)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(.white)
            }
            
            Text(tool.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 124)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTool = tool
            showToolDestination = true
        }
        .oneBoxGlassCard(cornerRadius: 24, interactive: true)
    }
}
