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
    private weak var viewModel: MessageRowViewModel?
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
        spacing = 0
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

extension MessageContainer: UIContextMenuInteractionDelegate {
    private func addMenus() {
        let menu = UIContextMenuInteraction(delegate: self)
        addInteraction(menu)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self, let viewModel = viewModel else { return UIMenu() }
            return menu(model: .init(viewModel: viewModel))
        }
        return config
    }
}

struct ActionModel {
    let viewModel: MessageRowViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    var message: any HistoryMessageProtocol { viewModel.message }
}

//MARK: Action menus
extension MessageContainer {

    public func menu(model: ActionModel) -> UIMenu {
        let message: any HistoryMessageProtocol = model.message
        let threadVM = model.threadVM
        let viewModel = model.viewModel

        var menus: [UIAction] = []
        let replyAction = UIAction(title: "Messages.ActionMenu.reply".localized(), image: UIImage(systemName: "arrowshape.turn.up.left")) { [weak self] _ in
            self?.onReplyAction(model)
        }
        menus.append(replyAction)

        if threadVM?.thread.group == true, !viewModel.calMessage.isMe {
            let replyPrivatelyAction = UIAction(title: "Messages.ActionMenu.replyPrivately".localized(), image: UIImage(systemName: "arrowshape.turn.up.left")) { [weak self] _ in
                self?.onReplyPrivatelyAction(model)
            }
            menus.append(replyPrivatelyAction)
        }

        let forwardAction = UIAction(title: "Messages.ActionMenu.forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right")) { [weak self] _ in
            self?.onForwardAction(model)
        }
        menus.append(forwardAction)

        if viewModel.calMessage.canEdit {
            let emptyText = message.message == nil || message.message == ""
            let title = emptyText ? "General.addText".localized() : "General.edit".localized()
            let editAction = UIAction(title: title, image: UIImage(systemName: "pencil.circle")) { [weak self] _ in
                self?.onEditAction(model)
            }
            menus.append(editAction)
        }

        if let threadVM = threadVM, viewModel.message.ownerId == AppState.shared.user?.id && threadVM.thread.group == true {
            let seenListAction = UIAction(title: "SeenParticipants.title".localized(), image: UIImage(systemName: "info.bubble")) { [weak self] _ in
                self?.onSeenListAction(model)
            }
            menus.append(seenListAction)
        }

        if viewModel.message.isImage {
            let saveImageAction = UIAction(title: "Messages.ActionMenu.saveImage".localized(), image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                self?.onSaveAction(model)
            }
            menus.append(saveImageAction)
        }


        if viewModel.calMessage.rowType.isVideo, viewModel.fileState.state == .completed {
            let saveVideoAction = UIAction(title: "Messages.ActionMenu.saveImage".localized(), image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                self?.onSaveVideoAction(model)
            }
            menus.append(saveVideoAction)
        }

        if !viewModel.message.isFileType || message.message?.isEmpty == false {
            let copyAction = UIAction(title: "Messages.ActionMenu.copy".localized(), image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                self?.onCopyAction(model)
            }
            menus.append(copyAction)
        }

        if EnvironmentValues.isTalkTest, message.isFileType == true {
            let deleteCacheAction = UIAction(title: "Messages.ActionMenu.deleteCache".localized(), image: UIImage(systemName: "cylinder.split.1x2")) { [weak self] _ in
                self?.onDeleteCacheAction(model)
            }
            menus.append(deleteCacheAction)
        }

        let isPinned = message.id == threadVM?.thread.pinMessage?.id && threadVM?.thread.pinMessage != nil
        if threadVM?.thread.admin == true {
            let title = isPinned ? "Messages.ActionMenu.unpinMessage".localized() : "Messages.ActionMenu.pinMessage".localized()
            let pinAction = UIAction(title: title, image: UIImage(systemName: "pin")) { [weak self] _ in
                self?.onPinAction(model)
            }
            menus.append(pinAction)
        }

        let selectAction = UIAction(title: "General.select".localized(), image: UIImage(systemName: "checkmark.circle")) { [weak self] _ in
            self?.onSelectAction(model)
        }
        menus.append(selectAction)

        if let message = message as? Message {
            let isDeletable = DeleteMessagesViewModelModel.isDeletable(isMe: viewModel.calMessage.isMe, message: message, thread: threadVM?.thread)
            if isDeletable {
                let deleteAction = UIAction(title: "General.delete".localized(), image: UIImage(systemName: "trash"), attributes: [.destructive]) { [weak self] _ in
                    self?.onDeleteAction(model)
                }
                menus.append(deleteAction)
            }
        }
        return UIMenu(children: menus)
    }

    private func onReplyAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        model.threadVM?.replyMessage = message
        model.threadVM?.sendContainerViewModel.setFocusOnTextView(focus: true)
        model.threadVM?.delegate?.openReplyMode(message)
    }

    private func onReplyPrivatelyAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        guard let participant = model.message.participant else { return }
        AppState.shared.appStateNavigationModel.replyPrivately = message
        AppState.shared.openThread(participant: participant)
    }

    private func onForwardAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        model.threadVM?.forwardMessage = message
        cell?.select()
        model.threadVM?.delegate?.setSelection(true)
        model.threadVM?.selectedMessagesViewModel.setInSelectionMode(true)
    }

    private func onEditAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        model.threadVM?.sendContainerViewModel.setEditMessage(message: message)
        model.threadVM?.delegate?.openEditMode(message)
    }

    private func onSeenListAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        let value = MessageParticipantsSeenNavigationValue(message: message, threadVM: model.threadVM!)
        AppState.shared.objectsContainer.navVM.append(value: value)
    }

    private func onSaveAction(_ model: ActionModel) {
        if let url = model.viewModel.message.fileURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, model.viewModel, nil, nil)
            let icon = Image(systemName: "externaldrive.badge.checkmark")
                .fontWeight(.semibold)
                .foregroundStyle(Color.App.white)
            AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.imageSaved", messageColor: Color.App.textPrimary)
        }
    }

    private func onSaveVideoAction(_ model: ActionModel) {
        Task {
            guard let url = await model.viewModel.message.makeTempURL() else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { saved, error in
                if saved {
                    Task {
                        try? FileManager.default.removeItem(at: url)
                        await MainActor.run {
                            let icon = Image(systemName: "externaldrive.badge.checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.App.white)
                            AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.videoSaved", messageColor: Color.App.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private func onCopyAction(_ model: ActionModel) {
        UIPasteboard.general.string = model.message.message
    }

    private func onDeleteCacheAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        model.threadVM?.clearCacheFile(message: message)
        if let uniqueId = message.uniqueId, let indexPath = model.threadVM?.historyVM.sections.indicesByMessageUniqueId(uniqueId) {
//            model.threadVM?.delegate?.reconfig(at: indexPath)
        }
    }

    private func onDeleteAction(_ model: ActionModel) {
        Task {
            if let threadVM = model.threadVM {
                model.viewModel.calMessage.state.isSelected = true
                let deleteVM = DeleteMessagesViewModelModel()
                await deleteVM.setup(viewModel: threadVM)
                let dialog = DeleteMessageDialog(viewModel: deleteVM)
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
            }
        }
    }

    private func onPinAction(_ model: ActionModel) {
        guard let message = model.message as? Message else { return }
        let isPinned = model.message.id == model.threadVM?.thread.pinMessage?.id && model.threadVM?.thread.pinMessage != nil
        if !isPinned, let threadVM = model.threadVM {
            let dialog = PinMessageDialog(message: message, threadVM: threadVM)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
        } else {
            model.threadVM?.threadPinMessageViewModel.unpinMessage(model.message.id ?? -1)
        }
    }

    private func onSelectAction(_ model: ActionModel) {
        model.threadVM?.delegate?.setSelection(true)
        cell?.select()
    }
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
}
