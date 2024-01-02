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

//struct ReplyInfoMessageRow: View {
//    private var message: Message { viewModel.message }
//    private var threadVM: ThreadViewModel? { viewModel.threadVM }
//    @EnvironmentObject var viewModel: MessageRowViewModel
//
//    var body: some View {
//        if hasReplyInfo {
//            Button {
//                moveToMessage()
//            } label: {
//                HStack(spacing: 8) {
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Message.replyTo")
//                            .foregroundStyle(Color.App.primary)
//                            .font(.iransansCaption3)
//                        if let name = message.replyInfo?.participant?.name {
//                            Text("\(name)")
//                                .font(.iransansBoldCaption2)
//                                .foregroundStyle(Color.App.primary)
//                        }
//
//                        HStack {
//                            ReplyImageIcon(viewModel: viewModel)
//                            ReplyFileIcon()
//                            if message.replyInfo?.deleted == true {
//                                Text("Messages.deletedMessageReply")
//                                    .font(.iransansBoldCaption2)
//                                    .foregroundColor(Color.App.red)
//                            }
//
//                            if let message = message.replyInfo?.message, !message.isEmpty {
//                                Text(message)
//                                    .font(.iransansCaption3)
//                                    .clipShape(RoundedRectangle(cornerRadius:(8)))
//                                    .foregroundStyle(Color.App.gray3)
//                                    .multilineTextAlignment(viewModel.isEnglish || viewModel.isMe ? .leading : .trailing)
//                                    .lineLimit(2)
//                                    .truncationMode(.tail)
//                            }
//                        }
//                    }
//                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: viewModel.isMe ? 4 : 8))
//                    .overlay(alignment: .leading) {
//                        RoundedRectangle(cornerRadius: 3)
//                            .stroke(lineWidth: 1.5)
//                            .fill(Color.App.primary)
//                            .frame(maxWidth: 1.5)
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
//            .buttonStyle(.borderless)
//            .truncationMode(.tail)
//            .contentShape(Rectangle())
//            .padding(EdgeInsets(top: 6, leading: viewModel.isMe ? 6 : 0, bottom: 6, trailing: viewModel.isMe ? 0 : 6))
//            .background(Color.App.bgInput.opacity(0.5))
//            .clipShape(RoundedRectangle(cornerRadius: 6))
//            .environmentObject(viewModel)
//        }
//    }
//
//    private var hasReplyInfo: Bool {
//        message.replyInfo != nil
//    }
//
//    private var isReplyPrivately: Bool {
//        message.replyInfo?.replyPrivatelyInfo != nil
//    }
//
//    private var replayTimeId: (time: UInt, id: Int)? {
//        guard
//            !isReplyPrivately,
//            let time = message.replyInfo?.repliedToMessageTime,
//            let repliedToMessageId = message.replyInfo?.repliedToMessageId
//        else { return nil }
//        return(time, repliedToMessageId)
//    }
//
//    private func moveToMessage() {
//        threadVM?.scrollVM.disableExcessiveLoading()
//        if !isReplyPrivately, let tuple = replayTimeId {
//            threadVM?.historyVM.moveToTime(tuple.time, tuple.id)
//        } else if let replyPrivatelyInfo = message.replyInfo?.replyPrivatelyInfo {
//            AppState.shared.openThreadAndMoveToMessage(conversationId: replyPrivatelyInfo.threadId ?? -1,
//                                                       messageId: message.replyInfo?.repliedToMessageId ?? -1,
//                                                       messageTime: message.replyInfo?.repliedToMessageTime ?? 0
//            )
//        }
//    }
//}

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

final class ReplyInfoMessageRow: UIButton {
    private let stack = UIStackView()
    private let hStack = UIStackView()
    private let replyStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let imageIconView = UIImageView()
    private let deletedLabel = UILabel()
    private let replyLabel = UILabel()
    private let bar = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.uibgInput?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        configuration = .borderless()

        replyStaticLebel.font = UIFont.uiiransansCaption3
        replyStaticLebel.textColor = Color.App.uiprimary
        replyStaticLebel.text = "Message.replyTo".localized()

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.uiprimary
        participantLabel.text = "Message.replyTo".localized()

        replyLabel.font = UIFont.uiiransansCaption3
        replyLabel.numberOfLines = 2
        replyLabel.textColor = Color.App.uigray3
        replyLabel.lineBreakMode = .byTruncatingTail

        deletedLabel.text = "Messages.deletedMessageReply".localized()
        deletedLabel.font = UIFont.uiiransansBoldCaption2
        deletedLabel.textColor = Color.App.uired

        bar.backgroundColor = Color.App.uired
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.layoutMargins = UIEdgeInsets(all: 8)
        stack.isLayoutMarginsRelativeArrangement = true

        hStack.axis = .horizontal
        hStack.spacing = 4

        hStack.addArrangedSubview(bar)
        hStack.addArrangedSubview(imageIconView)
        hStack.addArrangedSubview(deletedLabel)
        hStack.addArrangedSubview(replyLabel)

        stack.addArrangedSubview(replyStaticLebel)
        stack.addArrangedSubview(participantLabel)
        stack.addArrangedSubview(hStack)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 1.5),
            bar.heightAnchor.constraint(equalToConstant: 48),
            imageIconView.widthAnchor.constraint(equalToConstant: 28),
            imageIconView.heightAnchor.constraint(equalToConstant: 28),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            stack.trailingAnchor.constraint(greaterThanOrEqualTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let replyInfo = viewModel.message.replyInfo
        participantLabel.text = viewModel.message.replyInfo?.participant?.name
        participantLabel.isHidden = viewModel.message.replyInfo?.participant?.name == nil
        replyLabel.text = replyInfo?.message
        replyLabel.isHidden = replyInfo?.message?.isEmpty == true
        replyLabel.textAlignment = viewModel.isEnglish || viewModel.isMe ? .right : .left
        deletedLabel.isHidden = replyInfo?.deleted == nil || replyInfo?.deleted == false
    }
}

struct ReplyInfoMessageRowWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = ReplyInfoMessageRow()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ReplyInfoMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let replyMessage = ReplyInfo(repliedToMessageId: 1, message: "TEST", messageType: .text, repliedToMessageTime: 155600555)
            let message = Message(id: 1, messageType: .participantJoin, time: 155600555, replyInfo: replyMessage)
            let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
            ReplyInfoMessageRowWapper(viewModel: viewModel)
        }
    }
}
