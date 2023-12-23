//
//  MessageRowFactory.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels

struct MessageRowFactory: View {
    private var message: Message { viewModel.message }
    let viewModel: MessageRowViewModel

    var body: some View {
        HStack(spacing: 0) {
            if message is UnreadMessageProtocol {
                UnreadMessagesBubble()
            } else {
                if let type = message.type {
                    if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                        TextMessageType(viewModel: viewModel)
                    } else if type == .participantJoin || type == .participantLeft {
                        ParticipantMessageType(message: message)
                    } else if type == .endCall || type == .startCall {
                        CallMessageType(message: message)
                    } else {
                        UnknownMessageType(message: message)
                    }
                }
            }
        }
        .background(TextMessageSelectedBackground().environmentObject(viewModel))
        .transition(.asymmetric(insertion: .push(from: viewModel.isMe ? .trailing : .leading), removal: .move(edge: viewModel.isMe ? .trailing : .leading)))
    }
}

struct TextMessageSelectedBackground: View {
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        let selectedColor = Color.App.primary.opacity(0.1)
        let color: Color = viewModel.isHighlited || viewModel.isSelected ? selectedColor : Color.clear
        color
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.threadVM?.isInEditMode == true {
                    viewModel.isSelected.toggle()
                    viewModel.threadVM?.selectedMessagesViewModel.animateObjectWillChange()
                    viewModel.animateObjectWillChange()
                }
            }
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        let threadVM = ThreadViewModel(thread: Conversation())
        List {
            ForEach(MockData.mockDataModel.messages) { message in
                MessageRowFactory(viewModel: MessageRowViewModel(message: message, viewModel: threadVM))
                    .listRowInsets(.zero)
            }
        }
        .listStyle(.plain)
    }
}
