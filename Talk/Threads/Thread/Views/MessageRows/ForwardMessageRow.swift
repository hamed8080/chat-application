//
//  ForwardMessageRow.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ForwardMessageRow: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    var message: Message? { viewModel.message }

    var body: some View {
        if let forwardInfo = message?.forwardInfo, let forwardThread = forwardInfo.conversation {
            Button {
                AppState.shared.objectsContainer.navVM.append(thread: forwardThread)
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Message.forwardedFrom")
                            .foregroundStyle(Color.App.accent)
                            .font(.iransansCaption3)
                        /// When we are the sender of forward we use forwardInfo.participant.name unless we use message.participant.name because it's nil
                        if let name = forwardInfo.participant?.name ?? message?.participant?.name {
                            Text(name)
                                .font(.iransansBoldBody)
                                .foregroundStyle(Color.App.accent)
                        }                       
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: viewModel.isMe ? 4 : 8))
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(lineWidth: 1.5)
                        .fill(Color.App.accent)
                        .frame(maxWidth: 1.5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
            .buttonStyle(.borderless)
            .truncationMode(.tail)
            .contentShape(Rectangle())
            .padding(EdgeInsets(top: 6, leading: viewModel.isMe ? 6 : 0, bottom: 6, trailing: viewModel.isMe ? 0 : 6))
            .background(viewModel.isMe ? Color.App.bgChatMeDark : Color.App.bgChatUserDark)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
