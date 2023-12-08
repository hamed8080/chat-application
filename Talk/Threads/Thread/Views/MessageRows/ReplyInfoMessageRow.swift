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
                threadVM?.disableExcessiveLoading()
                if message.replyInfo?.replyPrivatelyInfo == nil, let time = message.replyInfo?.repliedToMessageTime, let repliedToMessageId = message.replyInfo?.repliedToMessageId {
                    threadVM?.moveToTime(time, repliedToMessageId)
                } else if let replyPrivatelyInfo = message.replyInfo?.replyPrivatelyInfo {
                    AppState.shared.openThreadAndMoveToMessage(conversationId: replyPrivatelyInfo.threadId ?? -1,
                                                               messageId: message.replyInfo?.repliedToMessageId ?? -1,
                                                               messageTime: message.replyInfo?.repliedToMessageTime ?? 0
                    )
                }
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Message.replyTo")
                            .foregroundStyle(Color.App.primary)
                            .font(.iransansCaption3)
                        
                        if let name = message.replyInfo?.participant?.name {
                            Text("\(name)")
                                .font(.iransansBoldCaption2)
                                .foregroundStyle(Color.App.primary)
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
                                .fixedSize(horizontal: false, vertical: true)
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
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: viewModel.isMe ? 4 : 8))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(lineWidth: 1.5)
                            .fill(Color.App.primary)
                            .frame(maxWidth: 1.5)
                    }
                }
            }
            .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
            .frame(minWidth: 128, alignment: viewModel.isMe ? .topTrailing : .topLeading)
            .buttonStyle(.borderless)
            .truncationMode(.tail)
            .contentShape(Rectangle())
            .padding(EdgeInsets(top: 6, leading: viewModel.isMe ? 6 : 0, bottom: 6, trailing: viewModel.isMe ? 0 : 6))
            .background(Color.App.bgInput.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
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
