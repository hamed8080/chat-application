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

    var body: some View {
        List {
            ListLoadingView(isLoading: $viewModel.isLoading)
            if let folder = folder {
                ForEach(folder.tagParticipants ?? []) { tagParticipant in
                    if let tagParticipant = tagParticipant.conversation, let thread = viewModel.threads.first { $0.id == tagParticipant.id } ?? tagParticipant {
                        NavigationLink {
                            ThreadView(thread: thread)
                        } label: {
                            ThreadRow(thread: thread)
                                .environmentObject(viewModel) // wen need to inject viewmodel here because inside threadRow we are using the global viewmodel injection
                        }
                    }
                }
            } else {
                ForEach(viewModel.filtered) { thread in
                    NavigationLink {
                        ThreadView(thread: thread)
                    } label: {
                        ThreadRow(thread: thread)
                            .onAppear {
                                if self.viewModel.filtered.last == thread {
                                    viewModel.loadMore()
                                }
                            }
                    }
                }
            }
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
