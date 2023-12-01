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
import TalkModels

struct ThreadLastMessageView: View {
    let isSelected: Bool
    // It must be here because we need to redraw the view after the thread inside ViewModel has changed.
    @EnvironmentObject var viewModel: ThreadsViewModel
    var thread: Conversation
    var lastMsgVO: Message? { thread.lastMessageVO }
    var isLeftOrJoinMessage: Bool { lastMsgVO?.type == .participantLeft || lastMsgVO?.type == .participantJoin }
    private static let textDirectionMark = Language.isRTL ? "\u{200f}" : "\u{200e}"
    var key: String? {
        if !isLeftOrJoinMessage, thread.group == true {
            return "Thread.Row.lastMessageSender"
        } else if lastMsgVO?.type == .participantLeft {
            return "Message.Participant.left"
        } else if lastMsgVO?.type == .participantJoin {
            return "Message.Participant.joined"
        } else {
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                if let participantName = lastMsgVO?.participant?.name, let key = key {
                    let localized = String(localized: .init(key))
                    Text(ThreadLastMessageView.textDirectionMark + String(format: localized, participantName) )
                        .font(.iransansBoldBody)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.App.white : Color.App.primary)
                }

                if lastMsgVO?.isFileType == true, let iconName = lastMsgVO?.iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.App.blue)
                }

                if let message = thread.lastMessageVO?.message {
                    Text(message)
                        .font(.iransansBody)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.App.white : Color.App.hint)
                }

                if lastMsgVO?.isFileType == true, lastMsgVO?.message.isEmptyOrNil == true, let fileStringName = lastMsgVO?.fileStringName {
                    Text(fileStringName)
                        .font(.iransansCaption2)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundStyle(isSelected ? Color.App.white : Color.App.hint)
                }

                if thread.lastMessageVO == nil, let creator = thread.inviter?.name {
                    let localizedLabel = String(localized: .init("Thread.createdAConversation"))
                    let text = String(format: localizedLabel, creator)
                    Text(text)
                        .foregroundStyle(isSelected ? Color.App.white : Color.App.primary)
                        .font(.iransansBoldCaption2)
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
