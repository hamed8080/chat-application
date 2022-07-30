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
                    if viewModel.model.archivedThreads.count > 0 {
                        NavigationLink {
                            ArchivedThreadContentList(viewModel: viewModel)
                        } label: {
                            archiveThreadsRow
                        }
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
                        ForEach(viewModel.model.threads.filter({$0.isArchive == false || $0.isArchive == nil }) , id:\.id) { thread in

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

    var archiveThreadsRow:some View{
        HStack{
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 64, height: 64)
                .overlay{
                    Image(systemName: "tray.and.arrow.down.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .font(.system(size: 24).bold())
                        .foregroundColor(.white)
                }


            VStack(alignment: .leading, spacing:8){
                Text("Archives")
                    .font(.headline.bold())
                if let message = viewModel.model.archivedThreads.sorted(by: { $0.lastMessageVO?.time ?? 0 > $1.lastMessageVO?.time ?? 0 }).first?.lastMessageVO?.message?.prefix(100){
                    Text(message)
                        .lineLimit(1)
                        .font(.subheadline)
                }
            }
        }
        .contentShape(Rectangle())
        .padding([.leading , .trailing] , 8)
        .padding([.top , .bottom] , 4)
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
