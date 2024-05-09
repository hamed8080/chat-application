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
        if let groupMessageParticipantName = viewModel.calculatedMessage.groupMessageParticipantName {
            HStack {
                Text(verbatim: groupMessageParticipantName)
                    .foregroundStyle(viewModel.calculatedMessage.participantColor ?? .clear)
                    .font(.iransansBoldBody)
            }
            .padding(viewModel.sizes.paddings.groupParticipantNamePadding)
        }
    }
}

struct GroupParticipantNameView_Previews: PreviewProvider {
    static var previews: some View {
        GroupParticipantNameView()
    }
}
