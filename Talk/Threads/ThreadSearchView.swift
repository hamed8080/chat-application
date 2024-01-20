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
    @EnvironmentObject var contactsVM: ContactsViewModel

    var body: some View {
        if viewModel.searchText.count > 0 {
            List {
                if contactsVM.searchedContacts.count > 0 {
                    StickyHeaderSection(header: "Contacts.searched", height: 4)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.zero)
                }

                ForEach(contactsVM.searchedContacts.prefix(5)) { contact in
                    ContactRow(isInSelectionMode: .constant(false), contact: contact)
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
                    .listRowInsets(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
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
            .animation(.easeInOut, value: AppState.shared.objectsContainer.contactsVM.searchedContacts.count)           
        }
    }
}

struct ThreadSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSearchView()
    }
}
