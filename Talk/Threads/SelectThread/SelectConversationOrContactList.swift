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

    var body: some View {
        List {
            SectionTitleView(title: "Thread.selectToStartConversation")
            Section {
                MultilineTextField("General.searchHere", text: $viewModel.searchText, backgroundColor: Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .noSeparators()
            }
            .listRowBackground(Color.clear)

            Section {
                ListLoadingView(isLoading: $viewModel.isLoading)
                    .listRowBackground(Color.clear)
                ForEach(viewModel.conversations) { conversation in
                    SelectThreadRow(thread: conversation)
                        .onTapGesture {
                            onSelect(conversation, nil)
                            dismiss()
                        }
                }
            } header: {
                Text("Tab.chats")
            }

            if viewModel.contacts.count > 0 {
                Section {
                    ForEach(viewModel.contacts) { contact in
                        SelectContactRow(contact: contact)
                            .onTapGesture {
                                onSelect(nil, contact)
                                dismiss()
                            }
                    }
                } header: {
                    Text("Tab.contacts")
                }
            }
        }
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
