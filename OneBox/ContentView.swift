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
            // 1. Studio Dashboard
            TabView(selection: $activeTab) {
                HomeView().tag(AppTab.home)
                PlaceholderView(title: "Insights", icon: "chart.bar.fill").tag(AppTab.search)
                PlaceholderView(title: "Vault", icon: "lock.shield.fill").tag(AppTab.notifications)
                PlaceholderView(title: "Settings", icon: "gearshape.fill").tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 2. The Original Floating Pro Dock (Adaptive)
            HStack(alignment: .bottom, spacing: 14) {
                // Adaptive Restored Tab Bar
                MorphingTabBar(activeTab: $activeTab, isExpanded: $isExpanded) {
                    DummyExpandedContent()
                }
                
                // Master Action Button (Fixed 62pt Pro Size)
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 62, height: 62)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(.systemBackground))
                            .rotationEffect(.init(degrees: isExpanded ? 45 : 0))
                    }
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
                .zIndex(1001)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 25) // Standard Pro Clearance
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(.all, edges: .bottom)
    }

    func DummyExpandedContent() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("ONEBOX STUDIO")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)) {
                let items = [
                    (icon: "doc.viewfinder.fill", title: "Scan"),
                    (icon: "photo.stack", title: "Batch"),
                    (icon: "sparkles", title: "Optimize")
                ]
                ForEach(items, id: \.title) { item in
                    VStack(spacing: 8) {
                        Image(systemName: item.icon).font(.title2)
                            .frame(width: 62, height: 62)
                            .background(Color.primary.opacity(0.05), in: .rect(cornerRadius: 18))
                        Text(item.title).font(.system(size: 10, weight: .bold))
                    }
                }
            }
        }
        .padding(25)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

struct PlaceholderView: View {
    let title: String; let icon: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40)).foregroundStyle(.gray.opacity(0.3))
            Text(title).font(.system(size: 20, weight: .bold)).foregroundStyle(.gray).opacity(0.5)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(.systemGroupedBackground))
    }
}

#Preview { ContentView() }
