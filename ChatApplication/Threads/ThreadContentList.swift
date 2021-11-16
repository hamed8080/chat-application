//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct ThreadContentList:View {
    
    @StateObject var viewModel:ThreadsViewModel
    
    @EnvironmentObject var appState:AppState
    
    var body: some View{
        GeometryReader{ reader in
            List {
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
            .padding(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
            .listStyle(PlainListStyle())
            Spacer()
            LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
            NavigationLink(destination: ThreadView(viewModel: ThreadViewModel()) ,isActive: $appState.showThread) {
                EmptyView()
            }
            .sheet(isPresented: $viewModel.toggleThreadContactPicker, onDismiss: nil, content: {
                StartThreadContactPickerView(viewModel: .init())
            })
            .onAppear{
                appState.selectedThread = nil
            }
            .navigationBarTitle("Chats",displayMode: .inline)
        }.onAppear {
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
