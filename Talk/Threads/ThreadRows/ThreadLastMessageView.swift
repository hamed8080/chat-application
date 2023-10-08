//
//  ThreadLastMessageView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadLastMessageView: View {
    // It must be here because we need to redraw the view after the thread inside ViewModel has changed.
    @EnvironmentObject var viewModel: ThreadsViewModel
    var thread: Conversation
    var lastMsgVO: Message? { thread.lastMessageVO }

    var body: some View {
        VStack(spacing: 2) {
            HStack {

                if let participantName = lastMsgVO?.participant?.name,  thread.group == true {
                    Text(String(format: String(localized: .init("Thread.Row.lastMessageSender")), participantName))
                        .font(.iransansBoldBody)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundStyle(Color.main)
                }

                if lastMsgVO?.isFileType == true, let iconName = lastMsgVO?.iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.blue)
                }

                if let message = thread.lastMessageVO?.message {
                    Text(message)
                        .font(.iransansBody)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundStyle(Color.secondaryLabel)
                }

                if lastMsgVO?.isFileType == true, lastMsgVO?.message.isEmptyOrNil == true, let fileStringName = lastMsgVO?.fileStringName {
                    Text(fileStringName)
                        .font(.iransansCaption2)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundStyle(Color.secondaryLabel)
                }
                Spacer()
            }
            if let message = lastMsgVO, message.type == .endCall || message.type == .startCall {
                ConversationCallMessageType(message: message)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .truncationMode(Text.TruncationMode.tail)
        .clipped()
    }
}
