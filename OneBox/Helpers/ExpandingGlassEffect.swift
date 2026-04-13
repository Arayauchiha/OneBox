//
//  ExpandingGlassEffect.swift
//  OneBox
//

import SwiftUI

struct ExpandableGlassEffect<Content: View, Label: View>: View, Animatable {
    var alignment: Alignment
    var progress: CGFloat
    var labelSize: CGSize = .init(width: 55, height: 55)
    var cornerRadius: CGFloat = 30
    @ViewBuilder var content: Content
    @ViewBuilder var label: Label
    
    @State private var contentSize: CGSize = .zero

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let heightDiff = max(contentSize.height - labelSize.height, 0)
        let rHeight = heightDiff * contentOpacity
        
        GlassEffectContainer {
            let widthDiff = max(contentSize.width - labelSize.width, 0)
            let rWidth = widthDiff * contentOpacity

            ZStack(alignment: .bottom) {
                // THE STUDIO DRAWER
                content
                    .compositingGroup()
                    .scaleEffect(contentScale, anchor: .bottom)
                    .blur(radius: 12 * blurProgress)
                    .opacity(contentOpacity)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { newValue in
                        contentSize = newValue
                    }
                    .fixedSize(horizontal: false, vertical: true)

                // THE TAB DOCK (Pinned to bottom)
                label
                    .compositingGroup()
                    .blur(radius: 8 * blurProgress)
                    .opacity(1 - (progress * 1.5))
                    .frame(width: labelSize.width, height: labelSize.height)
            }
            // FIXED: Locked to bottom with no manual offsets. This ensures
            // growth starts exactly from the dock's current position.
            .frame(width: labelSize.width + rWidth, height: labelSize.height + rHeight, alignment: .bottom)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.12), lineWidth: 0.5)
            }
        }
        .scaleEffect(
            x: 1 - (blurProgress * 0.3),
            y: 1 + (blurProgress * 0.15),
            anchor: .bottom
        )
        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 15)
    }

    var contentOpacity: CGFloat { max(progress - 0.3, 0) / 0.7 }
    var blurProgress: CGFloat { progress > 0.5 ? (1 - progress) / 0.5 : progress / 0.5 }

    var contentScale: CGFloat {
        let minAspectScale = min(labelSize.width / (contentSize.width > 0 ? contentSize.width : 1), 
                                 labelSize.height / (contentSize.height > 0 ? contentSize.height : 1))
        return minAspectScale + (1 - minAspectScale) * progress
    }
}
