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
                ForEach(folder.tagParticipants ?? [], id: \.id) { tagParticipant in
                    if let thread = tagParticipant.conversation, let threadVM = viewModel.threadsRowVM.first { $0.threadId == thread.id } ?? ThreadViewModel(thread: thread) {
                        NavigationLink {
                            ThreadView(viewModel: threadVM)
                        } label: {
                            ThreadRow(viewModel: threadVM)
                        }
                    }
                }
            } else {
                ForEach(viewModel.filtered, id: \.self) { threadVM in
                    NavigationLink {
                        ThreadView(viewModel: threadVM)
                    } label: {
                        ThreadRow(viewModel: threadVM)
                            .onAppear {
                                if self.viewModel.filtered.last == threadVM {
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
            .onAppear {
                vm.appendThreads(threads: MockData.generateThreads(count: 5))
            }
            .environmentObject(vm)
            .environmentObject(appState)
    }
}
