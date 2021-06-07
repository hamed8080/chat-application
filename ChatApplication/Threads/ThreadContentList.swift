//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct ThreadContentList:View {
    
    @StateObject var viewModel:ThreadsViewModel
    @State var connectionStatus:String?     = "Connecting ..."
    
    var body: some View{
        NavigationView{
            GeometryReader{ reader in
                List {
                    ForEach(viewModel.model.threads , id:\.id) { thread in
                        ThreadRow(thread: thread)
                            .onAppear {
                                if viewModel.model.threads.last == thread{
                                    viewModel.loadMore()
                                }
                            }
                    }.onDelete(perform: { indexSet in
                        print("on delete")
                    })
                }.listStyle(PlainListStyle())
                LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
            }
            .navigationBarTitle(Text("Chats"), displayMode: .inline)
            .toolbar{
                ToolbarItem(placement:.navigationBarLeading){
                    Text(connectionStatus ?? "")
                        .font(.headline)
                        .foregroundColor(Color.gray)
                }
            }
        }.onReceive(NotificationCenter.default.publisher(for: CONNECTION_STATUS_NAME_OBJECT), perform: { value in
            connectionStatus = value.object as? String
        })
       
    }
}

struct ThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadsViewModel()
        ThreadContentList(viewModel: vm)
            .onAppear(){
                vm.setupPreview()
            }
    }
}
