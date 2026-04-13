//
//  ExpandingGlassEffect.swift
//  OneBox
//
//  Created by Aryan singh on 26/03/26.
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
        GlassEffectContainer {
            let widthDiff = max(contentSize.width - labelSize.width, 0)
            let heightDiff = max(contentSize.height - labelSize.height, 0)

            let rWidth = widthDiff * contentOpacity
            let rHeight = heightDiff * contentOpacity

            // FIXED: Alignment is now .bottom to ensure the base stays 
            // pinned to the dock while the rest stretches UP.
            ZStack(alignment: .bottom) {
                content
                    .compositingGroup()
                    .scaleEffect(contentScale, anchor: .bottom) // Anchor at bottom
                    .blur(radius: 14 * blurProgress)
                    .opacity(contentOpacity)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { newValue in
                        contentSize = newValue
                    }
                    .fixedSize(horizontal: false, vertical: true)

                label
                    .compositingGroup()
                    .blur(radius: 14 * blurProgress)
                    .opacity(1 - labelOpacity)
                    .frame(width: labelSize.width, height: labelSize.height)
            }
            // FIXED: Using alignment .bottom here is crucial for upward growth
            .frame(width: labelSize.width + rWidth, height: labelSize.height + rHeight, alignment: .bottom)
            .compositingGroup()
            .clipShape(.rect(cornerRadius: cornerRadius))
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        }
        .scaleEffect(
            x: 1 - (blurProgress * 0.4),
            y: 1 + (blurProgress * 0.25),
            anchor: .bottom // Anchored growth
        )
    }

    var labelOpacity: CGFloat { min(progress / 0.35, 1) }
    var contentOpacity: CGFloat { max(progress - 0.35, 0) / 0.65 }
    var blurProgress: CGFloat { progress > 0.5 ? (1 - progress) / 0.5 : progress / 0.5 }

    var contentScale: CGFloat {
        let minAspectScale = min(labelSize.width / (contentSize.width > 0 ? contentSize.width : 1), 
                                 labelSize.height / (contentSize.height > 0 ? contentSize.height : 1))
        return minAspectScale + (1 - minAspectScale) * progress
    }
}
