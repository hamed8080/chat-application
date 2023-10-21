//
//  TabContainerView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI

struct TabContainerConfig {
    let alignment: Alignment
}

struct TabItem: Identifiable {
    let tabContent: any View
    let contextMenus: (any View)?
    let title: String
    let iconName: String?
    var id: String { title }

    init(tabContent: any View, contextMenus: (any View)? = nil, title: String, iconName: String? = nil) {
        self.tabContent = tabContent
        self.contextMenus = contextMenus
        self.title = title
        self.iconName = iconName
    }

    var image: Image? {
        if let iconName = iconName {
           return Image(systemName: iconName)
        } else {
           return nil
        }
    }
}

struct TabContainerView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    /// For iPadOs in splitview there is a need for fixed size.
    let iPadMaxAllowedWidth: CGFloat
    let isIpad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    var maxWidth: CGFloat { sizeClass == .compact || !isIpad ? .infinity : iPadMaxAllowedWidth }
    /// We need to get min because in if maxWidth is equal to '.infinity' it is always bigger than all views.
    var computedWidth: CGFloat { min(maxWidth, iPadMaxAllowedWidth) }
    @State var selectedId: String
    let tabs: [TabItem]
    let config: TabContainerConfig

    init(iPadMaxAllowedWidth: CGFloat = .infinity,
         selectedId: String,
         tabs: [TabItem] = [],
         config: TabContainerConfig) {
        self.iPadMaxAllowedWidth = iPadMaxAllowedWidth
        self.tabs = tabs
        self.config = config
        self._selectedId = State(wrappedValue: selectedId)
    }

    var body: some View {
        GeometryReader { reader in
            let screenWidth = reader.size.width
            ZStack {
                ForEach(tabs) { tab in
                    AnyView(tab.tabContent)
                        .offset(x: selectedId == tab.title ? 0 : -(screenWidth + 200))
                }
            }
            .safeAreaInset(edge: .bottom) {
                EmptyView()
                    .frame(width: 0, height: 46)
            }
            .frame(minWidth: 0, maxWidth: maxWidth)
            .overlay(alignment: config.alignment) {
                TabButtonsContainer(selectedId: $selectedId, tabs: tabs)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .frame(minWidth: 0, maxWidth: maxWidth)
    }
}

struct SideBar_Previews: PreviewProvider {
    static var previews: some View {
        TabContainerView(iPadMaxAllowedWidth: 400, selectedId: "chats", tabs: [], config: .init(alignment: .bottom))
    }
}
