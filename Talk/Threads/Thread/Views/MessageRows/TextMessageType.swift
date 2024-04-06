//
//  TextMessageType.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import TalkExtensions

final class TextMessageContainer: UIStackView {
    public weak var cell: TextMessageTypeCell?
    private var viewModel: MessageRowViewModel!
    private let messageRowFileDownloader = MessageRowFileDownloaderView()
    private let messageRowImageDownloader = MessageRowImageDownloaderView(frame: .zero)
    private let messageRowVideoDownloader = MessageRowVideoDownloaderView()
    private let messageRowAudioDownloader = MessageRowAudioDownloaderView()
    private let locationRowView = LocationRowView(frame: .zero)
    private let groupParticipantNameView = GroupParticipantNameView()
    private let replyInfoMessageRow = ReplyInfoMessageRow()
    private let forwardMessageRow = ForwardMessageRow()
    private let uploadImage = UploadMessageImageView()
    private let uploadFile = UploadMessageFileView()
    private let messageTextView = MessageTextView()
    private let reactionView = ReactionCountView()
    private let fotterView = MessageFooterView()
    private let unsentMessageView = UnsentMessageView()
    private let tailImageView = UIImageView(image: UIImage(named: "tail"))

    private var imageViewWidthConstraint: NSLayoutConstraint!
    private var imageViewHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        addMenus()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView() {
        backgroundColor = Color.App.bgChatUserUIColor!
        axis = .vertical
        spacing = 8
        alignment = .leading
        distribution = .fill
        layoutMargins = .init(all: 8)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 10
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        registerGestures()

        replyInfoMessageRow.translatesAutoresizingMaskIntoConstraints = false
        messageRowImageDownloader.translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(groupParticipantNameView)
        addArrangedSubview(replyInfoMessageRow)
        addArrangedSubview(forwardMessageRow)
        addArrangedSubview(messageRowFileDownloader)
        addArrangedSubview(messageRowImageDownloader)
        addArrangedSubview(messageRowVideoDownloader)
        addArrangedSubview(messageRowAudioDownloader)
        addArrangedSubview(locationRowView)
//        addArrangedSubview(uploadImage)
//        addArrangedSubview(uploadFile)
        addArrangedSubview(messageTextView)
        addArrangedSubview(reactionView)
        addArrangedSubview(fotterView)
//        addArrangedSubview(unsentMessageView)

        tailImageView.translatesAutoresizingMaskIntoConstraints = false
        tailImageView.contentMode = .scaleAspectFit
        addSubview(tailImageView)

        imageViewWidthConstraint = messageRowImageDownloader.widthAnchor.constraint(greaterThanOrEqualToConstant: 128)
        imageViewHeightConstraint = messageRowImageDownloader.heightAnchor.constraint(greaterThanOrEqualToConstant: 128)

        NSLayoutConstraint.activate([
            imageViewWidthConstraint,
            imageViewHeightConstraint,
            tailImageView.widthAnchor.constraint(equalToConstant: 16),
            tailImageView.heightAnchor.constraint(equalToConstant: 32),
            tailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -12),
            tailImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            forwardMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            replyInfoMessageRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageRowImageDownloader.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            messageRowImageDownloader.widthAnchor.constraint(greaterThanOrEqualToConstant: 128),
            messageRowImageDownloader.heightAnchor.constraint(greaterThanOrEqualToConstant: 128),
        ])
    }

    private func setVerticalSpacings(viewModel: MessageRowViewModel) {
//        let message = viewModel.message
//        let isReply = viewModel.message.replyInfo != nil
//        let isForward = viewModel.message.forwardInfo != nil
//        let isFile = message.isUploadMessage && !message.isImage && message.isFileType
//        let isImage = viewModel.canShowImageView
//        let isVideo = !message.isUploadMessage && message.isVideo == true
//        let isAudio = !message.isUploadMessage && message.isAudio == true
//        let isLocation = viewModel.isMapType
//        let isUploadImage = message.isUploadMessage && message.isImage
//        let isUploadFile = !message.isUploadMessage && message.isFileType && !viewModel.isMapType && !message.isImage && !message.isAudio && !message.isVideo
//        let isTextEmpty = message.messageTitle.isEmpty
//        let isUnsent = viewModel.message.isUnsentMessage
//        let hasReaction = viewModel.reactionsVM.reactionCountList.count > 0
    }

    public func set(_ viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        setVerticalSpacings(viewModel: viewModel)
        messageTextView.set(viewModel)
        replyInfoMessageRow.set(viewModel)
        forwardMessageRow.set(viewModel)
        messageRowImageDownloader.set(viewModel)
        groupParticipantNameView.set(viewModel)
        locationRowView.set(viewModel)
        messageRowFileDownloader.set(viewModel)
        messageRowAudioDownloader.set(viewModel)
        messageRowVideoDownloader.set(viewModel)
        unsentMessageView.set(viewModel)
        reactionView.set(viewModel)
        uploadImage.set(viewModel)
        uploadFile.set(viewModel)
        fotterView.set(viewModel)
        isUserInteractionEnabled = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == false
        backgroundColor = viewModel.isMe ? Color.App.bgChatMeUIColor! : Color.App.bgChatUserUIColor!
        if viewModel.isLastMessageOfTheUser && !viewModel.isMe {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            tailImageView.isHidden = false
        } else {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            tailImageView.isHidden = true
        }

        if viewModel.rowType.isImage {
            imageViewWidthConstraint.constant = viewModel.imageWidth ?? 128
            imageViewHeightConstraint.constant = viewModel.imageHeight ?? 128
        } else {
            imageViewWidthConstraint.constant = 0
            imageViewHeightConstraint.constant = 0
        }
    }

    private func registerGestures() {
        replyInfoMessageRow.isUserInteractionEnabled = true
        forwardMessageRow.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc func onTap(_ sender: UITapGestureRecognizer? = nil) {
//        if viewModel.isInSelectMode == true {
//            viewModel.isSelected.toggle()
//            radio.set(viewModel)
//            backgroundColor = viewModel.isSelected ? Color.App.accentUIColor?.withAlphaComponent(0.2) : UIColor.clear
//        }
    }
}

extension TextMessageContainer: UIContextMenuInteractionDelegate {
    private func addMenus() {
        let menu = UIContextMenuInteraction(delegate: self)
        addInteraction(menu)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return UIMenu() }
            return menu(model: .init(viewModel: viewModel))
        }
        return config
    }
}

struct ActionModel {
    let viewModel: MessageRowViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    var message: Message { viewModel.message }
}

//MARK: Action menus
extension TextMessageContainer {

    public func menu(model: ActionModel) -> UIMenu {
        let message: Message = model.message
        let threadVM = model.threadVM
        let viewModel = model.viewModel

        var menus: [UIAction] = []
        let replyAction = UIAction(title: "Messages.ActionMenu.reply".localized(), image: UIImage(systemName: "arrowshape.turn.up.left")) { [weak self] _ in
            self?.onReplyAction(model)
        }
        menus.append(replyAction)

        if threadVM?.thread.group == true, !viewModel.isMe {
            let replyPrivatelyAction = UIAction(title: "Messages.ActionMenu.replyPrivately".localized(), image: UIImage(systemName: "arrowshape.turn.up.left")) { [weak self] _ in
                self?.onReplyPrivatelyAction(model)
            }
            menus.append(replyPrivatelyAction)
        }

        let forwardAction = UIAction(title: "Messages.ActionMenu.forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right")) { [weak self] _ in
            self?.onForwardAction(model)
        }
        menus.append(forwardAction)

        if viewModel.canEdit {
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

        let isDeletable = DeleteMessagesViewModelModel.isDeletable(isMe: viewModel.isMe, message: viewModel.message, thread: threadVM?.thread)
        if isDeletable {
            let deleteAction = UIAction(title: "General.delete".localized(), image: UIImage(systemName: "trash"), attributes: [.destructive]) { [weak self] _ in
                self?.onDeleteAction(model)
            }
            menus.append(deleteAction)
        }
        return UIMenu(children: menus)
    }

    private func onReplyAction(_ model: ActionModel) {
        model.threadVM?.replyMessage = model.message
        model.threadVM?.sendContainerViewModel.setFocusOnTextView(focus: true)
    }

    private func onReplyPrivatelyAction(_ model: ActionModel) {
        guard let participant = model.message.participant else { return }
        AppState.shared.appStateNavigationModel.replyPrivately = model.message
        AppState.shared.openThread(participant: participant)
    }

    private func onForwardAction(_ model: ActionModel) {
        model.threadVM?.forwardMessage = model.message
        cell?.select()
        model.threadVM?.delegate?.setSelection(true)
        model.threadVM?.selectedMessagesViewModel.setInSelectionMode(true)
    }

    private func onEditAction(_ model: ActionModel) {
        model.threadVM?.sendContainerViewModel.setEditMessage(message: model.message)
    }

    private func onSeenListAction(_ model: ActionModel) {
        let value = MessageParticipantsSeenNavigationValue(message: model.viewModel.message, threadVM: model.threadVM!)
        AppState.shared.objectsContainer.navVM.append(type: .messageParticipantsSeen(value), value: value)
    }

    private func onSaveAction(_ model: ActionModel) {
        if let url = model.viewModel.downloadFileVM?.fileURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, model.viewModel, nil, nil)
            let icon = Image(systemName: "externaldrive.badge.checkmark")
                .fontWeight(.semibold)
                .foregroundStyle(Color.App.white)
            AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.imageSaved", messageColor: Color.App.textPrimary)
        }
    }

    private func onCopyAction(_ model: ActionModel) {
        UIPasteboard.general.string = model.message.message
    }

    private func onDeleteCacheAction(_ model: ActionModel) {
        model.threadVM?.clearCacheFile(message: model.message)
        model.threadVM?.animateObjectWillChange()
    }

    private func onDeleteAction(_ model: ActionModel) {
        if let threadVM = model.threadVM {
            model.viewModel.isSelected = true
            let deleteVM = DeleteMessagesViewModelModel(threadVM: threadVM)
            let dialog = DeleteMessageDialog(viewModel: deleteVM)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
        }
    }

    private func onPinAction(_ model: ActionModel) {
        let isPinned = model.message.id == model.threadVM?.thread.pinMessage?.id && model.threadVM?.thread.pinMessage != nil
        if !isPinned, let threadVM = model.threadVM {
            let dialog = PinMessageDialog(message: model.viewModel.message)
                .environmentObject(threadVM)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
        } else {
            model.threadVM?.threadPinMessageViewModel.unpinMessage(model.message.id ?? -1)
        }
    }

    private func onSelectAction(_ model: ActionModel) {
        cell?.select()
        model.threadVM?.delegate?.setSelection(true)
        model.threadVM?.selectedMessagesViewModel.setInSelectionMode(true)
    }
}

final class TextMessageTypeCell: UITableViewCell {
    private var viewModel: MessageRowViewModel!
    private let hStack = UIStackView()
    private let avatar = AvatarView(frame: .zero)
    private let radio = SelectMessageRadio()
    private let messageContainer = TextMessageContainer()

    private var message: Message { viewModel.message }
    private var isEmptyMessage: Bool { message.message == nil || message.message?.isEmpty == true  }
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureView() {
        selectionStyle = .none // Prevent iOS selection background color view added we use direct background color on content view instead of selectedBackgroundView or backgroundView
        contentView.isUserInteractionEnabled = true
        hStack.translatesAutoresizingMaskIntoConstraints = false

        hStack.axis = .horizontal
        hStack.alignment = .bottom
        hStack.spacing = 8
        hStack.distribution = .fill

        radio.isHidden = true

        messageContainer.cell = self
        hStack.addArrangedSubview(radio)
        hStack.addArrangedSubview(avatar)
        hStack.addArrangedSubview(messageContainer)

        contentView.addSubview(hStack)

        setConstraints()
    }

    private func setConstraints() {
        leadingConstraint = hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8)
        trailingConstraint = hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        NSLayoutConstraint.activate([
            messageContainer.widthAnchor.constraint(lessThanOrEqualToConstant: ThreadViewModel.maxAllowedWidth),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        self.viewModel = viewModel
        leadingConstraint.isActive = !viewModel.isMe
        trailingConstraint.isActive = viewModel.isMe
        hStack.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        messageContainer.semanticContentAttribute = viewModel.isMe ? .forceRightToLeft : .forceLeftToRight
        avatar.set(viewModel)
        messageContainer.set(viewModel)
        radio.isHidden = viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == false
        radio.set(selected: viewModel.isSelected)
        setSelectedBackground()
    }

    func deselect() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            viewModel.isSelected = false
            radio.set(selected: false)
            setSelectedBackground()
            viewModel.threadVM?.delegate?.updateCount()
        }
    }

    func select() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            viewModel.isSelected = true
            radio.set(selected: true)
            setSelectedBackground()
            viewModel.threadVM?.delegate?.updateCount()
        }
    }

    func setInSelectionMode(_ isInSelectionMode: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            radio.isHidden = !isInSelectionMode
            messageContainer.isUserInteractionEnabled = !isInSelectionMode
            if !isInSelectionMode {
                deselect()
            }
        }
    }

    private func setSelectedBackground() {
        if viewModel.isSelected {
            contentView.backgroundColor = Color.App.bgChatSelectedUIColor?.withAlphaComponent(0.8)
        } else {
            contentView.backgroundColor = nil
        }
    }
}

struct TextMessageTypeCellWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = TextMessageTypeCell()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct TextMessageType_Previews: PreviewProvider {
//    struct Preview: View {
//        @StateObject var viewModel: MessageRowViewModel
//
//        init(viewModel: MessageRowViewModel) {
//            ThreadViewModel.maxAllowedWidth = 340
//            self._viewModel = StateObject(wrappedValue: viewModel)
//            Task {
//                await viewModel.performaCalculation()
//                await viewModel.asyncAnimateObjectWillChange()
//            }
//        }
//
//        var body: some View {
//            TextMessageTypeCellWapper(viewModel: viewModel)
//        }
//    }

    static var previews: some View {
        let viewModels = MockAppConfiguration.shared.viewModels
//        Preview(viewModel: viewModels.first(where: {$0.isMe})!)
//            .previewDisplayName("IsMe")
//        Preview(viewModel: viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("Reply")
//        Preview(viewModel: viewModels.first(where: {$0.message.isImage == true})!)
//            .previewDisplayName("ImageDownloader")
//        Preview(viewModel: viewModels.first(where: {$0.message.isFileType == true && !$0.message.isImage})!)
//            .previewDisplayName("FileDownloader")
//        let vm = viewModels.first(where: {$0.message.message != nil && !$0.message.isImage})!
//        _ = vm.threadVM = .init(thread: .init(group: false))
//       return Preview(viewModel: vm)
//            .previewDisplayName("NotGroup-NoAvatar")
//        let viewModelWithNoMwssage = viewModels.first(where: {$0.message.isFileType == true && !$0.message.isImage && $0.message.message == nil})!
//        Preview(viewModel: viewModelWithNoMwssage)
//            .previewDisplayName("FileWithNoMessage")

//        Preview(viewModel: viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("Location")
//        Preview(viewModel: viewModels.first(where: {$0.message.replyInfo != nil })!)
//            .previewDisplayName("MusicPlayer")
//        Preview(viewModel: viewModels.first(where: {$0.message.forwardInfo != nil })!)
//            .previewDisplayName("Forward")
//        Preview(viewModel: MockAppConfiguration.shared.radioSelectVM)
//            .previewDisplayName("RadioSelect")
//        Preview(viewModel: MockAppConfiguration.shared.avatarVM)
//            .previewDisplayName("AvatarVM")
//        Preview(viewModel: MockAppConfiguration.shared.joinLinkVM)
//            .previewDisplayName("JoinLink")
//        Preview(viewModel: MockAppConfiguration.shared.groupParticipantNameVM)
//            .previewDisplayName("GroupParticipantName")
    }
}
