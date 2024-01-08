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
    var canShowName: Bool {
        !viewModel.isMe && viewModel.threadVM?.thread.group == true && viewModel.threadVM?.thread.type?.isChannelType == false
        && viewModel.isFirstMessageOfTheUser
    }

    var body: some View {
        if canShowName {
            HStack {
                Text(verbatim: message.participant?.name ?? "")
                    .foregroundStyle(Color.App.accent)
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
