//
//  MemberView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import FanapPodChatSDK
import SwiftUI

struct MemberView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        ListLoadingView(isLoading: $viewModel.isLoading)
        ForEach(viewModel.participants, id: \.id) { participant in
            ParticipantRow(participant: participant)
                .onAppear {
                    if viewModel.participants.last == participant {
                        viewModel.loadMore()
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.removePartitipant(participant)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            viewModel.getParticipants()
        }
    }
}

struct MemberView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ParticipantsViewModel(thread: MockData.thread)
        MemberView()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.appendParticipants(participants: MockData.generateParticipants())
            }
    }
}
