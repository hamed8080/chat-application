//
//  ReplyInfoMessageRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ReplyInfoMessageRow: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if message.replyInfo != nil {
            Button {
                if let time = message.replyInfo?.repliedToMessageTime, let repliedToMessageId = message.replyInfo?.repliedToMessageId {
                    threadVM?.moveToTime(time, repliedToMessageId)
                }
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let name = message.replyInfo?.participant?.name {
                            Text("\(name)")
                                .font(.iransansBoldCaption2)
                                .foregroundStyle(viewModel.isMe ? Color.App.primary : Color.App.text)
                        }

                        if message.replyInfo?.deleted == true {
                            Text("Messages.deletedMessageReply")
                                .font(.iransansBoldCaption2)
                                .foregroundColor(Color.App.red)
                        }

                        if let message = message.replyInfo?.message, !message.isEmpty {
                            Text(message)
                                .font(.iransansCaption3)
                                .clipShape(RoundedRectangle(cornerRadius:(8)))
                                .foregroundStyle(Color.App.gray3)
                                .multilineTextAlignment(viewModel.isEnglish || viewModel.isMe ? .leading : .trailing)
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                        if viewModel.canShowIconFile {
                            HStack {
                                if let iconName = self.message.iconName {
                                    Image(systemName: iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(Color.App.blue)
                                        .clipped()
                                }

                                if let fileStringName = self.message.fileStringName {
                                    Text(fileStringName)
                                        .font(.iransansCaption2)
                                        .foregroundStyle(Color.App.blue)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.leading, 4)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(lineWidth: 1.5)
                            .fill(viewModel.isMe ? Color.App.primary : Color.App.pink)
                            .frame(maxWidth: 1.5)
                            .offset(x: -4)
                    }
                }
            }
            .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
            .buttonStyle(.borderless)
            .truncationMode(.tail)
            .contentShape(Rectangle())
            .frame(height: 60)
                .padding(.horizontal, 6)
                .environmentObject(viewModel)
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
