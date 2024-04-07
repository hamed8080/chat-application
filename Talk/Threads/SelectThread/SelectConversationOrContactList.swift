//
//  SelectConversationOrContactList.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct SelectConversationOrContactList: View {
    @StateObject var viewModel: ThreadOrContactPickerViewModel = .init()
    var onSelect: (Conversation?, Contact?) -> Void
    @Environment(\.dismiss) var dismiss
    @State var selectedTabId: Int = 0
    let tabs: [Tab]

    init(onSelect: @escaping (Conversation?, Contact?) -> Void) {
        self.onSelect = onSelect
        tabs = [
            .init(title: "Tab.chats", view: AnyView(SelectConversationTab(onSelect: onSelect))),
            .init(title: "Tab.contacts", view: AnyView(SelectContactTab(onSelect: onSelect)))
        ]
    }

    var body: some View {
        CustomTabView(selectedTabIndex: $selectedTabId, tabs: tabs)
            .frame(minWidth: 300, maxWidth: .infinity)/// We have to use a fixed minimum width for a bug tabs goes to the end.
            .environmentObject(viewModel)
            .background(Color.App.bgPrimary)
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) {
                SearchInSelectConversationOrContact()
                    .environmentObject(viewModel)
            }
            .onDisappear {
                viewModel.cancelObservers()
            }
    }
}

struct SearchInSelectConversationOrContact: View {
    @EnvironmentObject var viewModel: ThreadOrContactPickerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("General.searchHere", text: $viewModel.searchText)
                .frame(height: 48)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
        .background(.ultraThinMaterial)
    }
}

struct SelectConversationTab: View {
    @EnvironmentObject var viewModel: ThreadOrContactPickerViewModel
    var onSelect: (Conversation?, Contact?) -> Void
    @Environment(\.dismiss) var dismiss
    private var conversations: [Conversation] { viewModel.conversations.sorted(by: {$0.type == .selfThread && $1.type != .selfThread }) }

    var body: some View {
        List {
            ForEach(conversations) { conversation in
                ThreadRow(forceSelected: false, thread: conversation) {
                    onSelect(conversation, nil)
                    dismiss()
                }
                .listRowBackground(Color.App.bgPrimary)
                .onAppear {
                    if conversation == conversations.last {
                        viewModel.loadMore()
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if viewModel.isLoadingConversation {
                SwingLoadingIndicator()
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: viewModel.conversations.count)
        .animation(.easeInOut, value: viewModel.isLoadingConversation)
    }
}

struct SelectContactTab: View {
    @EnvironmentObject var viewModel: ThreadOrContactPickerViewModel
    var onSelect: (Conversation?, Contact?) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(viewModel.contacts) { contact in
                ContactRow(isInSelectionMode: .constant(false))
                    .environmentObject(contact)
                    .onTapGesture {
                        onSelect(nil, contact)
                        dismiss()
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .onAppear {
                        if contact == viewModel.contacts.last {
                            viewModel.loadMoreContacts()
                        }
                    }
            }
        }
        .safeAreaInset(edge: .top) {
            if viewModel.isLoadingContacts {
                SwingLoadingIndicator()
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: viewModel.contacts.count)
        .animation(.easeInOut, value: viewModel.isLoadingContacts)
    }
}

struct SelectThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = ThreadsViewModel()
        SelectConversationOrContactList { (conversation, contact) in
        }
        .onAppear {}
        .environmentObject(vm)
        .environmentObject(appState)
    }
}
