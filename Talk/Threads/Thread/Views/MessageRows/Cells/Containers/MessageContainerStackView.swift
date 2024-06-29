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

public final class MessageContainerStackView: UIStackView {
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
        self.fotterView = .init(frame: frame, isMe: isMe)
        self.messageFileView = .init(frame: frame, isMe: isMe)
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
        layoutMargins = .init(all: 4)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 10
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        registerGestures()

        groupParticipantNameView.translatesAutoresizingMaskIntoConstraints = false
        replyInfoMessageRow.translatesAutoresizingMaskIntoConstraints = false
        forwardMessageRow.translatesAutoresizingMaskIntoConstraints = false
        messageFileView.translatesAutoresizingMaskIntoConstraints = false
        messageImageView.translatesAutoresizingMaskIntoConstraints = false
        messageVideoView.translatesAutoresizingMaskIntoConstraints = false
        messageAudioView.translatesAutoresizingMaskIntoConstraints = false
        locationRowView.translatesAutoresizingMaskIntoConstraints = false
        textMessageView.translatesAutoresizingMaskIntoConstraints = false
        textMessageView.backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        //        reactionView.translatesAutoresizingMaskIntoConstraints = false
        fotterView.translatesAutoresizingMaskIntoConstraints = false
//        unsentMessageView.translatesAutoresizingMaskIntoConstraints = false

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
        reattachOrDetach(viewModel: viewModel)
        isUserInteractionEnabled = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == false
        if viewModel.calMessage.isLastMessageOfTheUser && !viewModel.calMessage.isMe {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            tailImageView.setIsHidden(false)
        } else {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            tailImageView.setIsHidden(true)
        }
    }

    private func reattachOrDetach(viewModel: MessageRowViewModel) {
        if viewModel.calMessage.isFirstMessageOfTheUser {
            groupParticipantNameView.set(viewModel)
            addArrangedSubview(groupParticipantNameView)
        } else {
            groupParticipantNameView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isReply {
            replyInfoMessageRow.set(viewModel)
            addArrangedSubview(replyInfoMessageRow)
            replyInfoMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4).isActive = true
        } else {
            replyInfoMessageRow.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isForward {
            forwardMessageRow.set(viewModel)
            addArrangedSubview(forwardMessageRow)
            forwardMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4).isActive = true
        } else {
            forwardMessageRow.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isImage {
            messageImageView.set(viewModel)
            addArrangedSubview(messageImageView)
        } else {
            messageImageView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isMap {
            locationRowView.set(viewModel)
            addArrangedSubview(locationRowView)
        } else {
            locationRowView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isFile {
            messageFileView.set(viewModel)
            addArrangedSubview(messageFileView)
        } else {
            messageFileView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isAudio {
            messageAudioView.set(viewModel)
            addArrangedSubview(messageAudioView)
        } else {
            messageAudioView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.isVideo {
            messageVideoView.set(viewModel)
            addArrangedSubview(messageVideoView)
        } else {
            messageVideoView.removeFromSuperview()
        }

        if viewModel.calMessage.rowType.hasText {
            textMessageView.set(viewModel)
            addArrangedSubview(textMessageView)
        } else {
            textMessageView.removeFromSuperview()
        }

        //        if viewModel.calMessage.rowType.isUnSent {
        //            unsentMessageView.set(viewModel)
        //            addArrangedSubview(unsentMessageView)
        //        } else {
        //            unsentMessageView.removeFromSuperview()
        //        }
        //
        //        if viewModel.reactionsModel.rows.isEmpty == false {
        //            reactionView.set(viewModel)
        //            addArrangedSubview(reactionView)
        //        } else {
        //            reactionView.removeFromSuperview()
        //        }
        //        reactionView.set(viewModel)
        fotterView.set(viewModel)
    }

    private func registerGestures() {
        replyInfoMessageRow.isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = true
    }
}

public struct ActionModel {
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
        isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = false
        replyInfoMessageRow.isUserInteractionEnabled = false
        textMessageView.isUserInteractionEnabled = true
        tailImageView.isHidden = true
        textMessageView.isSelectable = true
        backgroundColor = isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        semanticContentAttribute = isMe ? .forceRightToLeft : .forceLeftToRight
    }
}