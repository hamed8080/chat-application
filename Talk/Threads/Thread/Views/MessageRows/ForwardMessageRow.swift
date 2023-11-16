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
                    VStack(alignment: .leading, spacing: 4) {
                        if let name = forwardInfo.participant?.name {
                            Text(name)
                                .font(.iransansCaption2)
                                .foregroundStyle(viewModel.isMe ? Color.App.primary : Color.App.text)
                        }
                        if !(message?.messageTitle.isEmpty ?? true) {
                            Text(viewModel.markdownTitle)
                                .font(.iransansCaption2)
                                .foregroundStyle(Color.App.gray2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding(.leading, 4)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(lineWidth: 1.5)
                        .fill(viewModel.isMe ? Color.App.primary : Color.App.pink)
                        .frame(maxWidth: 1.5)
                        .offset(x: -4)
                }
            }
            .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
            .buttonStyle(.borderless)
            .truncationMode(.tail)
            .contentShape(Rectangle())
            .padding(.horizontal, 6)
        }
    }
}
