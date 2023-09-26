//
//  TabContainerView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI

struct TabItem: Identifiable {
    let tabContent: any View
    let contextMenus: (any View)?
    let title: String
    let iconName: String
    var id: String { title }

    init(tabContent: any View, contextMenus: (any View)? = nil, title: String, iconName: String) {
        self.tabContent = tabContent
        self.contextMenus = contextMenus
        self.title = title
        self.iconName = iconName
    }
}

struct TabContainerView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let ipadSidebarWidth: CGFloat = 400
    let isIpad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    var maxWidth: CGFloat { sizeClass == .compact || !isIpad ? .infinity : ipadSidebarWidth }
    /// We need to get min because in if maxWidth is equal to '.infinity' it is always bigger than all views.
    var computedWidth: CGFloat { min(maxWidth, ipadSidebarWidth) }
    @State var selectedId = "chats"
    let tabs: [TabItem]

    var body: some View {
        ZStack {
            ForEach(tabs) { tab in
                AnyView(tab.tabContent)
                    .offset(x: selectedId == tab.title ? 0 : -(computedWidth))
            }
        }
        .safeAreaInset(edge: .bottom) {
            EmptyView()
                .frame(width: 0, height: 46)
        }
        .frame(minWidth: 0, maxWidth: computedWidth)
        .overlay(alignment: .bottom) {
            TabItems(selectedId: $selectedId, tabs: tabs)
        }
    }
}

struct SideBar_Previews: PreviewProvider {
    static var previews: some View {
        TabContainerView(tabs: [])
    }
}
