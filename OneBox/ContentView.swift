//
//  ContentView.swift
//  OneBox
//

import SwiftUI

struct ContentView: View {
    @State private var activeTab: AppTab = .home
    @State private var isExpanded: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Home Dashboard
            TabView(selection: $activeTab) {
                HomeView().tag(AppTab.home)
                PlaceholderView(title: "Insights Explorer", icon: "chart.bar.xaxis").tag(AppTab.search)
                PlaceholderView(title: "The Vault", icon: "lock.shield.fill").tag(AppTab.notifications)
                PlaceholderView(title: "Your Account", icon: "person.crop.circle.fill").tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 2. The Golden Dock Layout
            HStack(alignment: .bottom, spacing: 12) {
                // Adaptive Restored Tab Bar
                MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {
                    DummyExpandedContent()
                }
                .zIndex(1000)
                
                // Original Bouncy Master Button
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
                        .background(.ultraThinMaterial, in: .circle)
                }
                .buttonStyle(PlainGlassButtonEffect(shape: .circle))
                .zIndex(1001)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 25)
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    func DummyExpandedContent() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("STUDIO TOOLS")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)) {
                let tools = Array(allTools.prefix(3))
                ForEach(tools) { tool in
                    VStack(spacing: 8) {
                        Image(systemName: tool.icon).font(.title3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 16))
                        Text(tool.name).font(.system(size: 9, weight: .bold))
                    }
                    .contentShape(.rect)
                }
            }
        }
        .padding(15)
    }
}

// HELPERS
struct PlainGlassButtonEffect<S: Shape>: ButtonStyle {
    var shape: S
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glassEffect(.regular.interactive(), in: shape)
    }
}

struct PlaceholderView: View {
    let title: String; let icon: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 45)).foregroundStyle(.gray.opacity(0.3))
            Text(title).font(.system(size: 20, weight: .bold)).foregroundStyle(.gray).opacity(0.5)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemGroupedBackground))
    }
}

#Preview { ContentView() }
