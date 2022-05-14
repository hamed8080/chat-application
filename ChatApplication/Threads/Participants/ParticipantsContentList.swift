//
//  ParticipantsContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct ParticipantsContentList:View {
    
    var threadId:Int
    var title = "Participants"
    var style:StyleConfig = .init()
    
    struct StyleConfig{
        var rowStyle = ParticipantRow.StyleConfig()
    }
    
    @StateObject
    var viewModel:ParticipantsViewModel = ParticipantsViewModel()
    
    var body: some View{
        NavigationView{
            GeometryReader{ reader in
                List {
                    ForEach(viewModel.model.participants , id:\.id) { participant in
                        ParticipantRow(participant: participant,style: style.rowStyle)
                            .onAppear {
                                if viewModel.model.participants.last == participant{
                                    viewModel.loadMore()
                                }
                            }
                    }.onDelete(perform: { indexSet in
                        print("on delete")
                    })
				}.listStyle(PlainListStyle())
                LoadingViewAt(isLoading:viewModel.isLoading ,reader:reader)
            }
            .onAppear{
                viewModel.threadId = threadId
                viewModel.getParticipantsIfConnected()
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
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

struct ParticipantContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ParticipantsViewModel()
        ParticipantsContentList(threadId: 0, viewModel: vm)
            .onAppear(){
                vm.setupPreview()
            }
    }
}
