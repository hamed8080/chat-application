//
//  TabButtonsContainer.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkUI

struct TabButtonsContainer: View {
    @Binding var selectedId: String
    let tabs: [TabItem]

    var body: some View {
        HStack {
            ForEach(tabs) { tab in
                Spacer()
                TabButtonItem(title: tab.title,
                              image: tab.image,
                              imageView: tab.tabImageView,
                              contextMenu: tab.contextMenus,
                              isSelected: selectedId == tab.title) {
                    selectedId = tab.title
                    NotificationCenter.default.post(name: .selectTab, object: tab.title)
                }
                Spacer()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .frame(height: 36)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .background(MixMaterialBackground().ignoresSafeArea())
    }
}

struct TabItems_Previews: PreviewProvider {
    static var previews: some View {
        TabButtonsContainer(selectedId: .constant(""), tabs: [])
    }
}
