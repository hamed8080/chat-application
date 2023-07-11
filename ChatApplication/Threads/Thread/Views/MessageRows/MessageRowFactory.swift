//
//  MessageRowFactory.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatAppModels
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MessageRowFactory: View {
    private var message: Message { viewModel.message }
    @State var viewModel: MessageRowViewModel
    @State private(set) var showParticipants: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            if message is UnreadMessageProtocol {
                UnreadMessagesBubble()
            } else {
                if let type = message.type {
                    if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                        TextMessageType()
                            .environmentObject(viewModel)
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
        .transition(.asymmetric(insertion: .push(from: viewModel.isMe ? .trailing : .leading), removal: .move(edge: viewModel.isMe ? .trailing : .leading)))
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        let threadVM = ThreadViewModel(thread: Conversation())
        List {
            ForEach(MockData.generateMessages(count: 5)) { message in
                MessageRowFactory(viewModel: MessageRowViewModel(message: message, viewModel: threadVM))
            }
        }
        .listStyle(.plain)
    }
}
