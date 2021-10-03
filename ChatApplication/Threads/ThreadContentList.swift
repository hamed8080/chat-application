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
    
    @State var title    :String  = "Chats"
    @State var subtitle :String  = ""
    @State var toggleThreadContactPicker = false
    
    var body: some View{
        GeometryReader{ reader in
            PageWithNavigationBarView(title:$title, subtitle:$appState.connectionStatusString,trailingItems: getTrailingItems()){
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
                }.listStyle(PlainListStyle())
                Spacer()
                LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
                NavigationLink(destination: ThreadView(viewModel: ThreadViewModel()) ,isActive: $appState.showThread) {
                    EmptyView()
                }
            }
            .sheet(isPresented: $toggleThreadContactPicker, onDismiss: nil, content: {
                StartThreadContactPickerView(viewModel: .init())
            })
            .onAppear{
                appState.selectedThread = nil
            }
        }
    }
    
    func getTrailingItems()->[NavBarItem]{
        return [NavBarButton(systemImageName: "square.and.pencil") {
            withAnimation {
                toggleThreadContactPicker.toggle()
            }
        }.getNavBarItem()]
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
