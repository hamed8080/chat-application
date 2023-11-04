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
    @EnvironmentObject var navVM: NavigationModel

    var body: some View {
        if let forwardInfo = message?.forwardInfo, let forwardThread = forwardInfo.conversation {
            Button {
                navVM.append(thread: forwardThread)
            } label: {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(viewModel.isMe ? Color.App.primary : Color.App.pink)
                        .frame(width: 3)
                        .frame(minHeight: 0, maxHeight: 36)
                    VStack(spacing: 0) {
                        if let name = forwardInfo.participant?.name {
                            Text("\(name)")
                                .font(.iransansBoldCaption2)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(viewModel.isMe ? Color.App.primary : Color.App.text)
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: viewModel.widthOfRow, minHeight: 36, maxHeight: 36)
            }
            .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
            .buttonStyle(.borderless)
            .frame(minWidth: 0, maxWidth: viewModel.widthOfRow, minHeight: 36, maxHeight: 36)
            .truncationMode(.tail)
            .contentShape(Rectangle())
            .lineLimit(1)
        }
    }
}
