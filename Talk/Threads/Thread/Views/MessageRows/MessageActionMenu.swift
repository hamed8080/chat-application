//
//  MessageActionMenu.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Foundation
import SwiftUI
import TalkViewModels
import ActionableContextMenu
import TalkUI
import TalkModels
import Chat

struct MessageActionMenu: View {
    private var message: any HistoryMessageProtocol { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var thread: Conversation { viewModel.threadVM?.thread ?? .init() }

    private var isChannel: Bool { thread.type?.isChannelType == true }
    private var isAdmin: Bool { thread.admin == true }
    private var isPinned: Bool { message.id == thread.pinMessage?.id && thread.pinMessage != nil }
    private var isGroup: Bool { thread.group == true }
    private var isMe: Bool { viewModel.calMessage.isMe }
    private var notAdminChannel: Bool { !isAdmin && isChannel }
    private var isFileType: Bool { viewModel.message.isFileType }
    private var isImage: Bool { viewModel.message.isImage }
    private var isEmptyText: Bool { message.message?.isEmpty == true || message.message == nil }
    private var isDeletable: Bool {
        guard let message = viewModel.message as? Message else { return false }
        return DeleteMessagesViewModelModel.isDeletable(isMe: viewModel.calMessage.isMe, message: message, thread: threadVM?.thread)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isDeletable {
                ContextMenuButton(title: "General.delete".bundleLocalized(), image: "trash", iconColor: Color.App.red, showSeparator: false) {
                    onDeleteTapped()
                }
                .foregroundStyle(Color.App.red)
            }

            ContextMenuButton(title: "Messages.ActionMenu.forward".bundleLocalized(), image: "arrowshape.turn.up.right") {
                onForwardTapped()
            }


            if !notAdminChannel {
                ContextMenuButton(title: "Messages.ActionMenu.reply".bundleLocalized(), image: "arrowshape.turn.up.left") {
                    onReplyTapped()
                }
            }

            if isAdmin {
                let key = isPinned ? "Messages.ActionMenu.unpinMessage" : "Messages.ActionMenu.pinMessage"
                ContextMenuButton(title: key.bundleLocalized(), image: "pin") {
                    onPinUnpinTapped()
                }
            }

            if isGroup, !isMe && !isChannel {
                ContextMenuButton(title: "Messages.ActionMenu.replyPrivately".bundleLocalized(), image: "arrowshape.turn.up.left") {
                    onReplyPrivatelyTapped()
                }
                .overlay(alignment: Language.isRTL ? .bottomTrailing : .bottomLeading) {
                    lockIcon
                }
            }

            ContextMenuButton(title: "General.select".bundleLocalized(), image: "checkmark.circle") {
                onSelectTapped()
            }

            if isMe && isGroup {
                ContextMenuButton(title: "Messages.ActionMenu.messageDetail".bundleLocalized(), image: "info.bubble") {
                    onInfoTapped()
                }
            }

            if viewModel.calMessage.canEdit {
                let key = isEmptyText ? "General.addText" : "General.edit"
                ContextMenuButton(title: key.bundleLocalized(), image: "pencil.circle") {
                    onAddOrEditTextTapped()
                }
                .disabled((message.editable ?? false) == false)
                .opacity((message.editable ?? false) == false ? 0.3 : 1.0)
                .allowsHitTesting((message.editable ?? false) == true)
            }

            Group {
                if isImage, isImageDownloaded() {
                    ContextMenuButton(title: "Messages.ActionMenu.saveImage".bundleLocalized(), image: "square.and.arrow.down") {
                        onSaveImageTapped()
                    }
                }

                if !isEmptyText {
                    ContextMenuButton(title: "Messages.ActionMenu.copy".bundleLocalized(), image: "doc.on.doc") {
                        UIPasteboard.general.string = message.message
                    }
                }
            }

            if EnvironmentValues.isTalkTest {
                if isFileType {
                    ContextMenuButton(title: "Messages.ActionMenu.deleteCache".bundleLocalized(), image: "cylinder.split.1x2") {
                        onClearCacheTapped()
                    }
                }
            }
        }
        .foregroundColor(.primary)
        .frame(width: 196)
        .background(MixMaterialBackground())
        .clipShape(RoundedRectangle(cornerRadius:((12))))
    }

    private var lockIcon: some View {
        Image(systemName: "lock")
            .resizable()
            .scaledToFill()
            .frame(width: 8, height: 8)
            .offset(x: Language.isRTL ? -8 : 8, y: -8)
            .foregroundStyle(Color.App.textSecondary)
            .fontWeight(.semibold)
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }

    private func onDeleteTapped() {
        withAnimation(animation(appear: true)) {
            if let threadVM {
                viewModel.calMessage.state.isSelected = true
                let deleteVM = DeleteMessagesViewModelModel()
                deleteVM.setup(viewModel: threadVM)
                let dialog = DeleteMessageDialog(viewModel: deleteVM)
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
            }
        }
    }

    private func onForwardTapped() {
        guard let message = viewModel.message as? Message else { return }
        withAnimation(animation(appear: threadVM?.forwardMessage != nil)) {
            threadVM?.forwardMessage = message
            viewModel.calMessage.state.isSelected = true
            threadVM?.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: true)
            viewModel.animateObjectWillChange()
            threadVM?.animateObjectWillChange()
        }
    }

    private func onReplyTapped() {
        guard let message = viewModel.message as? Message else { return }
        withAnimation(animation(appear: threadVM?.replyMessage != nil)) {
            threadVM?.replyMessage = message
            threadVM?.sendContainerViewModel.focusOnTextInput = true
            threadVM?.animateObjectWillChange()
        }
    }

    private func onPinUnpinTapped() {
        guard let message = viewModel.message as? Message else { return }
        if !isPinned, let threadVM = threadVM {
            let dialog = PinMessageDialog(message: message)
                .environmentObject(threadVM)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
        } else {
            threadVM?.threadPinMessageViewModel.unpinMessage(message.id ?? -1)
            threadVM?.animateObjectWillChange()
        }
    }

    private func onReplyPrivatelyTapped() {
        guard let message = viewModel.message as? Message else { return }
        withAnimation(animation(appear: true)) {
            guard let participant = message.participant else { return }
            AppState.shared.appStateNavigationModel.replyPrivately = message
            AppState.shared.openThread(participant: participant)
        }
    }

    private func onSelectTapped() {
        withAnimation(animation(appear: threadVM?.selectedMessagesViewModel.isInSelectMode == true)) {
            viewModel.calMessage.state.isSelected = true
            threadVM?.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: true)
            viewModel.animateObjectWillChange()
            threadVM?.animateObjectWillChange()
        }
    }

    private func onInfoTapped() {
        guard let message = viewModel.message as? Message else { return }
        withAnimation(animation(appear: threadVM?.forwardMessage != nil)) {
            let value = MessageParticipantsSeenNavigationValue(message: message, threadVM: threadVM ?? .init(thread: thread))
            AppState.shared.objectsContainer.navVM.append(value: value)
        }
    }

    private func onAddOrEditTextTapped() {
        guard let message = viewModel.message as? Message else { return }
        withAnimation(animation(appear: threadVM?.sendContainerViewModel.editMessage != nil)) {
            threadVM?.sendContainerViewModel.editMessage = message
            threadVM?.objectWillChange.send()
            Task { @MainActor in
                await threadVM?.scrollVM.scrollToBottomIfIsAtBottom()
            }
        }
    }

    private func onSaveImageTapped() {
        if let url = viewModel.message.fileURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, viewModel, nil, nil)
            let icon = Image(systemName: "externaldrive.badge.checkmark")
                .fontWeight(.semibold)
                .foregroundStyle(Color.App.white)
            AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.imageSaved", messageColor: Color.App.textPrimary)
        }
    }

    private func isImageDownloaded() -> Bool {
        guard let chat = ChatManager.activeInstance, let url = message.url else { return false }
        return chat.file.isFileExist(url) || chat.file.isFileExistInGroup(url)
    }

    private func onClearCacheTapped() {
        guard let message = viewModel.message as? Message else { return }
        threadVM?.clearCacheFile(message: message)
        threadVM?.animateObjectWillChange()
    }
}
