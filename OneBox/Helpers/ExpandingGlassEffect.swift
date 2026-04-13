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
        GlassEffectContainer {
            let widthDiff = contentSize.width - labelSize.width
            let heightDiff = max(contentSize.height - labelSize.height, 0)

            let rWidth = widthDiff * contentOpacity
            let rHeight = heightDiff * contentOpacity

            ZStack(alignment: alignment) {
                content
                    .compositingGroup()
                    .scaleEffect(contentScale, anchor: scaleAnchor)
                    .blur(radius: 12 * blurProgress)
                    .opacity(contentOpacity)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { contentSize = $0 }
                    .fixedSize(horizontal: false, vertical: true)

                label
                    .compositingGroup()
                    .blur(radius: 12 * blurProgress)
                    .opacity(1 - labelOpacity)
                    .frame(width: labelSize.width, height: labelSize.height)
            }
            .frame(width: labelSize.width + rWidth, height: labelSize.height + rHeight)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        }
        .offset(y: offset * (1 - blurProgress)) // THE ORIGINAL PHYSICS
    }

    var labelOpacity: CGFloat { min(progress / 0.35, 1) }
    var contentOpacity: CGFloat { max(progress - 0.35, 0) / 0.65 }
    var blurProgress: CGFloat { progress > 0.5 ? (1 - progress) / 0.5 : progress / 0.5 }

    var contentScale: CGFloat {
        let minAspectScale = min(labelSize.width / max(contentSize.width, 1), labelSize.height / max(contentSize.height, 1))
        return minAspectScale + (1 - minAspectScale) * progress
    }

    var offset: CGFloat {
        // ORIGINAL UPWARD OFFSET
        let expandedHeight = contentSize.height
        return isExpanded ? -expandedHeight / 2.3 : 0
    }
    
    var isExpanded: Bool { progress > 0.5 }

    var scaleAnchor: UnitPoint {
        switch alignment {
        case .bottomLeading, .bottom: return .bottom
        case .topLeading, .top: return .top
        default: return .center
        }
    }
}
