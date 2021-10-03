//
//  ThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct ThreadView:View {
    
    @StateObject var viewModel:ThreadViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View{
        GeometryReader{ reader in
            List {
                ForEach(viewModel.model.messages , id:\.id) { message in
                    
                    MessageRow(message: message,viewModel: viewModel)
                        .onAppear {
                            if viewModel.model.messages.last == message{
                                viewModel.loadMore()
                            }
                        }
                        .noSeparators()
                        .listRowBackground(Color.clear)
                }
                .onDelete(perform: { indexSet in
                    print("on delete")
                })
            }
            .listStyle(PlainListStyle())
            LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
        }
        .background(
            ZStack{
                Image("chat_bg")
                    .resizable()
                    .opacity(0.25)
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
            }
        )
        .onAppear{
            if let thread = AppState.shared.selectedThread{
                viewModel.setThread(thread: thread)
            }
        }
        .navigationBarTitle(Text(viewModel.thread?.title ?? ""), displayMode: .inline)
        .toolbar{
            ToolbarItem(placement:.navigationBarLeading){
                Text(AppState.shared.connectionStatusString)
                    .font(.headline)
                    .foregroundColor(Color.gray)
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel()
        ThreadView(viewModel: vm)
            .onAppear(){
                vm.setupPreview()
            }
    }
}
