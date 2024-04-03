//
//  MessageActionMenu.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import ChatModels
import Foundation
import SwiftUI
import TalkViewModels
import ActionableContextMenu
import TalkUI
import TalkModels

struct ActionModel {
    let viewModel: MessageRowViewModel
    var threadVM: ThreadViewModel? { viewModel.threadVM }
    var message: Message { viewModel.message }
}

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
                self?.onForwardAction(model)
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
        model.threadVM?.sendContainerViewModel.focusOnTextInput = true
        model.threadVM?.animateObjectWillChange()
    }

    private func onReplyPrivatelyAction(_ model: ActionModel) {
        guard let participant = model.message.participant else { return }
        AppState.shared.appStateNavigationModel.replyPrivately = model.message
        AppState.shared.openThread(participant: participant)
    }

    private func onForwardAction(_ model: ActionModel) {
        model.threadVM?.forwardMessage = model.message
        model.viewModel.isSelected = true
        model.threadVM?.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: true)
        model.viewModel.animateObjectWillChange()
        model.threadVM?.animateObjectWillChange()
    }

    private func onEditAction(_ model: ActionModel) {
        model.threadVM?.sendContainerViewModel.editMessage = model.message
        model.threadVM?.objectWillChange.send()
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
            model.threadVM?.animateObjectWillChange()
        }
    }

    private func onSelectAction(_ model: ActionModel) {
        model.viewModel.isSelected = true
        model.threadVM?.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: true)
        model.viewModel.animateObjectWillChange()
        model.threadVM?.animateObjectWillChange()
    }
}
