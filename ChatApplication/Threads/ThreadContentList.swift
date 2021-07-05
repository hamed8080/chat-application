//
//  ThreadContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct ThreadContentList:View {
    
    @StateObject var viewModel:ThreadsViewModel
    
    var body: some View{
        NavigationView{
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
                        print("on delete")
                    })
				}.listStyle(PlainListStyle())
                LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
            }
            .navigationBarTitle(Text("Chats"), displayMode: .inline)
            .toolbar{
                ToolbarItem(placement:.navigationBarLeading){
                    Text(viewModel.model.connectionStatus ?? "")
                        .font(.headline)
                        .foregroundColor(Color.gray)
                }
            }
        }
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
