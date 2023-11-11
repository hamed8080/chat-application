//
//  ConversationTopSafeAreaInset.swift
//  Talk
//
//  Created by hamed on 11/11/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct ConversationTopSafeAreaInset: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel
    let container: ObjectsContainer

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                title: "Tab.chats",
                searchPlaceholder: "General.searchHere",
                leadingViews: EmptyView().frame(width: 0, height: 0).hidden(),
                centerViews: ConnectionStatusToolbar(),
                trailingViews: ConversationPlusContextMenu()
            ) { searchValue in
                container.contactsVM.searchContactString = searchValue
                threadsVM.searchText = searchValue
            }

            if UIApplication.shared.isInSlimMode {
                AudioPlayerView()
            }
            ThreadSearchView()

            if threadsVM.threads.count == 0, threadsVM.firstSuccessResponse, UIApplication.shared.isInSlimMode {
                NothingHasBeenSelectedView(contactsVM: container.contactsVM)
            }
        }
    }
}

struct ConversationTopSafeAreaInset_Previews: PreviewProvider {
    static var previews: some View {
        ConversationTopSafeAreaInset(container: ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance))
    }
}