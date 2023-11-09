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
    var viewModel: ThreadOrContactPickerViewModel = .init()
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
            .frame(minWidth: 0, maxWidth: .infinity)
            .environmentObject(viewModel)
            .background(Color.App.bgPrimary)
            .listStyle(.plain)
            .safeAreaInset(edge: .top, spacing: 0) {
                SearchInSelectConversationOrContact()
                    .environmentObject(viewModel)
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

    var body: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                ThreadRow(isSelected: false, thread: conversation)
                    .listRowBackground(Color.App.bgPrimary)
                    .onTapGesture {
                        onSelect(conversation, nil)
                        dismiss()
                    }
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: viewModel.conversations.count)
    }
}


struct SelectContactTab: View {
    @EnvironmentObject var viewModel: ThreadOrContactPickerViewModel
    var onSelect: (Conversation?, Contact?) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(viewModel.contacts) { contact in
                ContactRow(isInSelectionMode: .constant(false), contact: contact, isMainContactTab: false)
                    .onTapGesture {
                        onSelect(nil, contact)
                        dismiss()
                    }
                    .listRowBackground(Color.App.bgPrimary)
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: viewModel.contacts.count)
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
