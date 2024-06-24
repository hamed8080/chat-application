//
//  MessageContainer.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import TalkExtensions
import Photos

final class MessageContainer: UIStackView {
    public weak var cell: MessageBaseCell?
    weak var viewModel: MessageRowViewModel?
    private let messageFileView = MessageFileView()
    private let messageImageView = MessageImageView(frame: .zero)
    private let messageVideoView: MessageVideoView
    private let messageAudioView: MessageAudioView
    private let locationRowView = MessageLocationView(frame: .zero)
    private let groupParticipantNameView = GroupParticipantNameView()
    private let replyInfoMessageRow: ReplyInfoView
    private let forwardMessageRow: ForwardInfoView
    private let textMessageView = TextMessageView()
    private let reactionView: ReactionCountScrollView
    private let fotterView = FooterView()
    private let unsentMessageView = UnsentMessageView()
    private let tailImageView = UIImageView(image: UIImage(named: "tail"))

    init(frame: CGRect, isMe: Bool) {
        self.replyInfoMessageRow = .init(frame: frame, isMe: isMe)
        self.forwardMessageRow = .init(frame: frame, isMe: isMe)
        self.messageAudioView = .init(frame: frame, isMe: isMe)
        self.messageVideoView = .init(frame: frame, isMe: isMe)
        self.reactionView = .init(frame: frame, isMe: isMe)
        super.init(frame: frame)
        configureView(isMe: isMe)
        addMenus()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView(isMe: Bool) {
        backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        axis = .vertical
        spacing = 4
        alignment = .leading
        distribution = .fill
        layoutMargins = .init(all: 4)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 10
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        registerGestures()

        replyInfoMessageRow.translatesAutoresizingMaskIntoConstraints = false
        forwardMessageRow.translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(groupParticipantNameView)
        addArrangedSubview(replyInfoMessageRow)
        addArrangedSubview(forwardMessageRow)
        addArrangedSubview(messageFileView)
        addArrangedSubview(messageImageView)
        addArrangedSubview(messageVideoView)
        addArrangedSubview(messageAudioView)
        addArrangedSubview(locationRowView)
        addArrangedSubview(textMessageView)
        addArrangedSubview(reactionView)
        addArrangedSubview(fotterView)
//        addArrangedSubview(unsentMessageView)

        tailImageView.translatesAutoresizingMaskIntoConstraints = false
        tailImageView.contentMode = .scaleAspectFit
        tailImageView.tintColor = Color.App.bgChatUserUIColor!
        addSubview(tailImageView)

        NSLayoutConstraint.activate([
            tailImageView.widthAnchor.constraint(equalToConstant: 16),
            tailImageView.heightAnchor.constraint(equalToConstant: 32),
            tailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -12),
            tailImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            forwardMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            replyInfoMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        groupParticipantNameView.set(viewModel)
        replyInfoMessageRow.set(viewModel)
        forwardMessageRow.set(viewModel)
        messageImageView.set(viewModel)
        locationRowView.set(viewModel)
        messageFileView.set(viewModel)
        messageAudioView.set(viewModel)
        messageVideoView.set(viewModel)
        textMessageView.set(viewModel)
        unsentMessageView.set(viewModel)
        reactionView.set(viewModel)
        fotterView.set(viewModel)
        isUserInteractionEnabled = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == false

        if viewModel.calMessage.isLastMessageOfTheUser && !viewModel.calMessage.isMe {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            tailImageView.setIsHidden(false)
        } else {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            tailImageView.setIsHidden(true)
        }
    }

    private func registerGestures() {
        replyInfoMessageRow.isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = true
    }
}

struct ActionModel {
    let viewModel: MessageRowViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    var message: any HistoryMessageProtocol { viewModel.message }
}

// MARK: Upadate methods
extension MessageContainer {
    func edited() {
        UIView.animate(withDuration: 0.2) {
            self.textMessageView.setText()
            self.fotterView.edited()
        }
    }

    func pinChanged() {
        guard let viewModel = viewModel else { return }
        fotterView.pinChanged(isPin: viewModel.message.pinned == true)
    }

    func sent() {
        guard let viewModel = viewModel else { return }
        fotterView.sent(image: viewModel.message.uiFooterStatus.image)
    }

    func delivered() {
        guard let viewModel = viewModel else { return }
        fotterView.delivered(image: viewModel.message.uiFooterStatus.image)
    }

    func seen() {
        guard let viewModel = viewModel else { return }
        fotterView.seen(image: viewModel.message.uiFooterStatus.image)
    }

    func updateProgress(viewModel: MessageRowViewModel) {
        messageAudioView.updateProgress(viewModel: viewModel)
        messageFileView.updateProgress(viewModel: viewModel)
        messageImageView.updateProgress(viewModel: viewModel)
        messageVideoView.updateProgress(viewModel: viewModel)
    }

    func updateThumbnail(viewModel: MessageRowViewModel) {
        messageImageView.updateThumbnail(viewModel: viewModel)
    }

    public func downloadCompleted(viewModel: MessageRowViewModel) {
        messageAudioView.downloadCompleted(viewModel: viewModel)
        messageFileView.downloadCompleted(viewModel: viewModel)
        messageImageView.downloadCompleted(viewModel: viewModel)
        messageVideoView.downloadCompleted(viewModel: viewModel)
    }

    public func uploadCompleted(viewModel: MessageRowViewModel) {
        messageAudioView.uploadCompleted(viewModel: viewModel)
        messageFileView.uploadCompleted(viewModel: viewModel)
        messageImageView.uploadCompleted(viewModel: viewModel)
        messageVideoView.uploadCompleted(viewModel: viewModel)
    }

    public func reationUpdated() {
        guard let viewModel = viewModel else { return }
        reactionView.set(viewModel)
    }

    public func prepareForContextMenu(userInterfaceStyle: UIUserInterfaceStyle) {
        overrideUserInterfaceStyle = userInterfaceStyle
        let isMe = viewModel?.calMessage.isMe == true
        isUserInteractionEnabled = false
        tailImageView.isHidden = true
        backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
    }
}
