//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK
import Combine

struct ThreadContentList:View {

    @EnvironmentObject
    var viewModel: ThreadsViewModel

    @State
    var searechInsideThread:String = ""
    
    @State
    var folder:Tag? = nil
    
    var body: some View{
        let  _ = Self._printChanges()
        ZStack{
            VStack(spacing:0){
                List {
                    if let threadsInsideFolder = folder?.tagParticipants{
                        ForEach(threadsInsideFolder, id:\.id) { thread in
                            if let thread = thread.conversation{
                                NavigationLink {
                                    ThreadView(viewModel: ThreadViewModel(thread: thread))
                                } label: {
                                    ThreadRow(viewModel: .init(thread: thread, threadsViewModel: viewModel))
                                }
                            }
                        }
                    }else{
                        ForEach(viewModel.threads, id:\.id) { thread in
                            NavigationLink {
                                LazyView(ThreadView(viewModel: ThreadViewModel(thread: thread)))
                            } label: {
                                ThreadRow(viewModel: .init(thread: thread, threadsViewModel: viewModel))
                                    .onAppear {
                                        if viewModel.threads.last == thread{
                                            viewModel.loadMore()
                                        }
                                    }
                            }
                        }
                    }
                }
                .searchable(text: $viewModel.searchInsideThreadString, placement: .navigationBarDrawer, prompt: "Search...")
                .animation(.easeInOut, value: viewModel.threads)
                .listStyle(.plain)
            }
            
            VStack{
                GeometryReader{ reader in
                    LoadingViewAt(at: .CENTER, isLoading:viewModel.centerIsLoading, reader: reader)
                    LoadingViewAt(at: .BOTTOM, isLoading:viewModel.isLoading, reader: reader)
                }
            }
        }
        .toolbar{
            ToolbarItem{
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
        .navigationTitle(Text( folder?.name ?? "Chats"))
        .sheet(isPresented: $viewModel.showAddParticipants, onDismiss: nil, content: {
            AddParticipantsToThreadView(viewModel: .init()) { contacts in
                viewModel.addParticipantsToThread(contacts)
                viewModel.showAddParticipants.toggle()
            }
        })
        .sheet(isPresented: $viewModel.showAddToTags, onDismiss: nil, content: {
            AddThreadToTagsView(viewModel: viewModel.tagViewModel) { tag in
                viewModel.threadAddedToTag(tag)
                viewModel.showAddToTags.toggle()
            }
        })
        .sheet(isPresented: $viewModel.toggleThreadContactPicker, onDismiss: nil, content: {
            StartThreadContactPickerView(viewModel: .init()) { model in
                viewModel.createThread(model)
                viewModel.toggleThreadContactPicker.toggle()
            }
        })
    }
}

struct ThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = ThreadsViewModel()
        ThreadContentList()
            .onAppear(){
                vm.setupPreview()
            }
            .environmentObject(vm)
            .environmentObject(appState)
    }
}
