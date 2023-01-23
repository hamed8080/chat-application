//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

struct ThreadContentList: View {
    @EnvironmentObject var navModel: NavigationModel
    @EnvironmentObject var viewModel: ThreadsViewModel
    @State var searchText: String = ""

    var body: some View {
        List(viewModel.filtered, selection: $navModel.selectedThreadId) { thread in
            NavigationLink(value: thread.id) {
                ThreadRow(thread: thread)
                    .environmentObject(viewModel) // wen need to inject viewmodel here because inside threadRow we are using the global viewmodel injection
                    .onAppear {
                        if self.viewModel.filtered.last == thread {
                            viewModel.loadMore()
                        }
                    }
            }
        }
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "Search...")
        .onChange(of: searchText) { searchText in
            viewModel.searchText = searchText
            viewModel.getThreads()
        }
        .animation(.easeInOut, value: viewModel.filtered)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.toggleThreadContactPicker.toggle()
                } label: {
                    Label {
                        Text("Start new chat")
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                ConnectionStatusToolbar()
            }
        }
        .navigationTitle(viewModel.title)
        .sheet(isPresented: $viewModel.showAddParticipants) {
            AddParticipantsToThreadView(viewModel: .init()) { contacts in
                viewModel.addParticipantsToThread(contacts)
                viewModel.showAddParticipants.toggle()
            }
        }
        .sheet(isPresented: $viewModel.showAddToTags) {
            AddThreadToTagsView(viewModel: viewModel.tagViewModel) { tag in
                viewModel.threadAddedToTag(tag)
                viewModel.showAddToTags.toggle()
            }
        }
        .sheet(isPresented: $viewModel.toggleThreadContactPicker) {
            StartThreadContactPickerView(viewModel: .init()) { model in
                viewModel.createThread(model)
                viewModel.toggleThreadContactPicker.toggle()
            }
        }
    }
}

struct ThreadContentList_Previews: PreviewProvider {
    @State static var vm = ThreadsViewModel()
    static var previews: some View {
        let appState = AppState.shared

        ThreadContentList()
            .environmentObject(vm)
            .environmentObject(appState)
            .onAppear {
                vm.title = "chats"
                vm.appendThreads(threads: MockData.generateThreads(count: 5))
            }
    }
}
