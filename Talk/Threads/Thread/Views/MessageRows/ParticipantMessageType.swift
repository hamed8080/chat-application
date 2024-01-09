//
//  ParticipantMessageType.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ParticipantMessageType: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if let attr = viewModel.addOrRemoveParticipantsAttr {
            HStack(alignment: .center, spacing: 0) {
                Text(attr)
                    .foregroundStyle(Color.App.white)
                    .multilineTextAlignment(.center)
                    .font(.iransansBody)
                    .padding(2)
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius:(25)))
            .frame(maxWidth: .infinity)
        }
    }
}
