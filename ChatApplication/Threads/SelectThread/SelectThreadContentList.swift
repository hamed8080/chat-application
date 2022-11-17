//
//  SelectThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct SelectThreadContentList:View {
    
    @EnvironmentObject
    var viewModel: ThreadsViewModel
    
    @State
    var searechInsideThread:String = ""
    
    var onSelect:(Conversation)->()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View{
        PageWithNavigationBarView(title: .constant("Select Thread"), subtitle:nil,trailingItems: [], leadingItems: []){
            GeometryReader{ reader in
                VStack(spacing:0){
                    List {
                        MultilineTextField("Search ...",text: $searechInsideThread,backgroundColor:Color.gray.opacity(0.2))
                            .cornerRadius(16)
                            .noSeparators()
                            .onChange(of: searechInsideThread) { newValue in
                                viewModel.searchInsideAllThreads(text: searechInsideThread)
                            }
                        
                        ForEach(viewModel.filtered.map{$0.thread} , id:\.id) { thread in
                            SelectThreadRow(thread: thread)
                                .onTapGesture {
                                    onSelect(thread)
                                    dismiss()
                                }
                                .onAppear {
                                    if viewModel.filtered.last?.thread == thread{
                                        viewModel.loadMore()
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    Spacer()
                }
                .padding(.top)
            }
        }
    }
}

struct SelectThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = ThreadsViewModel()
        SelectThreadContentList()
        { selectedThread in
            
        }
        .onAppear(){
            vm.setupPreview()
        }
        .environmentObject(vm)
        .environmentObject(appState)
    }
}
