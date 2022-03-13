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
    var isKeyboardShown = false
    
    var body: some View{
        GeometryReader{ reader in
            VStack(spacing:0){
                CustomNavigationBar(title: "Chats",
                                    trailingActions: [
                                        .init(systemImageName: "plus",font: .headline){
                                            viewModel.toggleThreadContactPicker.toggle()
                                        }
                                    ]
                )
                List {
                    MultilineTextField("Search ...",
                                       text: $searechInsideThread,
                                       backgroundColor:Color.gray.opacity(0.2),
                                       keyboardReturnType: .search){ text in
                        isKeyboardShown = false
                    }
                    .cornerRadius(8)
                    .noSeparators()
                    .onChange(of: searechInsideThread) { newValue in
                        viewModel.searchInsideAllThreads(text: searechInsideThread)
                    }
                    
                    ForEach(viewModel.model.threads , id:\.id) { thread in
                        ThreadRow(thread: thread,viewModel: viewModel)
                            .onAppear {
                                if viewModel.model.threads.last == thread{
                                    viewModel.loadMore()
                                }
                            }
                            .onTapGesture {
                                if isKeyboardShown == false{
                                    //navigate to thread only keyboard is not showing
                                    withAnimation {
                                        print("Go to thread ")
                                        appState.selectedThread = thread
                                    }
                                }else{
                                    //hide keyboard and prevent action to navigate to thread
                                    isKeyboardShown = false
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
                .listStyle(PlainListStyle())
                LoadingViewAtCenterOfView(isLoading:viewModel.centerIsLoading ,reader:reader)
                LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
            }
        }
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
        .manageKeyboardForList(isKeyboardShown: $isKeyboardShown)
        .onAppear {
            UINavigationBar.changeAppearance(clear: false)
            viewModel.setViewAppear(appear: true)
        }.onDisappear {
            viewModel.setViewAppear(appear: false)
        }
    }
}

struct ThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = ThreadsViewModel()
        ThreadContentList(viewModel: vm)
            .onAppear(){
                vm.setupPreview()
            }
            .environmentObject(appState)
    }
}
