//
//  MessageFooterView.swift
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

struct MessageFooterView: View {
    var message: Message { viewModel.message }
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    private var thread: Conversation? { threadVM?.thread }
    private var isSelfThread: Bool { thread?.type == .selfThread }
    private var isSelfThreadDelvived: Bool {
        if !isSelfThread { return true }
        return message.id != nil
    }

    var body: some View {
        HStack {
            Text(viewModel.timeString)
                .foregroundColor(Color.App.textPrimary.opacity(0.5))
                .font(.iransansCaption2)

            if message.edited == true {
                Text("Messages.Footer.edited")
                    .foregroundColor(Color.App.textSecondary)
                    .font(.iransansCaption2)
            }

            if viewModel.isMe, isSelfThreadDelvived {
                Image(uiImage: message.footerStatus.image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundColor(message.footerStatus.fgColor)
            }

            if message.id != nil, message.id == thread?.pinMessage?.id {
                Image(systemName: "pin.fill")
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundColor(Color.App.accent)
            }
        }
        .font(.subheadline)
        .padding(EdgeInsets(top: 4, leading: 6, bottom: 0, trailing: 6)) /// Top 4 for spacing in VStack in TextMessageType
    }
}
