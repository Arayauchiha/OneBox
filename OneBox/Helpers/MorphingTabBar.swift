//
//  MorphingTabBar.swift
//  OneBox
//
//  Created by Aryan singh on 26/03/26.
//

import SwiftUI

protocol MorphingTabProtocol: CaseIterable, Hashable {
    var symbolImage: String { get }
}

struct MorphingTabBar<Tab: MorphingTabProtocol, ExpandedContent: View>: View {
    @Binding var activeTab: Tab
    @Binding var isExpanded: Bool
    @ViewBuilder var expandedContent: ExpandedContent
    /// View Properties
    @State private var viewWidth: CGFloat?

    var body: some View {
        ZStack {
            let symbols = Array(Tab.allCases).compactMap { $0.symbolImage }
            let selectedIndex = Binding {
                symbols.firstIndex(of: activeTab.symbolImage) ?? 0
            } set: {
                index in
                activeTab = Array(Tab.allCases)[index]
            }

            if let viewWidth {
                let progress: CGFloat = isExpanded ? 1 : 0
                let labelSize = CGSize(width: viewWidth, height: 52)
                let cornerRadius: CGFloat = labelSize.height / 2

                ExpandableGlassEffect(alignment: .center, progress: progress, labelSize: labelSize, cornerRadius: cornerRadius) {
                    expandedContent

                } label: {
                    CustomTabBar(symbols: symbols, index: selectedIndex) { image in
                        let font = UIFont.systemFont(ofSize: 19)
                        let confirguation = UIImage.SymbolConfiguration(font: font)

                        return UIImage(systemName: image, withConfiguration: confirguation)
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 2)
                    .offset(y: -0.7)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: { newValue in
            viewWidth = newValue
        }
        .frame(height: viewWidth == nil ? 52 : nil)
    }
}

private struct CustomTabBar: UIViewRepresentable {
    var tint: Color = .gray.opacity(0.15)
    var symbols: [String]
    @Binding var index: Int
    var image: (String) -> UIImage?

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: symbols)
        control.selectedSegmentIndex = index
        control.selectedSegmentTintColor = UIColor(tint)
        for (index, symbol) in symbols.enumerated() {
            control.setImage(image(symbol), forSegmentAt: index)
        }

        control.addTarget(context.coordinator, action: #selector(Coordinator.disSelect(_:)), for: .valueChanged)

        // Removing Background Color
        DispatchQueue.main.async {
            for view in control.subviews.dropLast() {
                if view is UIImageView {
                    view.alpha = 0
                }
            }
        }

        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context _: Context) {
        if uiView.selectedSegmentIndex != index {
            uiView.selectedSegmentIndex = index
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject {
        var parent: CustomTabBar
        init(parent: CustomTabBar) {
            self.parent = parent
        }

        @objc
        func disSelect(_ control: UISegmentedControl) {
            parent.index = control.selectedSegmentIndex
        }
    }

    /// Free size!
    func sizeThatFits(_ proposal: ProposedViewSize, uiView _: UISegmentedControl, context _: Context) -> CGSize? {
        return proposal.replacingUnspecifiedDimensions()
    }
}

#Preview {
    ContentView()
}
