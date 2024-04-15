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
    let thread: Conversation
    @EnvironmentObject var eventViewModel: ThreadEventViewModel

    var body: some View {
        VStack(spacing: 2) {
            if eventViewModel.isShowingEvent {
                ThreadEventView()
                    .transition(.push(from: .leading))
            } else {
                NormalLastMessageContainer(isSelected: isSelected, thread: thread)
            }
        }
        .animation(.easeInOut, value: eventViewModel.isShowingEvent)
    }
}

struct NormalLastMessageContainer: View {
    let isSelected: Bool
    let thread: Conversation
    // It must be here because we need to redraw the view after the thread inside ViewModel has changed.
    @EnvironmentObject var viewModel: ThreadsViewModel
    var lastMsgVO: Message? { thread.lastMessageVO }

    var body: some View {
        HStack(spacing: 0) {
            let isFileType = lastMsgVO?.isFileType == true
            let isMe = lastMsgVO?.isMe(currentUserId: AppState.shared.user?.id ?? -1) == true
            if let addOrRemoveParticipantString = lastMsgVO?.addOrRemoveParticipantString(meId: AppState.shared.user?.id) {
                Text(addOrRemoveParticipantString)
                    .font(.iransansBody)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
            } else if let participantName = lastMsgVO?.participant?.contactName ?? lastMsgVO?.participant?.name, thread.group == true {
                let meVerb = String(localized: .init("General.you"))
                let localized = String(localized: .init("Thread.Row.lastMessageSender"))
                let participantName = String(format: localized, participantName)
                let name = isMe ? "\(meVerb):" : participantName
                Text(Message.textDirectionMark + name)
                    .font(.iransansBody)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
            }

//            if lastMsgVO?.isFileType == true, let iconName = lastMsgVO?.iconName {
//                Image(systemName: iconName)
//                    .resizable()
//                    .frame(width: 16, height: 16)
//                    .foregroundStyle(Color.App.color1)
//            }

            if !isFileType, let message = lastMsgVO?.message?.replacingOccurrences(of: "\n", with: " ").prefix(50) {
                Text(String(message))
                    .font(.iransansBody)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
            } else if isFileType {
                let fileStringName = lastMsgVO?.fileStringName ?? "MessageType.file"
                let sentVerb = String(localized: .init(isMe ? "Genral.mineSendVerb" : "General.thirdSentVerb"))
                let formatted = String(format: sentVerb, fileStringName.localized())
                Text(Message.textDirectionMark + "\(formatted)")
                    .font(.iransansCaption2)
                    .lineLimit(thread.group == false ? 2 : 1)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
            }

            if thread.lastMessageVO == nil, let creator = thread.inviter?.name {
                let type = thread.type
                let key = type?.isChannelType == true ? "Thread.createdAChannel" : "Thread.createdAGroup"
                let localizedLabel = String(localized: .init(key))
                let text = String(format: localizedLabel, creator)
                Text(text)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
                    .font(.iransansCaption2)
            }
            Spacer()
        }

        if let message = lastMsgVO, message.type == .endCall || message.type == .startCall {
            ConversationCallMessageType(message: message)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }
}
