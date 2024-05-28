//
//  ForwardMessageRow.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct ForwardMessageRow: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    var message: (any HistoryMessageProtocol)? { viewModel.message }

    var body: some View {
        Button {
                /// Disabled until they fix the server side.
//                AppState.shared.objectsContainer.navVM.append(thread: forwardThread)
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        statcForwardText
                        /// When we are the sender of forward we use forwardInfo.participant.name unless we use message.participant.name because it's nil
                        participantName
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: viewModel.calMessage.isMe ? 4 : 8))
                .overlay(alignment: .leading) {
                    orangeLeadingBar
                }
            }
            .frame(maxWidth: viewModel.calMessage.sizes.forwardContainerWidth, alignment: .leading)
            .buttonStyle(.borderless)
            .truncationMode(.tail)
            .contentShape(Rectangle())
            .padding(EdgeInsets(top: 6, leading: viewModel.calMessage.isMe ? 6 : 0, bottom: 6, trailing: viewModel.calMessage.isMe ? 0 : 6))
            .background(viewModel.calMessage.isMe ? Color.App.bgChatMeDark : Color.App.bgChatUserDark)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.top,viewModel.calMessage.sizes.paddings.forwardViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
    }

    private var statcForwardText: some View {
        Text("Message.forwardedFrom")
            .foregroundStyle(Color.App.accent)
            .font(.iransansCaption3)
    }

    @ViewBuilder
    private var participantName: some View {
        let name = message?.forwardInfo?.participant?.name ?? message?.participant?.name ?? ""
        Text(name)
            .font(.iransansBoldBody)
            .foregroundStyle(Color.App.accent)
    }

    private var orangeLeadingBar: some View {
        RoundedRectangle(cornerRadius: 3)
            .stroke(lineWidth: 1.5)
            .fill(Color.App.accent)
            .frame(maxWidth: 1.5)
    }
}
