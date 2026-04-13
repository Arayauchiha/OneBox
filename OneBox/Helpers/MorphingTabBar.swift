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
            let allCases = Array(Tab.allCases)
            let symbols = allCases.compactMap({$0.symbolImage})
            let selectedIndex = Binding {
                return allCases.firstIndex(of: activeTab) ?? 0
            } set: { index in
                activeTab = allCases[index]
            }

            let progress: CGFloat = isExpanded ? 1 : 0
            // FIXED: Using real-time 'width' instead of state variable for rotation stability
            let labelSize: CGSize = CGSize(width: width, height: 64)
            let cornerRadius: CGFloat = labelSize.height / 2

            ExpandableGlassEffect(alignment: .bottom, progress: progress, labelSize: labelSize, cornerRadius: cornerRadius) {
                expandedContent
                    .opacity(isExpanded ? 1 : 0)
                    .frame(width: width)
            } label: {
                ZStack {
                    // THE GOLDEN ENGINE (aa54f56)
                    CustomTabBar(symbols: symbols, index: selectedIndex) { image in
                        let font = UIFont.systemFont(ofSize: 1)
                        return UIImage(systemName: image, withConfiguration: UIImage.SymbolConfiguration(font: font))
                    }
                    .frame(height: 60)
                    .padding(.horizontal, 2)
                    
                    // THE TITLED OVERLAY
                    HStack(spacing: 0) {
                        ForEach(allCases, id: \.self) { tab in
                            let isSelected = activeTab == tab
                            VStack(spacing: 4) {
                                Image(systemName: tab.symbolImage)
                                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                Text(tab.rawValue.capitalized)
                                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(isSelected ? .blue : .secondary)
                        }
                    }
                    .padding(.horizontal, 6)
                    .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: isExpanded ? nil : 64)
    }
}

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
        if uiView.selectedSegmentIndex != index { uiView.selectedSegmentIndex = index }
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
