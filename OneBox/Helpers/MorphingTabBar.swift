//
//  MorphingTabBar.swift
//  OneBox
//
//  Created by Aryan singh on 26/03/26.
//

import SwiftUI

struct MorphingTabBar<Tab: MorphingTabProtocol, ExpandedContent: View>: View {
    @Binding var activeTab: Tab
    @Binding var isExpanded: Bool
    @ViewBuilder var expandedContent: ExpandedContent
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            ZStack {
                let symbols = Array(Tab.allCases).compactMap({$0.symbolImage})
                let allCases = Array(Tab.allCases)
                let selectedIndex = Binding {
                    return allCases.firstIndex(of: activeTab) ?? 0
                } set: { index in
                    activeTab = allCases[index]
                }

                // FIXED: Passing .bottom alignment here to lock the expansion anchor
                ExpandableGlassEffect(alignment: .bottom, progress: isExpanded ? 1 : 0, labelSize: CGSize(width: width, height: 52), cornerRadius: 26) {
                    expandedContent
                        .opacity(isExpanded ? 1 : 0)
                        .frame(width: width)
                } label: {
                    CustomTabBar(symbols: symbols, index: selectedIndex) { image in
                        let font = UIFont.systemFont(ofSize: 19)
                        let configuration = UIImage.SymbolConfiguration(font: font)
                        return UIImage(systemName: image, withConfiguration: configuration)
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 2)
                    .offset(y: -0.7)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: isExpanded ? nil : 52) 
    }
}

// CustomTabBar UIViewRepresentable stays exactly as it was
fileprivate struct CustomTabBar: UIViewRepresentable {
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

        DispatchQueue.main.async {
            for view in control.subviews.dropLast() {
                if view is UIImageView { view.alpha = 0 }
            }
        }
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        if uiView.selectedSegmentIndex != index {
            uiView.selectedSegmentIndex = index
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    class Coordinator: NSObject {
        var parent: CustomTabBar
        init(parent: CustomTabBar) { self.parent = parent }
        @objc func disSelect(_ control: UISegmentedControl) { parent.index = control.selectedSegmentIndex }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        return proposal.replacingUnspecifiedDimensions()
    }
}
