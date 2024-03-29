//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
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
    }

    @ViewBuilder var trailingToolbarViews: some View {
        Button {
            threadsVM.toggleThreadContactPicker.toggle()
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

struct ThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
}
