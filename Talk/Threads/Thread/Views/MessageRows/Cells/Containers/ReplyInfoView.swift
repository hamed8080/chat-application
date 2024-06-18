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

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        backgroundColor = Color.App.bgChatMeDarkUIColor
        layer.cornerRadius = 8
        layer.masksToBounds = true

        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        imageIconView.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4

        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 0
        vStack.layoutMargins = .init(all: 4)
        vStack.isLayoutMarginsRelativeArrangement = true

        replyStaticLebel.font = UIFont.uiiransansBoldCaption2
        replyStaticLebel.textColor = Color.App.accentUIColor
//        replyStaticLebel.text = ReplyInfoView.repliedToStaticText

        participantLabel.font = UIFont.uiiransansBoldCaption2
        participantLabel.textColor = Color.App.accentUIColor

        replyLabel.font = UIFont.uiiransansCaption3
        replyLabel.numberOfLines = 1
        replyLabel.textColor = UIColor.gray
        replyLabel.lineBreakMode = .byTruncatingTail
        replyLabel.textAlignment = .left

        imageTextHStack.axis = .horizontal
        imageTextHStack.spacing = 4

        imageTextHStack.addArrangedSubview(imageIconView)
        imageTextHStack.addArrangedSubview(replyLabel)

        deletedLabel.text = ReplyInfoView.deletedStaticText
        deletedLabel.font = UIFont.uiiransansBoldCaption2
        deletedLabel.textColor = Color.App.redUIColor

        bar.backgroundColor = Color.App.accentUIColor
        bar.layer.cornerRadius = 2
        bar.layer.masksToBounds = true

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 2
        hStack.addArrangedSubview(replyStaticLebel)
        hStack.addArrangedSubview(participantLabel)

        vStack.addArrangedSubview(hStack)
        vStack.addArrangedSubview(deletedLabel)
        vStack.addArrangedSubview(imageTextHStack)

        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onReplyTapped))
        addGestureRecognizer(tap)

        addArrangedSubview(bar)
        addArrangedSubview(vStack)

        NSLayoutConstraint.activate([
            imageIconView.heightAnchor.constraint(equalToConstant: 24),
            imageIconView.widthAnchor.constraint(equalToConstant: 24),
            bar.widthAnchor.constraint(equalToConstant: 1.5),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        if !viewModel.calMessage.rowType.isReply {
            reset()
            return
        }
        setIsHidden(false)
        setBackgroundColor(viewModel.calMessage.isMe ? Color.App.bgChatMeDarkUIColor : Color.App.bgChatUserDarkUIColor)

        setSemanticContent(viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight)
        vStack.setSemanticContent(viewModel.calMessage.isMe ? .forceRightToLeft : .forceLeftToRight)

        participantLabel.text = replyInfo?.participant?.name
        participantLabel.setIsHidden(replyInfo?.participant?.name == nil)

        replyLabel.text = replyInfo?.message
        replyLabel.setIsHidden(replyInfo?.message?.isEmpty == true)
        replyLabel.textAlignment = viewModel.calMessage.isEnglish || viewModel.calMessage.isMe ? .right : .left

        deletedLabel.setIsHidden(replyInfo?.deleted == nil || replyInfo?.deleted == false)

        let hasImage = viewModel.calMessage.isReplyImage

        if viewModel.calMessage.isReplyImage, let url = viewModel.calMessage.replyLink {
            imageIconView.setValues(config: .init(url: url, metaData: replyInfo?.metadata))
        }
        imageIconView.setIsHidden( !hasImage)
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
