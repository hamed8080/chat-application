//
//  CustomTabView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI

public struct CustomTabView: View {
    @Binding var selectedTabIndex: Int
    let tabs: [Tab]

    public init(selectedTabIndex: Binding<Int> = .constant(0), tabs: [Tab]) {
        self._selectedTabIndex = selectedTabIndex
        self.tabs = tabs
    }

    public var body: some View {
        VStack(spacing: 0) {
            TabViewButtonsContainer(selectedTabIndex: $selectedTabIndex, tabs: tabs)
            tabs[selectedTabIndex].view
                .transition(.asymmetric(insertion: .push(from: .leading), removal: .move(edge: .trailing)))
        }
    }
}

struct CustomTabView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabView(tabs: [])
    }
}
