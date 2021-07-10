//
//  ParticipantsContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct ParticipantsContentList:View {
    
	var threadId:Int
	
    @StateObject
	private var viewModel:ParticipantsViewModel = ParticipantsViewModel()
    
    var body: some View{
        NavigationView{
            GeometryReader{ reader in
                List {
                    ForEach(viewModel.model.participants , id:\.id) { participant in
                        ParticipantRow(participant: participant,viewModel: viewModel)
                            .onAppear {
//                                if viewModel.model.threads.last == thread{
//                                    viewModel.loadMore()
//                                }
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

struct ParticipantContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ParticipantsViewModel()
		ParticipantsContentList(threadId: 0)
            .onAppear(){
                vm.setupPreview()
            }
    }
}
