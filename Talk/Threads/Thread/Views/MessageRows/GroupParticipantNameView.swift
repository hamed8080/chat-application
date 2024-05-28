//
//  GroupParticipantNameView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import Chat
import TalkModels

struct GroupParticipantNameView: View {
    private var message: any HistoryMessageProtocol { viewModel.message }
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if let groupMessageParticipantName = viewModel.calMessage.groupMessageParticipantName {
            HStack {
                Text(verbatim: groupMessageParticipantName)
                    .foregroundStyle(viewModel.calMessage.participantColor ?? .clear)
                    .font(.iransansBoldBody)
            }
            .padding(viewModel.calMessage.sizes.paddings.groupParticipantNamePadding)
        }
    }
}

struct GroupParticipantNameView_Previews: PreviewProvider {
    static var previews: some View {
        GroupParticipantNameView()
    }
}
