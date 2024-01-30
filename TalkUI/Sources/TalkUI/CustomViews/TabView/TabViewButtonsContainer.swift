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
    @State private var width: CGFloat = 0
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                HStack(spacing: 28) {
                    ForEach(tabs) { tab in
                        let index = tabs.firstIndex(where: { $0.title == tab.title })
                        Button {
                            selectedTabIndex = index ?? 0
                        } label: {
                            VStack(spacing: 6) {
                                HStack(spacing: 8) {
                                    if let icon = tab.icon {
                                        Image(systemName: icon)
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(Color.App.textSecondary)
                                            .fixedSize()
                                    }
                                    Text(String(localized: .init(tab.title)))
                                        .font(index == selectedTabIndex ? . iransansBoldCaption : .iransansCaption)
                                        .fixedSize()
                                        .foregroundStyle(index == selectedTabIndex ? Color.App.textPrimary : Color.App.textSecondary)
                                }
                                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))

                                if index == selectedTabIndex {
                                    Rectangle()
                                        .fill(Color.App.accent)
                                        .frame(height: 3)
                                        .cornerRadius(2, corners: [.topLeft, .topRight])
                                        .matchedGeometryEffect(id: "DetailTabSeparator", in: id)
                                }
                            }
                            .frame(height: 48)
                            .contentShape(Rectangle())
                            .fixedSize(horizontal: true, vertical: true)
                        }
                        .buttonStyle(.plain)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                    }
                }
                .animation(.spring(), value: selectedTabIndex)
                .padding([.leading, .trailing])
                Spacer()
            }
            .frame(width: sizeClass == .regular ? width : nil)
        }
        .background(frameReader)
    }

    private var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                width = reader.size.width
            }
        }
    }
}

struct TabViewButtonsContainer_Previews: PreviewProvider {
    static var previews: some View {
        TabViewButtonsContainer(selectedTabIndex: .constant(0), tabs: [])
    }
}
