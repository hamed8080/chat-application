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
    @EnvironmentObject var viewModel: ThreadsViewModel
    @State var searchText: String = ""
    @State var folder: Tag?
    @State var archived: Bool = false
    @AppStorage("selectedThread") var selectedThread: Int?
    var threads: [Conversation] {
        if let folder = folder {
            return folder.tagParticipants?
                .compactMap(\.conversation?.id)
                .compactMap { id in viewModel.threads.first { $0.id == id } }
                ?? []
        } else {
            return viewModel.filtered
        }
    }

    var body: some View {
        List(threads) { thread in
            NavigationLink(destination: ThreadView(thread: thread), tag: thread.id ?? -1, selection: $selectedThread) {
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
        .autoNavigateToThread()
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
        .navigationTitle(Text(folder?.name ?? (archived ? "Archive" : "Chats")))
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
        }.onAppear {
            if let selectedThread = selectedThread {
                viewModel.getThreadsWith([selectedThread])
            }
            if let threadIdsInFolder = folder?.tagParticipants?.compactMap(\.conversation?.id) {
                viewModel.getThreadsWith(threadIdsInFolder)
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
                vm.appendThreads(threads: MockData.generateThreads(count: 5))
            }
    }
}
