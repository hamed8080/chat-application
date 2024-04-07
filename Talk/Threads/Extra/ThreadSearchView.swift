//
//  ThreadSearchView.swift
//  Talk
//
//  Created by hamed on 11/11/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct ThreadSearchView: View {
    @EnvironmentObject var viewModel: ThreadsSearchViewModel

    var body: some View {
        if viewModel.searchText.count > 0 {
            List {
                if viewModel.searchedContacts.count > 0 {
                    StickyHeaderSection(header: "Contacts.searched", height: 4)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.zero)
                }

                ForEach(viewModel.searchedContacts.prefix(5)) { contact in
                    ContactRow(isInSelectionMode: .constant(false))
                        .environmentObject(contact)
                        .listRowInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 8)) /// We usre 16 leading due to in ThreadRow we have a yellow bar and it causes spacing in VStack to add 16 pixels, so we have to keep Contacts and Threads row in same alignmen.
                        .listRowBackground(Color.App.bgPrimary)
                        .onTapGesture {
                            AppState.shared.openThread(contact: contact)
                        }
                }

                if viewModel.searchedConversations.count > 0 {
                    StickyHeaderSection(header: "Tab.chats", height: 4)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.zero)
                }

                ForEach(viewModel.searchedConversations) { thread in
                    ThreadRow(thread: thread) {
                        AppState.shared.objectsContainer.navVM.append(thread: thread)
                    }
                    .listRowInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
                    .listRowSeparatorTint(Color.App.dividerSecondary)
                    .listRowBackground(thread.pin == true ? Color.App.bgSecondary : Color.App.bgPrimary)
                    .onAppear {
                        if self.viewModel.searchedConversations.last == thread {
                            viewModel.loadMore()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(MixMaterialBackground())
            .environment(\.defaultMinListRowHeight, 24)
            .animation(.easeInOut, value: viewModel.searchedContacts.count)
            .animation(.easeInOut, value: viewModel.searchedConversations.count)
        }
    }
}

struct ThreadSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSearchView()
    }
}
