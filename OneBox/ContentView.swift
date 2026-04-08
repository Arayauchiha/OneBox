//
//  ContentView.swift
//  OneBox
//
//  Created by Aryan singh on 26/03/26.
//

import SwiftUI

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

struct ContentView: View {
    @State private var activeTab: AppTab = .home
    @State private var isExpanded: Bool = false
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    Text(activeTab.rawValue)
                }

            HStack(alignment: .bottom, spacing: 12) {
                MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {
                    DummyExpandedContent()
                }

                Button {
                    withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) {
                        isExpanded.toggle()
                    }

                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .medium))
                        .rotationEffect(.init(degrees: isExpanded ? 45 : 0))
                        .frame(width: 52, height: 52)
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(PlainGlassButtonEffect(shape: .circle))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 25)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    func DummyExpandedContent() -> some View {
        GlassEffectContainer(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 4), spacing: 10) {
                ForEach(actions) { action in
                    VStack(spacing: 6) {
                        Button {} label: {
                            Image(systemName: action.icon)
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundStyle(Color.primary)
                                // A little gray tint!
                                .background(.gray.opacity(0.09), in: .rect(cornerRadius: 16))
                        }

                        .buttonStyle(PlainGlassButtonEffect(shape: .rect(cornerRadius: 16)))

                        Text(action.title)
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .padding(10)
    }
}

struct PlainGlassButtonEffect<S: Shape>: ButtonStyle {
    var shape: S
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glassEffect(.regular.interactive(), in: shape)
    }
}

/// Dummy Action Model
struct Action: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}

let actions: [Action] = [
    Action(icon: "scissors", title: "Trim"),
    Action(icon: "crop", title: "Crop"),
    Action(icon: "wand.and.stars", title: "Enhance"),
    Action(icon: "textformat", title: "Text"),
    Action(icon: "music.note", title: "Audio"),
    Action(icon: "hare", title: "Speed"),
    Action(icon: "square.on.square", title: "Duplicate"),
    Action(icon: "arrow.uturn.backward", title: "Undo"),
    Action(icon: "square.and.arrow.up", title: "Share"),
    Action(icon: "bookmark", title: "Save"),
    Action(icon: "trash", title: "Delete"),
]

#Preview {
    ContentView()
}
