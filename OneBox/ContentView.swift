//
//  ContentView.swift
//  OneBox
//

import SwiftUI

struct ContentView: View {
    @State private var activeTab: AppTab = .home
    @State private var isExpanded: Bool = false
    
    // CUSTOM STUDIO ACCENT: Vibrant Ocean Blue
    let studioAccent = Color(red: 0.0, green: 0.45, blue: 0.95)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. HOME DASHBOARD
            TabView(selection: $activeTab) {
                HomeView().tag(AppTab.home)
                PlaceholderView(title: "Insights Explorer", icon: "chart.bar.xaxis").tag(AppTab.search)
                PlaceholderView(title: "The Vault", icon: "lock.shield.fill").tag(AppTab.notifications)
                PlaceholderView(title: "Your Account", icon: "person.crop.circle.fill").tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .blur(radius: isExpanded ? 5 : 0)
            
            // 2. DISMISSAL SHIELD
            if isExpanded {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.1)) {
                            isExpanded = false
                        }
                    }
                    .zIndex(500)
            }
            
            // 3. THE ULTIMATE STUDIO DOCK
            HStack(alignment: .bottom, spacing: 14) {
                MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {
                    DummyExpandedContent()
                }
                .zIndex(1000)
                
                // THE MASTER ACCENT BUTTON
                Button {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    
                    withAnimation(.bouncy(duration: 0.5, extraBounce: 0.1)) {
                        isExpanded.toggle()
                    }
                } label: {
                    ZStack {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .rotationEffect(.init(degrees: isExpanded ? 45 : 0))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(studioAccent)) // NEW MATTE ACCENT
                    // GLOW REMOVED
                }
                .zIndex(1001)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 25)
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    func DummyExpandedContent() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("STUDIO TOOLKIT")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.secondary)
                    .kerning(1.2)
                Spacer()
                Image(systemName: "sparkles").foregroundStyle(studioAccent).font(.system(size: 10))
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 15) {
                let tools = Array(allTools.prefix(3))
                ForEach(tools) { tool in
                    VStack(spacing: 8) {
                        Image(systemName: tool.icon).font(.title3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.primary.opacity(0.04), in: .rect(cornerRadius: 18))
                        
                        Text(tool.name).font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(25)
    }
}

// ... rest of the code is same
struct PlaceholderView: View {
    let title: String; let icon: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 45)).foregroundStyle(.gray.opacity(0.3))
            Text(title).font(.system(size: 20, weight: .bold)).foregroundStyle(.gray).opacity(0.5)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemGroupedBackground))
    }
}
