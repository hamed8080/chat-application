//
//  ConversationTopSafeAreaInset.swift
//  Talk
//
//  Created by hamed on 11/11/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels

struct ConversationTopSafeAreaInset: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel
    let container: ObjectsContainer
    @State var isInSearchMode: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                searchId: "Tab.chats",
                title: "Tab.chats",
                leadingViews: searchButton,
                centerViews: ConnectionStatusToolbar(),
                trailingViews: ConversationPlusContextMenu()
            )
            ThreadListSearchBarFilterView(isInSearchMode: $isInSearchMode)
                .background(MixMaterialBackground())
                .environmentObject(container.searchVM)
            if AppState.isInSlimMode {
                AudioPlayerView()
            }
            ThreadSearchView()
                .environmentObject(container.searchVM)

            if threadsVM.threads.count == 0, threadsVM.firstSuccessResponse, AppState.isInSlimMode {
                NothingHasBeenSelectedView(contactsVM: container.contactsVM)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cancelSearch)) { newValue in
            if let cancelSearch = newValue.object as? Bool, cancelSearch == true, cancelSearch && isInSearchMode {
                isInSearchMode.toggle()
            }
        }
    }

    @ViewBuilder var searchButton: some View {
        if isInSearchMode {
            Button {
                AppState.shared.objectsContainer.contactsVM.searchContactString = ""
                AppState.shared.objectsContainer.searchVM.searchText = ""
                isInSearchMode.toggle()
            } label: {
                Text("General.cancel")
                    .padding(.leading)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.accent)
            }
            .buttonStyle(.borderless)
            .frame(minWidth: 0, minHeight: 0, maxHeight: isInSearchMode ? 38 : 0)
            .clipped()
        } else {
            ToolbarButtonItem(imageName: "magnifyingglass", hint: "Search", padding: 10) {
                withAnimation {
                    isInSearchMode.toggle()
                }
            }
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: isInSearchMode ? 0 : 38)
            .clipped()
            .foregroundStyle(Color.App.accent)
        }
    }
}

struct ConversationTopSafeAreaInset_Previews: PreviewProvider {
    static var previews: some View {
        ConversationTopSafeAreaInset(container: ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance))
    }
}
