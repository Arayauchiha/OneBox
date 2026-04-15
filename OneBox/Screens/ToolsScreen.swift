import SwiftUI

struct ToolsScreen: View {
    @State private var searchText = ""
    @AppStorage("favorite_tool_titles") private var favoriteToolTitlesStorage = ""
    @State private var favoriteToolTitles: Set<String> = []
    @State private var selectedCategory: ToolCategory?
    @State private var showCategoryDetail = false
    @State private var selectedTool: OperationItem?
    @State private var showToolDestination = false
    @State private var showAllMostCommon = false

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    private let pageHorizontalPadding: CGFloat = 16
    private let cardCornerRadius: CGFloat = 24

    private var allTools: [OperationItem] {
        toolCategories.flatMap(\.tools)
    }

    private var favoriteTools: [OperationItem] {
        allTools.filter { favoriteToolTitles.contains($0.title) }
    }

    private var mostCommonTools: [OperationItem] {
        [
            "Compress PDF",
            "Merge PDF",
            "Image to PDF",
            "Resize",
            "OCR",
            "Sign PDF"
        ].compactMap { title in
            allTools.first(where: { $0.title == title })
        }
    }

    private var visibleMostCommonTools: [OperationItem] {
        showAllMostCommon ? mostCommonTools : Array(mostCommonTools.prefix(4))
    }

    private var favoriteCategory: ToolCategory {
        ToolCategory(
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
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Categories")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: categoryColumns, spacing: 8) {
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

                        Text("Most Common")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)

                        mostCommonCard
                    } else {
                        Text("Results")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)

                        if filteredTools.isEmpty {
                            Text("No tools found")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        } else {
                            toolListCard(filteredTools)
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
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
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }

    private var mostCommonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            toolListCard(visibleMostCommonTools)

            if mostCommonTools.count > 4 {
                Button(showAllMostCommon ? "Show less" : "Show all") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showAllMostCommon.toggle()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            }
        }
    }

    private func toolRow(_ tool: OperationItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tool.icon)
                .font(.body)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text(tool.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                toggleFavorite(tool)
            } label: {
                Image(systemName: favoriteToolTitles.contains(tool.title) ? "star.fill" : "star")
                    .foregroundStyle(favoriteToolTitles.contains(tool.title) ? Color.white : Color(UIColor.tertiaryLabel))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
    }

    private func categoryCard(_ category: ToolCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(12)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
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
    @State private var layoutMode: ToolLayoutMode = .list
    @State private var selectedTool: OperationItem?
    @State private var showToolDestination = false

    private let toolGridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
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
            VStack(alignment: .leading, spacing: 16) {
                if visibleTools.isEmpty {
                    Text("No tools found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if layoutMode == .list {
                    toolListCard(visibleTools)
                } else {
                    LazyVGrid(columns: toolGridColumns, spacing: 12) {
                        ForEach(visibleTools) { tool in
                            toolGridCard(tool)
                        }
                    }
                }
            }
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

    private func toolListCard(_ tools: [OperationItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(tools.enumerated()), id: \.element.id) { index, tool in
                toolListRow(tool)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
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
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
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
                .font(.body)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text(tool.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                toggleFavorite(tool)
            } label: {
                Image(systemName: favoriteToolTitles.contains(tool.title) ? "star.fill" : "star")
                    .foregroundStyle(favoriteToolTitles.contains(tool.title) ? Color.white : Color(UIColor.tertiaryLabel))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    private func toolGridCard(_ tool: OperationItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tool.icon)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(width: 24, height: 24)

                Spacer()

                Button {
                    toggleFavorite(tool)
                } label: {
                    Image(systemName: favoriteToolTitles.contains(tool.title) ? "star.fill" : "star")
                        .foregroundStyle(favoriteToolTitles.contains(tool.title) ? Color.white : Color(UIColor.tertiaryLabel))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }

            Text(tool.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(tool.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTool = tool
            showToolDestination = true
        }
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
