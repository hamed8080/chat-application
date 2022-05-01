//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct ThreadContentList:View {
    
    @StateObject var viewModel:ThreadsViewModel
    
    @EnvironmentObject var appState:AppState
    
    @State
    var searechInsideThread:String = ""
    
    @State
    var folder:Tag? = nil
    
    var body: some View{
        ZStack{
            VStack(spacing:0){
                List {
                    MultilineTextField("Search ...",
                                       text: $searechInsideThread,
                                       backgroundColor:Color.gray.opacity(0.2),
                                       keyboardReturnType: .search){ text in
                        hideKeyboard()
                    }
                                       .cornerRadius(8)
                                       .noSeparators()
                                       .onChange(of: searechInsideThread) { newValue in
                                           viewModel.searchInsideAllThreads(text: searechInsideThread)
                                       }
                    if let threadsInsideFolder = folder?.tagParticipants{
                        ForEach(threadsInsideFolder, id:\.id) { thread in
                            if let thread = thread.conversation{
                                NavigationLink {
                                    ThreadView(viewModel: ThreadViewModel(thread:thread))
                                } label: {
                                    ThreadRow(thread: thread,viewModel: viewModel)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                viewModel.deleteThread(thread)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }else{
                        ForEach(viewModel.model.threads , id:\.id) { thread in

                            NavigationLink {
                                ThreadView(viewModel: ThreadViewModel(thread:thread))
                            } label: {
                                ThreadRow(thread: thread,viewModel: viewModel)
                                    .onAppear {
                                        if viewModel.model.threads.last == thread{
                                            viewModel.loadMore()
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            viewModel.deleteThread(thread)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            
            VStack{
                GeometryReader{ reader in
                    LoadingViewAtCenterOfView(isLoading:viewModel.centerIsLoading,reader: reader)
                    LoadingViewAtBottomOfView(isLoading:viewModel.isLoading, reader: reader)
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
                if viewModel.connectionStatus != .CONNECTED{
                    Text("\(viewModel.connectionStatus.stringValue) ...")
                        .foregroundColor(Color(named: "text_color_blue"))
                        .font(.subheadline.bold())
                }
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
        ThreadContentList(viewModel: vm)
            .previewDevice("iPad Pro (12.9-inch) (5th generation)")
            .onAppear(){
                vm.setupPreview()
            }
            .environmentObject(appState)
    }
}
