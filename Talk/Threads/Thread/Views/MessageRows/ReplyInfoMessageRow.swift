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
        if hasReplyInfo {
            replyContent()
                .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
                .padding(EdgeInsets(top: 6, leading: viewModel.isMe ? 6 : 0, bottom: 6, trailing: viewModel.isMe ? 0 : 6))
                .frame(maxWidth: viewModel.replyContainerWidth, maxHeight: 52, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(viewModel.isMe ? Color.App.bgChatMeDark : Color.App.bgChatUserDark)
                )
                .padding(.top, viewModel.paddings.replyViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
        }
    }

    @ViewBuilder private func replyContent() -> some View {
        Button {
            moveToMessage()
        } label: {
            if message.replyInfo?.deleted == true {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(lineWidth: 1.5)
                        .fill(Color.App.accent)
                        .frame(maxWidth: 1.5)
                    Text("Messages.deletedMessageReply")
                        .font(.iransansBoldCaption2)
                        .foregroundColor(Color.App.textSecondary)
                    Spacer()
                }
                .contentShape(Rectangle())
            } else {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(lineWidth: 1.5)
                        .fill(Color.App.accent)
                        .frame(maxWidth: 1.5)
                    ReplyImageIcon(viewModel: viewModel)
                    ReplyFileIcon()
                    VStack(alignment: .leading, spacing: 2) {
                        if let name = message.replyInfo?.participant?.name {
                            Text("\(name)")
                                .font(.iransansBoldCaption2)
                                .foregroundStyle(Color.App.accent)
                        }

                        if let hinTextMessage = viewModel.localizedReplyFileName, !hinTextMessage.isEmpty {
                            Text(hinTextMessage)
                                .font(.iransansCaption3)
                                .clipShape(RoundedRectangle(cornerRadius:(8)))
                                .foregroundStyle(Color.App.textPrimary.opacity(0.7))
                                .multilineTextAlignment(viewModel.isEnglish || viewModel.isMe ? .leading : .trailing)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.borderless)
        .truncationMode(.tail)
        .contentShape(Rectangle())
        .environmentObject(viewModel)
    }

    private var hasReplyInfo: Bool {
        message.replyInfo != nil
    }

    private var isReplyPrivately: Bool {
        message.replyInfo?.replyPrivatelyInfo != nil
    }

    private var replayTimeId: (time: UInt, id: Int)? {
        guard
            !isReplyPrivately,
            let time = message.replyInfo?.repliedToMessageTime,
            let repliedToMessageId = message.replyInfo?.repliedToMessageId
        else { return nil }
        return(time, repliedToMessageId)
    }

    private func moveToMessage() {
        Task {
            threadVM?.scrollVM.disableExcessiveLoading()
            if !isReplyPrivately, let tuple = replayTimeId {
                threadVM?.historyVM.moveToTime(tuple.time, tuple.id)
            } else if let replyPrivatelyInfo = message.replyInfo?.replyPrivatelyInfo {
                AppState.shared.openThreadAndMoveToMessage(conversationId: replyPrivatelyInfo.threadId ?? -1,
                                                           messageId: message.replyInfo?.repliedToMessageId ?? -1,
                                                           messageTime: message.replyInfo?.repliedToMessageTime ?? 0
                )
            }
        }
    }
}

struct ReplyImageIcon: View {
    let viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.isReplyImage, let link = viewModel.replyLink {
            let config = ImageLoaderConfig(url: link, size: .SMALL, metaData: viewModel.message.replyInfo?.metadata, thumbnail: true)
            ImageLoaderView(imageLoader: .init(config: config), contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .clipped()
        }
    }
}

struct ReplyFileIcon: View {
    private var message: Message { viewModel.message }
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        if !viewModel.isReplyImage, viewModel.canShowIconFile {
            if let iconName = self.message.replyIconName {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(Color.App.accent)
                    .clipped()
            }
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
