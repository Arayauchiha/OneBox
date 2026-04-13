//
//  HomeView.swift
//  OneBox
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // 1. Native-Aligned Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("OneBox")
                        .font(.system(size: 34, weight: .black))
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search tools...", text: .constant(""))
                    }
                    .padding(12)
                    .background(Color(.systemFill), in: .rect(cornerRadius: 12))
                }
                .padding(.horizontal, 20) // NATIVE PADDING
                
                // 2. Magic Drop Zone
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                    
                    Text("Magic Drop Zone")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("Import any file to start")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 30))
                .padding(.horizontal, 20) // MATCHED PADDING
                
                // 3. Studio Toolkit
                VStack(alignment: .leading, spacing: 16) {
                    Text("STUDIO TOOLSET")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(allTools) { tool in
                            HStack(spacing: 16) {
                                Image(systemName: tool.icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(tool.color.opacity(0.1), in: .rect(cornerRadius: 12))
                                    .foregroundStyle(tool.color)
                                
                                VStack(alignment: .leading) {
                                    Text(tool.name).font(.system(size: 16, weight: .bold))
                                    Text("Tap to open tool").font(.system(size: 12)).foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 120) // Space for the floating dock
        }
        .background(Color(.systemGroupedBackground))
    }
}
