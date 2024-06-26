//
//  MessageContainerStackView.swift
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

final class MessageContainerStackView: UIStackView {
    public weak var cell: MessageBaseCell?
    weak var viewModel: MessageRowViewModel?
    private let messageFileView: MessageFileView
    private let messageImageView: MessageImageView
    private let messageVideoView: MessageVideoView
    private let messageAudioView: MessageAudioView
    private let locationRowView: MessageLocationView
    private let groupParticipantNameView: GroupParticipantNameView
    private let replyInfoMessageRow: ReplyInfoView
    private let forwardMessageRow: ForwardInfoView
    private let textMessageView = TextMessageView()
    private static let tailImage = UIImage(named: "tail")
    private var tailImageView = UIImageView()
//    private let reactionView: ReactionCountScrollView
    private let fotterView: FooterView
//    private let unsentMessageView = UnsentMessageView()

    init(frame: CGRect, isMe: Bool) {
        self.groupParticipantNameView = .init(frame: frame)
        self.replyInfoMessageRow = .init(frame: frame, isMe: isMe)
        self.forwardMessageRow = .init(frame: frame, isMe: isMe)
        self.fotterView = .init(frame: frame)
        self.messageFileView = .init(frame: frame)
        self.messageAudioView = .init(frame: frame, isMe: isMe)
        self.locationRowView = .init(frame: frame)
        self.messageImageView = .init(frame: frame)
        self.messageVideoView = .init(frame: frame, isMe: isMe)
//        self.reactionView = .init(frame: frame, isMe: isMe)
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
        alignment = .top
        distribution = .fill
//        layoutMargins = .init(all: 4)
//        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 10
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        registerGestures()

        groupParticipantNameView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(groupParticipantNameView)

        replyInfoMessageRow.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(replyInfoMessageRow)
//        replyInfoMessageRow.heightAnchor.constraint(equalToConstant: 48).isActive = true
        replyInfoMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4).isActive = true

        forwardMessageRow.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(forwardMessageRow)
//        forwardMessageRow.heightAnchor.constraint(equalToConstant: 48).isActive = true
        forwardMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4).isActive = true

        messageFileView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(messageFileView)

        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(messageImageView)

        messageVideoView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(messageVideoView)

        messageAudioView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(messageAudioView)
//        messageAudioView.heightAnchor.constraint(equalToConstant: 77).isActive = true

        locationRowView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(locationRowView)

        textMessageView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(textMessageView)

        //        reactionView.translatesAutoresizingMaskIntoConstraints = false
        //        addArrangedSubview(reactionView)

        fotterView.translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(fotterView)

//        unsentMessageView.translatesAutoresizingMaskIntoConstraints = false
//        addArrangedSubview(unsentMessageView)

        if !isMe {
            tailImageView = UIImageView(image: MessageContainerStackView.tailImage)
            tailImageView.translatesAutoresizingMaskIntoConstraints = false
            tailImageView.contentMode = .scaleAspectFit
            tailImageView.tintColor = Color.App.bgChatUserUIColor!
            addSubview(tailImageView)
            tailImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
            tailImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
            tailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -12).isActive = true
            tailImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        }
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
//        unsentMessageView.set(viewModel)
//        reactionView.set(viewModel)
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
extension MessageContainerStackView {
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
//        reactionView.set(viewModel)
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
