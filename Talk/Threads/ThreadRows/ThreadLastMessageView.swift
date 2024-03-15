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
        HStack {
            if let addOrRemoveParticipantString = lastMsgVO?.addOrRemoveParticipantString(meId: AppState.shared.user?.id) {
                Text(addOrRemoveParticipantString)
                    .font(.iransansBody)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
            } else if let participantName = lastMsgVO?.participant?.name, thread.group == true {
                let localized = String(localized: .init("Thread.Row.lastMessageSender"))
                Text(Message.textDirectionMark + String(format: localized, participantName) )
                    .font(.iransansBody)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.accent)
            }

            if lastMsgVO?.isFileType == true, let iconName = lastMsgVO?.iconName {
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.App.color1)
            }

            if let message = thread.lastMessageVO?.message?.replacingOccurrences(of: "\n", with: " ").prefix(50) {
                Text(String(message))
                    .font(.iransansBody)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
            }

            if lastMsgVO?.isFileType == true, lastMsgVO?.message.isEmptyOrNil == true, let fileStringName = lastMsgVO?.fileStringName {
                Text(fileStringName.localized())
                    .font(.iransansCaption2)
                    .lineLimit(thread.group == false ? 2 : 1)
                    .foregroundStyle(isSelected ? Color.App.textPrimary : Color.App.textSecondary)
            }

            if thread.lastMessageVO == nil, let creator = thread.inviter?.name {
                let localizedLabel = String(localized: .init("Thread.createdAConversation"))
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
