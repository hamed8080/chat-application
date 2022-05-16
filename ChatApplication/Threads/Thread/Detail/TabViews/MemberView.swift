//
//  MemberView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import SwiftUI
import FanapPodChatSDK

struct MemberView: View {

    var thread:Conversation
    
    @StateObject
    var viewModel:ParticipantsViewModel = ParticipantsViewModel()
    
    var body: some View {
        List{
            ForEach(viewModel.model.participants , id:\.id) { participant in
                ParticipantRow(participant: participant, style: .init(avatarConfig: .init(size: 32, textSize: 16), textFont: .headline))
                    .onAppear {
                        if viewModel.model.participants.last == participant{
                            viewModel.loadMore()
                        }
                    }
                    .contextMenu{
                        Button(role: .destructive) {
                            viewModel.removePartitipant(participant)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }.onAppear {
            if viewModel.model.totalCount <= 0{
                viewModel.threadId = thread.id ?? -1
                viewModel.getParticipantsIfConnected()
            }
        }
    }
}

struct MemberView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ParticipantsViewModel()
        MemberView(thread: MockData.thread, viewModel: viewModel)
            .onAppear {
                viewModel.setupPreview()
            }
        
    }
}
