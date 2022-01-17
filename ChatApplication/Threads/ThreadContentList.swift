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
                    MultilineTextField("Search ...",text: $searechInsideThread,backgroundColor:Color.gray.opacity(0.2))
                        .cornerRadius(16)
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
                    }.onDelete(perform: { indexSet in
                        guard let thread = indexSet.map({ viewModel.model.threads[$0]}).first else {return}
                        viewModel.deleteThread(thread)
                    })
                }
                .listStyle(PlainListStyle())
                Spacer()
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
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
                .onChanged({ value in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                })
        )
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
