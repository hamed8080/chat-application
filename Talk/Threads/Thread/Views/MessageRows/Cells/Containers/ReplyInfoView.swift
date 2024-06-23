//
//  ReplyInfoView.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import Additive
import TalkModels

final class ReplyInfoView: UIStackView {
    private let vStack = UIStackView()
    private let imageTextHStack = UIStackView()
    private let replyStaticLebel = UILabel()
    private let participantLabel = UILabel()
    private let imageIconView = ImageLoaderUIView()
    private let deletedLabel = UILabel()
    private let replyLabel = UILabel()
    private let bar = UIView()
    private weak var viewModel: MessageRowViewModel?

//    // These two texts are used to localize and bundle which are costly to reconstruct every time.
    private static let deletedStaticText = "Messages.deletedMessageReply".localized()
    private static let repliedToStaticText = "Message.replyTo".localized()

    init(frame: CGRect, isMe: Bool) {
        super.init(frame: frame)
        configureView(isMe: isMe)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(isMe: Bool) {
        layoutMargins = .init(horizontal: 0.5, vertical: 3)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 8
        layer.masksToBounds = true
        backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        axis = .horizontal
        spacing = 4
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onReplyTapped))
        addGestureRecognizer(tap)

        vStack.semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 0
        vStack.layoutMargins = .init(all: 4)
        vStack.isLayoutMarginsRelativeArrangement = true

        replyStaticLebel.font = UIFont.uiiransansBoldCaption2
        replyStaticLebel.textColor = Color.App.accentUIColor
//        replyStaticLebel.text = ReplyInfoView.repliedToStaticText
        imageTextHStack.axis = .horizontal
        imageTextHStack.spacing = 4

        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        imageTextHStack.addArrangedSubview(imageIconView)

        replyLabel.font = UIFont.uiiransansCaption3
        replyLabel.numberOfLines = 1
        replyLabel.textColor = UIColor.gray
        replyLabel.lineBreakMode = .byTruncatingTail
        replyLabel.textAlignment = isMe ? .right : .left
        imageTextHStack.addArrangedSubview(replyLabel)

        deletedLabel.text = ReplyInfoView.deletedStaticText
        deletedLabel.font = UIFont.uiiransansBoldCaption2
        deletedLabel.textColor = Color.App.textSecondaryUIColor

        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 2
        hStack.addArrangedSubview(replyStaticLebel)

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.accentUIColor
        hStack.addArrangedSubview(participantLabel)

        vStack.addArrangedSubview(hStack)
        vStack.addArrangedSubview(deletedLabel)
        vStack.addArrangedSubview(imageTextHStack)

        addArrangedSubview(bar)
        addArrangedSubview(vStack)

        NSLayoutConstraint.activate([
            imageIconView.heightAnchor.constraint(equalToConstant: 24),
            imageIconView.widthAnchor.constraint(equalToConstant: 24),
            bar.widthAnchor.constraint(equalToConstant: 2.0),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        if !viewModel.calMessage.rowType.isReply {
            reset()
            return
        }
        setIsHidden(false)

        participantLabel.text = replyInfo?.participant?.name
        participantLabel.setIsHidden(replyInfo?.participant?.name == nil)

        replyLabel.text = replyInfo?.message
        replyLabel.setIsHidden(replyInfo?.message?.isEmpty == true)

        deletedLabel.setIsHidden(replyInfo?.deleted == nil || replyInfo?.deleted == false)

        let hasImage = viewModel.calMessage.isReplyImage

        if viewModel.calMessage.isReplyImage, let url = viewModel.calMessage.replyLink {
            imageIconView.setValues(config: .init(url: url, metaData: replyInfo?.metadata))
        }

        let deleted = replyInfo?.deleted == true
        imageTextHStack.setIsHidden(deleted)
        imageIconView.setIsHidden(!hasImage)
    }

    @objc func onReplyTapped(_ sender: UIGestureRecognizer) {
        Task {
            if isReplyPrivately {
                moveToReplyPrivately()
            } else {
                await moveToReply()
            }
        }
    }

    private func moveToReply() async {
        await historyVM?.moveToTime(replyTime, replyId, highlight: true)
    }

    private func moveToReplyPrivately() {
        AppState.shared.openThreadAndMoveToMessage(conversationId: sourceConversationId,
                                                   messageId: replyId,
                                                   messageTime: replyTime
        )
    }

    private var historyVM: ThreadHistoryViewModel? { viewModel?.threadVM?.historyVM }

    private var replyTime: UInt {
        replyInfo?.repliedToMessageTime ?? 0
    }

    private var replyId: Int {
        replyInfo?.repliedToMessageId ?? -1
    }

    private var isReplyPrivately: Bool {
        replyInfo?.replyPrivatelyInfo != nil
    }

    private var replyInfo: ReplyInfo? {
        viewModel?.message.replyInfo
    }

    private var sourceConversationId: Int {
        replyInfo?.replyPrivatelyInfo?.threadId ?? -1
    }

    private func reset() {
        setIsHidden(true)
    }
}
