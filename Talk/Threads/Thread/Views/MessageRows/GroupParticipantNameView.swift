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
                    .foregroundStyle(viewModel.participantColor ?? .clear)
                    .font(.iransansBoldBody)
            }
            .padding(padding)
        }
    }

    private var padding: EdgeInsets {
        let hasAlreadyPadding = viewModel.message.replyInfo != nil || viewModel.message.forwardInfo != nil
        let padding: CGFloat = hasAlreadyPadding ? 0 : 4
        return .init(top: padding, leading: padding, bottom: 0, trailing: padding)
    }
}

struct GroupParticipantNameView_Previews: PreviewProvider {
    static var previews: some View {
        GroupParticipantNameView()
    }
}
