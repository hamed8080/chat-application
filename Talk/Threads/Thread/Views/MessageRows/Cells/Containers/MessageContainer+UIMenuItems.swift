//
//  MessageContainer+UIMenuItems.swift
//  Talk
//
//  Created by hamed on 6/24/24.
//

import Foundation
import UIKit
import Chat
import TalkModels
import TalkViewModels
import TalkExtensions
import TalkUI
import SwiftUI
import Photos

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
