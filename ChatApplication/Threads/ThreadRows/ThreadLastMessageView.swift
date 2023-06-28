//
//  ThreadLastMessageView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct ThreadLastMessageView: View {
    // It must be here because we need to redraw the view after the thread inside ViewModel has changed.
    @EnvironmentObject var viewModel: ThreadsViewModel
    var thread: Conversation
    var lastMsgVO: Message? { thread.lastMessageVO }

    var body: some View {
        VStack(spacing: 2) {
            if let name = lastMsgVO?.participant?.name, thread.group == true {
                Text(name)
                    .font(.iransansBoldCaption)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .foregroundColor(.orange)
            }

            HStack {
                if lastMsgVO?.isFileType == true, let iconName = lastMsgVO?.iconName {
                    Image(systemName: iconName)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.blue)
                }
                if let message = thread.lastMessageVO?.message {
                    Text(message)
                        .font(.iransansBody)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundColor(.secondaryLabel)
                }

                if lastMsgVO?.isFileType == true, lastMsgVO?.message.isEmptyOrNil == true, let fileStringName = lastMsgVO?.fileStringName {
                    Text(fileStringName)
                        .font(.iransansCaption2)
                        .lineLimit(thread.group == false ? 2 : 1)
                        .foregroundColor(.secondaryLabel)
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
