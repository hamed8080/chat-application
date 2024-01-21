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

struct MessageActionMenu: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ContextMenuButton(title: "Messages.ActionMenu.reply", image: "arrowshape.turn.up.left") {
                withAnimation(animation(appear: threadVM?.replyMessage != nil)) {
                    threadVM?.replyMessage = message
                    threadVM?.sendContainerViewModel.focusOnTextInput = true
                    threadVM?.animateObjectWillChange()
                }
            }

            if threadVM?.thread.group == true, !viewModel.isMe {
                ContextMenuButton(title: "Messages.ActionMenu.replyPrivately", image: "arrowshape.turn.up.left") {
                    withAnimation(animation(appear: true)) {
                        guard let participant = message.participant else { return }
                        AppState.shared.appStateNavigationModel.replyPrivately = message
                        AppState.shared.openThread(participant: participant)
                    }
                }
                .overlay(alignment: Language.isRTL ? .bottomTrailing : .bottomLeading) {
                    Image(systemName: "lock")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 8, height: 8)
                        .offset(x: Language.isRTL ? -8 : 8, y: -8)
                        .foregroundStyle(Color.App.textSecondary)
                        .fontWeight(.semibold)
                }
            }

            ContextMenuButton(title: "Messages.ActionMenu.forward", image: "arrowshape.turn.up.right") {
                withAnimation(animation(appear: threadVM?.forwardMessage != nil)) {
                    threadVM?.forwardMessage = message
                    viewModel.isSelected = true
                    threadVM?.isInEditMode = true
                    viewModel.animateObjectWillChange()
                    threadVM?.animateObjectWillChange()
                }
            }

            if viewModel.canEdit {
                ContextMenuButton(title: "General.edit", image: "pencil.circle") {
                    withAnimation(animation(appear: threadVM?.sendContainerViewModel.editMessage != nil)) {
                        threadVM?.sendContainerViewModel.editMessage = message
                        threadVM?.objectWillChange.send()
                    }
                }
                .disabled((message.editable ?? false) == false)
                .opacity((message.editable ?? false) == false ? 0.3 : 1.0)
                .allowsHitTesting((message.editable ?? false) == true)
            }

            if let threadVM = threadVM, viewModel.message.ownerId == AppState.shared.user?.id && threadVM.thread.group == true {
                ContextMenuButton(title: "SeenParticipants.title", image: "info.bubble") {
                    withAnimation(animation(appear: threadVM.forwardMessage != nil)) {
                        AppState.shared.objectsContainer.navVM.appendMessageParticipantsSeen(viewModel.message, threadVM: threadVM)
                    }
                }
            }

            Group {
                if EnvironmentValues.isTalkTest {
                    if viewModel.message.isImage,
                       let url = viewModel.downloadFileVM?.fileURL,
                       let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        ContextMenuButton(title: "Messages.ActionMenu.saveImage", image: "square.and.arrow.down") {
                            UIImageWriteToSavedPhotosAlbum(image, viewModel, nil, nil)
                            let icon = Image(systemName: "externaldrive.badge.checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.App.white)
                            AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.imageSaved", messageColor: Color.App.textPrimary)
                        }
                    }
                }

                if !viewModel.message.isFileType || message.message?.isEmpty == false {
                    ContextMenuButton(title: "Messages.ActionMenu.copy", image: "doc.on.doc") {
                        UIPasteboard.general.string = message.message
                    }
                }
            }

            if EnvironmentValues.isTalkTest {
                if message.isFileType == true {
                    ContextMenuButton(title: "Messages.ActionMenu.deleteCache", image: "cylinder.split.1x2") {
                        threadVM?.clearCacheFile(message: message)
                        threadVM?.animateObjectWillChange()
                    }
                }
            }

            let isPinned = message.id == threadVM?.thread.pinMessage?.id && threadVM?.thread.pinMessage != nil
            if threadVM?.thread.admin == true {
                ContextMenuButton(title: isPinned ? "Messages.ActionMenu.unpinMessage" : "Messages.ActionMenu.pinMessage", image: "pin") {
                    if !isPinned, let threadVM = threadVM {
                        let dialog = PinMessageDialog(message: viewModel.message)
                            .environmentObject(threadVM)
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
                    } else {
                        threadVM?.threadPinMessageViewModel.unpinMessage(message.id ?? -1)
                        threadVM?.animateObjectWillChange()
                    }
                }
            }

            ContextMenuButton(title: "General.select", image: "checkmark.circle") {
                withAnimation(animation(appear: threadVM?.isInEditMode == true)) {
                    threadVM?.isInEditMode = true
                    viewModel.isSelected = true
                    viewModel.animateObjectWillChange()
                    threadVM?.animateObjectWillChange()
                }
            }

            let delete = MessageRowViewModel.isDeletable(isMe: viewModel.isMe, message: viewModel.message, thread: viewModel.threadVM?.thread)
            if delete.forMe || delete.ForOthers {
                ContextMenuButton(title: "General.delete", image: "trash", iconColor: Color.App.red, showSeparator: false) {
                    withAnimation(animation(appear: true)) {
                        if let threadVM {
                            threadVM.historyVM.sections.flatMap{$0.vms}.first(where: {$0.message.id == message.id})?.isSelected = true
                            let dialog = DeleteMessageDialog(deleteForMe: delete.forMe,
                                                             deleteForOthers: delete.ForOthers,
                                                             viewModel: threadVM)
                            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
                        }
                    }
                }
                .foregroundStyle(Color.App.red)
            }
        }
        .foregroundColor(.primary)
        .frame(width: 196)
        .background(MixMaterialBackground())
        .clipShape(RoundedRectangle(cornerRadius:((12))))
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }
}
