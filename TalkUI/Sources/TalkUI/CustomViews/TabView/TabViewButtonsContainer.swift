//
//  TabViewButtonsContainer.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI

struct TabViewButtonsContainer: View {
    @Binding var selectedTabIndex: Int
    let tabs: [Tab]
    @Namespace var id

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                ForEach(tabs) { tab in
                    let index = tabs.firstIndex(where: { $0.title == tab.title })
                    Button {
                        selectedTabIndex = index ?? 0
                    } label: {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                if let icon = tab.icon {
                                    Image(systemName: icon)
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(Color.App.gray1)
                                        .fixedSize()
                                }
                                Text(String(localized: .init(tab.title)))
                                    .font(index == selectedTabIndex ? . iransansBoldCaption : .iransansCaption)
                                    .fixedSize()
                                    .foregroundStyle(index == selectedTabIndex ? Color.App.text : Color.App.hint)
                            }
                            .padding([.trailing, .leading], 8)

                            if index == selectedTabIndex {
                                Rectangle()
                                    .fill(Color.App.primary)
                                    .frame(height: 3)
                                    .cornerRadius(2, corners: [.topLeft, .topRight])
                                    .matchedGeometryEffect(id: "DetailTabSeparator", in: id)

                            }
                        }
                        .frame(height: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
            }
            .animation(.spring(), value: selectedTabIndex)
            .padding([.leading, .trailing])
        }
    }
}

struct TabViewButtonsContainer_Previews: PreviewProvider {
    static var previews: some View {
        TabViewButtonsContainer(selectedTabIndex: .constant(0), tabs: [])
    }
}
