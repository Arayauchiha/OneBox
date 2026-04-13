import SwiftUI

struct MorphingTabBar<Tab: MorphingTabProtocol, ExpandedContent: View>: View {
    @Binding var activeTab: Tab
    @Binding var isExpanded: Bool
    @ViewBuilder var expandedContent: ExpandedContent
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            ZStack(alignment: .bottom) {
                ExpandableGlassEffect(
                    alignment: .bottom,
                    progress: isExpanded ? 1 : 0,
                    labelSize: CGSize(width: width, height: 72),
                    cornerRadius: 36,
                    content: {
                        expandedContent
                            .opacity(isExpanded ? 1 : 0)
                            .frame(width: width)
                    },
                    label: {
                        HStack(spacing: 0) {
                            ForEach(Array(Tab.allCases), id: \.self) { tab in
                                VStack(spacing: 4) {
                                    Image(systemName: tab.symbolImage)
                                        .font(.system(size: 20, weight: .bold))
                                    Text(tab.rawValue)
                                        .font(.system(size: 10, weight: .black))
                                        .kerning(0.5)
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(activeTab == tab ? Color.primary : Color.secondary.opacity(0.4))
                                .contentShape(.rect)
                                .onTapGesture { activeTab = tab }
                            }
                        }
                        .frame(width: width, height: 72)
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 72)
    }
}
