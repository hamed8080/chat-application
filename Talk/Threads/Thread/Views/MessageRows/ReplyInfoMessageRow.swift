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

    var replyMessageColor: Color {
        if message.replyInfo?.deleted != nil {
            return Color.App.red
        } else if viewModel.isMe {
            return Color.App.hint
        } else {
            return Color.App.red
        }
    }

    var body: some View {
        Button {
            if let time = message.replyInfo?.repliedToMessageTime, let repliedToMessageId = message.replyInfo?.repliedToMessageId {
                threadVM?.moveToTime(time, repliedToMessageId)
            }
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(viewModel.isMe ? Color.App.primary : Color.App.pink)
                    .frame(width: 3)
                    .frame(minHeight: 0, maxHeight: 52)
                VStack(spacing: 0) {
                    if let name = message.replyInfo?.participant?.name {
                        Text("\(name)")
                            .font(.iransansBoldCaption2)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(viewModel.isMe ? Color.App.primary : Color.App.text)
                    }

                    if message.replyInfo?.deleted == true {
                        Text("Messages.deletedMessageReply")
                            .font(.iransansBoldCaption2)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.App.red)
                    }

                    if let message = message.replyInfo?.message?.replacingOccurrences(of: "\n", with: " ") {
                        Text(message)
                            .font(.iransansCaption3)
                            .cornerRadius(8, corners: .allCorners)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(Color.App.gray3)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    if canShowIconFile {
                        HStack {
                            if let iconName = message.iconName {
                                Image(systemName: iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(Color.App.blue)
                            }

                            if let fileStringName = message.fileStringName {
                                Text(fileStringName)
                                    .font(.iransansCaption2)
                                    .foregroundStyle(Color.App.blue)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: viewModel.widthOfRow, minHeight: 52, maxHeight: 52)
        }
        .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
        .buttonStyle(.borderless)
        .frame(minWidth: 0, maxWidth: viewModel.widthOfRow, minHeight: 52, maxHeight: 52)
        .truncationMode(.tail)
        .contentShape(Rectangle())
        .lineLimit(1)
    }

    var canShowIconFile: Bool { message.replyInfo?.messageType != .text && message.replyInfo?.message.isEmptyOrNil == true && message.replyInfo?.deleted == false }
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
