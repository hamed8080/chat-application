//
//  MemberView.swift
//  ChatApplication
//
//  Created by hamed on 3/7/22.
//

import FanapPodChatSDK
import SwiftUI

struct MemberView: View {

    @EnvironmentObject
    var viewModel: ParticipantsViewModel

    var body: some View {
        List {
            ListLoadingView(isLoading: $viewModel.isLoading)
            ForEach(viewModel.participants, id: \.id) { participant in
                ParticipantRow(participant: participant, style: .init(avatarConfig: .init(size: 32, textSize: 16), textFont: .headline))
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
        }
    }
}

struct MemberView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ParticipantsViewModel(thread: MockData.thread)
        MemberView()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.setupPreview()
            }
    }
}
