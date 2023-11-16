//
//  GroupParticipantNameView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import ChatModels

struct GroupParticipantNameView: View {
    private var message: Message { viewModel.message }
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if !viewModel.isMe {
            HStack {
                Text(verbatim: message.participant?.name ?? "")
                    .foregroundStyle(Color.App.purple)
                    .font(.iransansBody)
            }
            .padding(.horizontal, 6)
        }
    }
}

struct GroupParticipantNameView_Previews: PreviewProvider {
    static var previews: some View {
        GroupParticipantNameView()
    }
}
