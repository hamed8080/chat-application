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
import Additive

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
    private let hStackWithBar = UIStackView()
    private let vStack = UIStackView()
    private let hStack = UIStackView()
    private let replyStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let imageIconView = ImageLoaderUIView()
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
        hStackWithBar.translatesAutoresizingMaskIntoConstraints = false
        vStack.translatesAutoresizingMaskIntoConstraints = false

        layoutMargins = UIEdgeInsets(all: 8)
        backgroundColor = Color.App.bgPrimaryUIColor?.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        configuration = .borderless()

        replyStaticLebel.font = UIFont.uiiransansCaption3
        replyStaticLebel.textColor = Color.App.textPrimaryUIColor
        replyStaticLebel.text = "Message.replyTo".localized()

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.textPrimaryUIColor

        replyLabel.font = UIFont.uiiransansCaption3
        replyLabel.numberOfLines = 2
        replyLabel.textColor = UIColor.gray
        replyLabel.lineBreakMode = .byTruncatingTail

        deletedLabel.text = "Messages.deletedMessageReply".localized()
        deletedLabel.font = UIFont.uiiransansBoldCaption2
        deletedLabel.textColor = Color.App.redUIColor

        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        hStack.axis = .horizontal
        hStack.spacing = 4
        hStack.addArrangedSubview(imageIconView)
        hStack.addArrangedSubview(deletedLabel)
        hStack.addArrangedSubview(replyLabel)

        hStackWithBar.axis = .horizontal
        hStackWithBar.spacing = 2

        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.alignment = .leading
        vStack.layoutMargins = UIEdgeInsets(horizontal: 8, vertical: 4)
        vStack.isLayoutMarginsRelativeArrangement = true
        vStack.addArrangedSubview(replyStaticLebel)
        vStack.addArrangedSubview(participantLabel)
        vStack.addArrangedSubview(hStack)

        hStackWithBar.addArrangedSubview(bar)
        hStackWithBar.addArrangedSubview(vStack)

        addSubview(hStackWithBar)

        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 1.5),
            imageIconView.widthAnchor.constraint(equalToConstant: 28),
            imageIconView.heightAnchor.constraint(equalToConstant: 28),
            hStackWithBar.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            hStackWithBar.topAnchor.constraint(equalTo: topAnchor),
            hStackWithBar.bottomAnchor.constraint(equalTo: bottomAnchor),
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
        imageIconView.isHidden = !viewModel.isReplyImage
        if viewModel.isReplyImage, let url = viewModel.replyLink {
            imageIconView.setValues(config: .init(url: url, metaData: viewModel.message.replyInfo?.metadata))
        }
        registerGestures(viewModel)
    }

    private func registerGestures(_ viewModel: MessageRowViewModel) {
        isUserInteractionEnabled = true
        let tap = MessageTapGestureRecognizer(target: self, action: #selector(onReplyTapped(_:)))
        tap.viewModel = viewModel
        addGestureRecognizer(tap)
    }

    @objc func onReplyTapped(_ sender: MessageTapGestureRecognizer) {
        print("on reply tapped")
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
    struct Preview: View {
        @StateObject var viewModel: MessageRowViewModel

        init(viewModel: MessageRowViewModel) {
            ThreadViewModel.maxAllowedWidth = 340
            self._viewModel = StateObject(wrappedValue: viewModel)
            Task {
                await viewModel.performaCalculation()
                await viewModel.asyncAnimateObjectWillChange()
            }
        }

        var body: some View {
            ReplyInfoMessageRowWapper(viewModel: viewModel)
        }
    }

    static var previews: some View {
        Preview(viewModel: MockAppConfiguration.shared.viewModels.first(where: {$0.message.replyInfo != nil })!)
    }
}
