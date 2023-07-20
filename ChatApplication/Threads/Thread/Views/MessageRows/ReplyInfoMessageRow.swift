//
//  ReplyInfoMessageRow.swift
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

struct ReplyInfoMessageRow: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        Button {
            if let time = message.replyInfo?.repliedToMessageTime, let repliedToMessageId = message.replyInfo?.repliedToMessageId {
                threadVM?.moveToTime(time, repliedToMessageId)
            }
        } label: {
            HStack {
                Image(systemName: "poweron")
                    .resizable()
                    .frame(width: 3)
                    .frame(minHeight: 0, maxHeight: .infinity)
                    .foregroundColor(message.replyInfo?.deleted == true ? .redSoft : .orange)
                VStack(spacing: 4) {
                    if let name = message.replyInfo?.participant?.name {
                        Text("\(name)")
                            .font(.iransansBoldCaption2)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: name.naturalTextAlignment == .leading ? .leading : .trailing)
                            .foregroundColor(.orange)
                            .padding([.leading, .trailing], 4)
                    }

                    if message.replyInfo?.deleted == true {
                        Text("Message deleted.")
                            .font(.iransansBoldCaption2)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.redSoft)
                            .padding([.leading, .trailing], 4)
                    }

                    if let message = message.replyInfo?.message?.replacingOccurrences(of: "\n", with: " ") {
                        Text(message)
                            .font(.iransansCaption3)
                            .padding([.leading, .trailing], 4)
                            .cornerRadius(8, corners: .allCorners)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: message.naturalTextAlignment == .leading ? .leading : .trailing)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                if message.replyInfo?.deleted == true {
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: viewModel.widthOfRow - 32, height: message.replyInfo?.deleted == true ? 32 : 48)
        .background(Color.replyBg)
        .cornerRadius(8)
        .padding([.top, .leading, .trailing], 12)
        .truncationMode(.tail)
        .lineLimit(1)
        .onAppear {
            viewModel.calculate()
        }
    }
}

struct ReplyInfo_Previews: PreviewProvider {
    static let participant = Participant(name: "john", username: "john_9090")
    static let replyInfo = ReplyInfo(repliedToMessageId: 0, message: "Hi how are you?", messageType: .text, repliedToMessageTime: 100, participant: participant)
    static let isMEParticipant = Participant(name: "Mason", username: "sam_rage")
    static let isMeReplyInfo = ReplyInfo(repliedToMessageId: 0, message: "Hi how are you?", messageType: .text, repliedToMessageTime: 100, participant: isMEParticipant)
    static let deletedReplay = ReplyInfo(deleted: true)
    static var previews: some View {
        let threadVM = ThreadViewModel(thread: Conversation())
        List {
            TextMessageType(viewModel: MessageRowViewModel(message: Message(message: "Hi Hamed, I'm graet.", ownerId: 10, replyInfo: replyInfo), viewModel: threadVM))
            TextMessageType(viewModel: MessageRowViewModel(message: Message(message: "Hi Hamed, I'm graet.", replyInfo: isMeReplyInfo), viewModel: threadVM))
            TextMessageType(viewModel: MessageRowViewModel(message: Message(message: "Hi Hamed, I'm graet.", replyInfo: deletedReplay), viewModel: threadVM))
        }
        .listStyle(.plain)
    }
}
