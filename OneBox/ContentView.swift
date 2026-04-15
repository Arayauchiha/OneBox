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

    private let menuAnimation = Animation.bouncy(duration: 0.42, extraBounce: 0.08)
    private let operations: [QuickOperation] = [
        .init(icon: "plus.square.on.square", title: "New Project", subtitle: "Start from template"),
        .init(icon: "camera", title: "Scan", subtitle: "Capture and import"),
        .init(icon: "wand.and.stars", title: "Enhance", subtitle: "Auto optimize content"),
        .init(icon: "paperplane", title: "Send", subtitle: "Share to your team"),
        .init(icon: "slider.horizontal.3", title: "Tune", subtitle: "Adjust settings quickly"),
        .init(icon: "bookmark", title: "Save", subtitle: "Store for later")
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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

            FloatingActionCluster(operations: operations, progress: menuProgress) { _ in
                closeMenu()
            }
            .padding(.trailing, 20)
            .padding(.bottom, 92)
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
    }

    private func closeMenu() {
        withAnimation(menuAnimation) {
            menuProgress = 0
        }
    }
}

#Preview {
    ContentView()
}
