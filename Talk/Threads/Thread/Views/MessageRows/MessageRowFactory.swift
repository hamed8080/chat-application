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
            if let type = message.type {
                switch type {
                case .endCall, .startCall:
                    CallMessageType()
                        .environmentObject(viewModel)
                case .participantJoin, .participantLeft:
                    ParticipantMessageType()
                        .environmentObject(viewModel)
                default:
                    if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                        TextMessageType(viewModel: viewModel)
                    } else if message is UnreadMessageProtocol {
                        UnreadMessagesBubble()
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
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        let selectedColor = colorScheme == .dark ? Color.App.accent.opacity(0.4) : Color.App.dividerPrimary.opacity(0.5)
        let color: Color = viewModel.isHighlited || viewModel.isSelected ? selectedColor : Color.clear
        color
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == true {
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
