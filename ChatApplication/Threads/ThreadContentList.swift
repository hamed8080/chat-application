//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import ChatAppExtensions
import ChatAppUI
import ChatAppViewModels
import ChatModels
import Combine
import SwiftUI

struct ThreadContentList: View {
    @EnvironmentObject var container: ObjectsContainer
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @State var searchText: String = ""

    var body: some View {
        List(threadsVM.filtered, selection: $container.navVM.selectedThreadId) { thread in
            NavigationLink(value: thread.id) {
                ThreadRow(thread: thread)
                    .onAppear {
                        if self.threadsVM.filtered.last == thread {
                            threadsVM.loadMore()
                        }
                    }
            }
            .listRowBackground(container.navVM.selectedThreadId == thread.id ? Color.orange.opacity(0.5) : Color(UIColor.systemBackground))
        }
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $container.threadsVM.isLoading)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search...")
        .onChange(of: searchText) { searchText in
            threadsVM.searchText = searchText
            threadsVM.getThreads()
        }
        .animation(.easeInOut, value: threadsVM.filtered)
        .animation(.easeInOut, value: threadsVM.isLoading)
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                trailingToolbarViews
            }

            ToolbarItem(placement: .principal) {
                ConnectionStatusToolbar()
            }
        }
        .navigationTitle(threadsVM.title)
        .sheet(isPresented: $threadsVM.showAddParticipants) {
            AddParticipantsToThreadView(viewModel: .init()) { contacts in
                threadsVM.addParticipantsToThread(contacts)
                threadsVM.showAddParticipants.toggle()
            }
        }
        .sheet(isPresented: $threadsVM.showAddToTags) {
            AddThreadToTagsView(viewModel: container.tagsVM) { tag in
                container.tagsVM.addThreadToTag(tag: tag, threadId: threadsVM.selectedThraed?.id)
                threadsVM.showAddToTags.toggle()
            }
        }
        .sheet(isPresented: $threadsVM.toggleThreadContactPicker) {
            StartThreadContactPickerView { model in
                threadsVM.createThread(model)
                threadsVM.toggleThreadContactPicker.toggle()
            }
        }
        .sheet(isPresented: $threadsVM.showCreateDirectThread) {
            CreateDirectThreadView { invitee, message in
                threadsVM.fastMessage(invitee, message)
            }
        }
    }

    @ViewBuilder var trailingToolbarViews: some View {
        Menu {
            Button {
                threadsVM.toggleThreadContactPicker.toggle()
            } label: {
                Label("Start a new Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }

            // Send a message to a user without creating a new contact. Directly by their userName or cellPhone number.
            Button {
                threadsVM.showCreateDirectThread = true
            } label: {
                Label("Fast Messaage", systemImage: "arrow.up.circle.fill")
            }

            Button {} label: {
                Label("Create a new Bot", systemImage: "face.dashed.fill")
            }
        } label: {
            Label("Start new chat", systemImage: "plus.square")
        }

        Menu {
            Button {
                threadsVM.selectedFilterThreadType = nil
                threadsVM.refresh()
            } label: {
                if threadsVM.selectedFilterThreadType == nil {
                    Image(systemName: "checkmark")
                }
                Text("All")
            }
            ForEach(ThreadTypes.allCases) { item in
                if let type = item.stringValue {
                    Button {
                        threadsVM.selectedFilterThreadType = item
                        threadsVM.refresh()
                    } label: {
                        if threadsVM.selectedFilterThreadType == item {
                            Image(systemName: "checkmark")
                        }
                        Text("\(type)")
                    }
                }
            }
        } label: {
            Label("Filter threads", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

private struct Preview: View {
    @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)

    var body: some View {
        NavigationStack {
            ThreadContentList()
                .environmentObject(container)
                .environmentObject(container.threadsVM)
                .environmentObject(container.tagsVM)
                .environmentObject(container.loginVM)
                .environmentObject(AppState.shared)
                .environmentObject(container.tokenVM)
                .environmentObject(container.contactsVM)
                .environmentObject(container.navVM)
                .environmentObject(container.settingsVM)
                .onAppear {
                    container.threadsVM.title = "chats"
                    container.threadsVM.appendThreads(threads: MockData.generateThreads(count: 5))
                }
        }
    }
}

struct CreateDirectThreadView: View {
    @State private var type: InviteeTypes = .cellphoneNumber
    @State private var message: String = ""
    @State private var id: String = ""
    var onCompeletion: (Invitee, String) -> Void
    @State var types = InviteeTypes.allCases.filter { $0 != .unknown }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Contact type", selection: $type) {
                        ForEach(types) { value in
                            Text(verbatim: "\(value.title)")
                        }
                    }
                    .pickerStyle(.navigationLink)
                    TextField("Enter \(type.rawValue) here...", text: $id)
                        .keyboardType(type == .cellphoneNumber ? .phonePad : .default)

                    TextField("Enter your message here...", text: $message)
                } footer: {
                    Text("Create a thread immediately even though the person you are going to send a message to is not in the contact list.")
                }

                Button {
                    onCompeletion(Invitee(id: id, idType: type), message)
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "paperplane")
                        Text("Send")
                        Spacer()
                    }
                }
            }
        }
    }
}

struct ThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
//        Preview()
        CreateDirectThreadView { _, _ in }
    }
}
