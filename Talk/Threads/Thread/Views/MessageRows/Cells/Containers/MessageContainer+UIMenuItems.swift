//
//  MessageContainerStackView+UIMenuItems.swift
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
extension MessageContainerStackView {

    public func menu(model: ActionModel) -> CustomMenu {
        let message: any HistoryMessageProtocol = model.message
        let threadVM = model.threadVM
        let viewModel = model.viewModel

        let menu = CustomMenu()

        let replyAction = ActionMenuItem(model: .reply) { [weak self] in
            self?.onReplyAction(model)
            self?.closeContexMenu()
        }
        menu.addItem(replyAction)

        if threadVM?.thread.group == true, !viewModel.calMessage.isMe {
            let replyPrivatelyAction = ActionMenuItem(model: .replyPrivately) { [weak self] in
                self?.onReplyPrivatelyAction(model)
                self?.closeContexMenu()
            }
            menu.addItem(replyPrivatelyAction)
        }

        let forwardAction = ActionMenuItem(model: .forward) { [weak self] in
            self?.onForwardAction(model)
            self?.closeContexMenu()
        }
        menu.addItem(forwardAction)

        if viewModel.calMessage.canEdit {
            let emptyText = message.message == nil || message.message == ""
            let editAction = ActionMenuItem(model: emptyText ? .add : .edit) { [weak self] in
                self?.onEditAction(model)
                self?.closeContexMenu()
            }
            menu.addItem(editAction)
        }

        if let threadVM = threadVM, viewModel.message.ownerId == AppState.shared.user?.id && threadVM.thread.group == true {
            let seenListAction = ActionMenuItem(model: .seenParticipants) { [weak self] in
                self?.onSeenListAction(model)
                self?.closeContexMenu()
            }
            menu.addItem(seenListAction)
        }

        if viewModel.message.isImage {
            let saveImageAction = ActionMenuItem(model: .saveImage) { [weak self] in
                self?.onSaveAction(model)
                self?.closeContexMenu()
            }
            menu.addItem(saveImageAction)
        }

        if viewModel.calMessage.rowType.isVideo, viewModel.fileState.state == .completed {
            let saveVideoAction = ActionMenuItem(model: .saveVideo) { [weak self] in
                self?.onSaveVideoAction(model)
                self?.closeContexMenu()
            }
            menu.addItem(saveVideoAction)
        }

        if !viewModel.message.isFileType || message.message?.isEmpty == false {
            let copyAction = ActionMenuItem(model: .copy) { [weak self] in
                self?.onCopyAction(model)
                self?.closeContexMenu()
            }
            menu.addItem(copyAction)
        }

        if EnvironmentValues.isTalkTest, message.isFileType == true {
            let deleteCacheAction = ActionMenuItem(model: .deleteCache) { [weak self] in
                self?.onDeleteCacheAction(model)
                self?.closeContexMenu()
            }
            menu.addItem(deleteCacheAction)
        }

        let isPinned = message.id == threadVM?.thread.pinMessage?.id && threadVM?.thread.pinMessage != nil
        if threadVM?.thread.admin == true {
            let pinAction = ActionMenuItem(model: isPinned ? .unpin : .pin) { [weak self] in
                self?.onPinAction(model)
                self?.closeContexMenu()
            }
            menu.addItem(pinAction)
        }

        let selectAction = ActionMenuItem(model: .select) { [weak self] in
            self?.onSelectAction(model)
            self?.closeContexMenu()
        }
        menu.addItem(selectAction)

        if let message = message as? Message {
            let isDeletable = DeleteMessagesViewModelModel.isDeletable(isMe: viewModel.calMessage.isMe, message: message, thread: threadVM?.thread)
            if isDeletable {
                let deleteAction = ActionMenuItem(model: .delete) { [weak self] in
                    self?.onDeleteAction(model)
                    self?.closeContexMenu()
                }
                menu.addItem(deleteAction)
            }
        }
        menu.removeLastSeparator()
        return menu
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

    private func closeContexMenu() {
        viewModel?.threadVM?.delegate?.dismissContextMenu()
    }
}
