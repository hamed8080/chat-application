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

final class ReplyInfoView: UIView {
    private let replyStaticLabel = UILabel()
    private let participantLabel = UILabel()
    private let imageIconView = ImageLoaderUIView(frame: .zero)
    private let deletedLabel = UILabel()
    private let replyLabel = UILabel()
    private let bar = UIView()
    private weak var viewModel: MessageRowViewModel?
    private var imageIconViewLeadingConstriant: NSLayoutConstraint!
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
        layer.cornerRadius = 8
        layer.masksToBounds = true
        backgroundColor = isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onReplyTapped))
        addGestureRecognizer(tap)

        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        imageIconView.accessibilityIdentifier = "imageIconViewReplyInfoView"
        imageIconView.backgroundColor = .blue
        imageIconView.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(imageIconView)

        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.font = UIFont.uiiransansCaption3
        replyLabel.numberOfLines = 1
        replyLabel.textColor = Color.App.textPrimaryUIColor?.withAlphaComponent(0.7)
        replyLabel.lineBreakMode = .byTruncatingTail
        replyLabel.textAlignment = isMe ? .right : .left
        replyLabel.accessibilityIdentifier = "replyLabelReplyInfoView"
        replyLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(replyLabel)

        deletedLabel.translatesAutoresizingMaskIntoConstraints = false
        deletedLabel.text = ReplyInfoView.deletedStaticText
        deletedLabel.font = UIFont.uiiransansBoldCaption2
        deletedLabel.textColor = Color.App.textSecondaryUIColor
        deletedLabel.setIsHidden(true)
        deletedLabel.accessibilityIdentifier = "deletedLabelReplyInfoView"
        deletedLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(deletedLabel)

        replyStaticLabel.translatesAutoresizingMaskIntoConstraints = false
        replyStaticLabel.font = UIFont.uiiransansBoldCaption2
        replyStaticLabel.textColor = Color.App.accentUIColor
        replyStaticLabel.text = ReplyInfoView.repliedToStaticText
        replyStaticLabel.accessibilityIdentifier = "replyStaticLabelReplyInfoView"
        replyStaticLabel.setContentHuggingPriority(.required, for: .horizontal)
        replyStaticLabel.setContentHuggingPriority(.required, for: .vertical)
        replyStaticLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(replyStaticLabel)

        participantLabel.translatesAutoresizingMaskIntoConstraints = false
        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.accentUIColor
        participantLabel.accessibilityIdentifier = "participantLabelReplyInfoView"
        participantLabel.textAlignment = isMe ? .right : .left
        participantLabel.backgroundColor = .yellow
        participantLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(participantLabel)

        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true
        bar.accessibilityIdentifier = "barReplyInfoView"
        addSubview(bar)

        let padding: CGFloat = 6
        imageIconViewLeadingConstriant = imageIconView.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: padding)
        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 1.5),
            bar.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.5),
            
            imageIconViewLeadingConstriant,
            imageIconView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            imageIconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            imageIconView.widthAnchor.constraint(equalToConstant: 36),

            replyStaticLabel.leadingAnchor.constraint(equalTo: imageIconView.trailingAnchor, constant: 8),
            replyStaticLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),

            participantLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            participantLabel.leadingAnchor.constraint(equalTo: replyStaticLabel.trailingAnchor, constant: 2),
            participantLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),

            deletedLabel.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            deletedLabel.leadingAnchor.constraint(equalTo: replyStaticLabel.leadingAnchor),
            deletedLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),

            replyLabel.topAnchor.constraint(equalTo: replyStaticLabel.bottomAnchor, constant: padding),
            replyLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            replyLabel.leadingAnchor.constraint(equalTo: replyStaticLabel.leadingAnchor),
            replyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding)
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
        setImageView(viewModel: viewModel)
    }

    private func setImageView(viewModel: MessageRowViewModel) {
        let hasImage = viewModel.calMessage.isReplyImage
        if viewModel.calMessage.isReplyImage, let url = viewModel.calMessage.replyLink {
            imageIconView.setValues(config: .init(url: url, metaData: replyInfo?.metadata))
        }
        imageIconView.setIsHidden(!hasImage)
        imageIconViewLeadingConstriant.constant = hasImage ? 0 : -36
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
