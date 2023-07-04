//
//  MessageRowFactory.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct MessageRowFactory: View {
    var message: Message
    @State var calculation: MessageRowCalculationViewModel = .init()
    @EnvironmentObject var viewModel: ThreadViewModel
    @State private(set) var showParticipants: Bool = false
    private var isMe: Bool { message.isMe(currentUserId: AppState.shared.user?.id) }

    var body: some View {
        HStack(spacing: 0) {
            if let type = message.type {
                if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                    TextMessageType(message: message)
                        .environmentObject(calculation)
                } else if type == .participantJoin || type == .participantLeft {
                    ParticipantMessageType(message: message)
                } else if type == .endCall || type == .startCall {
                    CallMessageType(message: message)
                } else {
                    VStack {
                        Text("something is wrong")
                        Rectangle()
                            .fill(Color.green)
                    }
                }
            }
        }
        .transition(.asymmetric(insertion: .push(from: isMe ? .trailing : .leading), removal: .move(edge: isMe ? .trailing : .leading)))
    }
}

struct MessageRow_Previews: PreviewProvider {
    static var previews: some View {
        let threadVM = ThreadViewModel()
        List {
            ForEach(MockData.generateMessages(count: 5)) { message in
                MessageRowFactory(message: message, calculation: .init())
                    .environmentObject(threadVM)
            }
        }
        .environmentObject(MessageRowCalculationViewModel())
        .onAppear {
            threadVM.setup(thread: MockData.thread)
        }
        .listStyle(.plain)
    }
}

struct ReplyInfo_Previews: PreviewProvider {
    static let participant = Participant(name: "john", username: "john_9090")
    static let replyInfo = ReplyInfo(repliedToMessageId: 0, message: "Hi how are you?", messageType: .text, repliedToMessageTime: 100, participant: participant)
    static let isMEParticipant = Participant(name: "Sam", username: "sam_rage")
    static let isMeReplyInfo = ReplyInfo(repliedToMessageId: 0, message: "Hi how are you?", messageType: .text, repliedToMessageTime: 100, participant: isMEParticipant)
    static var previews: some View {
        let threadVM = ThreadViewModel()
        List {
            TextMessageType(message: Message(message: "Hi Hamed, I'm graet.", ownerId: 10, replyInfo: replyInfo))
            TextMessageType(message: Message(message: "Hi Hamed, I'm graet.", replyInfo: isMeReplyInfo))
        }
        .environmentObject(MessageRowCalculationViewModel())
        .environmentObject(threadVM)
        .onAppear {
            threadVM.setup(thread: MockData.thread)
        }
        .listStyle(.plain)
    }
}
