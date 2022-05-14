//
//  CallParticipantsContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct CallParticipantsContentList:View {
    
    var callId:Int
    var isPreview = false
    
    @StateObject
    private var viewModel:CallParticipantsViewModel = CallParticipantsViewModel()
    
    var body: some View{
        GeometryReader{ reader in
            List{
                ForEach(viewModel.model.callParticipants , id:\.id) { participant in
                    CallParticipantRow(participant: participant,viewModel: viewModel)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .frame(width: reader.size.width, height: reader.size.height)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(.all)
            )
            LoadingViewAt(isLoading:viewModel.isLoading ,reader:reader)
        }.onAppear{
            UITableView.appearance().backgroundColor = UIColor.clear
            UITableViewCell.appearance().backgroundColor = UIColor.clear
            viewModel.callId = callId
            viewModel.getParticipantsIfConnected()
            setupPreviewIfInPreviewMode()
        }
    }
    
}

extension CallParticipantsContentList{
    
    func setupPreviewIfInPreviewMode(){
        if isPreview{
            viewModel.setupPreview()
        }
    }
}

struct CallParticipantContentList_Previews: PreviewProvider {
    
    static var previews: some View {
        CallParticipantsContentList(callId: 0,isPreview: true)
    }
}
