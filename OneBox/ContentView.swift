import SwiftUI

enum MainTab: Hashable {
    case home
    case tools
    case files
    case create
}

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var previousTab: MainTab = .home
    @State private var menuProgress: CGFloat = 0
    @State private var quickActionTool: OperationItem?

    private let menuAnimation = Animation.bouncy(duration: 0.42, extraBounce: 0.08)
    private let operations: [QuickOperation] = [
        .init(icon: "doc.richtext", title: "Image to PDF", subtitle: "Convert photos to PDF"),
        .init(icon: "arrow.down.doc", title: "Compress PDF", subtitle: "Reduce file size"),
        .init(icon: "doc.on.doc", title: "Merge PDF", subtitle: "Combine multiple PDFs"),
        .init(icon: "text.viewfinder", title: "OCR", subtitle: "Extract text quickly"),
        .init(icon: "folder", title: "Open Files", subtitle: "View saved outputs"),
        .init(icon: "wrench.and.screwdriver", title: "Open Tools", subtitle: "Browse all utilities")
    ]

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house", value: .home) {
                    HomeScreen()
                }

                Tab("Tools", systemImage: "wrench.and.screwdriver", value: .tools) {
                    ToolsScreen()
                }

                Tab("Files", systemImage: "folder", value: .files) {
                    FilesScreen()
                }

                Tab("Add", systemImage: "plus", value: .create, role: .search) {
                    Color.clear
                        .accessibilityHidden(true)
                }
            }

            Color.black
                .opacity(0.16 * menuProgress)
                .ignoresSafeArea()
                .allowsHitTesting(menuProgress > 0.01)
                .onTapGesture {
                    closeMenu()
                }

            FloatingActionCluster(operations: operations, progress: menuProgress) { operation in
                handleQuickOperation(operation)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, verticalSizeClass == .compact ? 16 : 92)
            .allowsHitTesting(menuProgress > 0.01)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .create {
                selectedTab = previousTab
                withAnimation(menuAnimation) {
                    menuProgress = menuProgress > 0.5 ? 0 : 1
                }
                return
            }
            previousTab = newValue
        }
        .onDisappear {
            menuProgress = 0
        }
        .sheet(item: $quickActionTool) { tool in
            NavigationStack {
                ToolDestinationScreen(tool: tool)
            }
        }
    }

    private func closeMenu() {
        withAnimation(menuAnimation) {
            menuProgress = 0
        }
    }

    private func handleQuickOperation(_ operation: QuickOperation) {
        closeMenu()

        switch operation.title {
        case "Open Files":
            selectedTab = .files
        case "Open Tools":
            selectedTab = .tools
        default:
            if let tool = toolCategories
                .flatMap(\.tools)
                .first(where: { $0.title == operation.title }) {
                quickActionTool = tool
                selectedTab = .tools
            }
        }
    }
}

#Preview {
    ContentView()
}
