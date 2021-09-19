//
//  ThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct ThreadView:View {
    
    @StateObject var viewModel:ThreadViewModel
    
    var body: some View{
        NavigationView{
            GeometryReader{ reader in
                List {
                    ForEach(viewModel.model.messages , id:\.id) { message in
                        MessageRow(message: message,viewModel: viewModel)
                            .onAppear {
                                if viewModel.model.messages.last == message{
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
                    Text(AppState.shared.connectionStatusString)
                        .font(.headline)
                        .foregroundColor(Color.gray)
                }
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel(thread: ThreadRow_Previews.thread)
        ThreadView(viewModel: vm)
            .onAppear(){
                vm.setupPreview()
            }
    }
}
