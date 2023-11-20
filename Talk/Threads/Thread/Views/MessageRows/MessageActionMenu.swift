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

struct MessageActionMenu: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel
    @EnvironmentObject var navVM: NavigationModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ContextMenuButton(title: "Messages.ActionMenu.reply", image: "arrowshape.turn.up.left") {
                withAnimation(animation(appear: threadVM?.replyMessage != nil)) {
                    threadVM?.replyMessage = message
                    threadVM?.objectWillChange.send()
                }
            }

            if threadVM?.thread.group == true {
                ContextMenuButton(title: "Messages.ActionMenu.replyPrivately", image: "arrowshape.turn.up.left") {
                    withAnimation(animation(appear: true)) {
                        guard let participant = message.participant else { return }
                        AppState.shared.replyPrivately = message
                        AppState.shared.openThread(participant: participant)
                    }
                }
            }

            ContextMenuButton(title: "Messages.ActionMenu.forward", image: "arrowshape.turn.up.forward") {
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
                    withAnimation(animation(appear: threadVM?.editMessage != nil)) {
                        threadVM?.editMessage = message
                        threadVM?.objectWillChange.send()
                    }
                }
                .disabled((message.editable ?? false) == false)
                .opacity((message.editable ?? false) == false ? 0.3 : 1.0)
                .allowsHitTesting((message.editable ?? false) == true)
            }

            if viewModel.message.ownerId == AppState.shared.user?.id && viewModel.threadVM?.thread.group == true {
                ContextMenuButton(title: "SeenParticipants.title", image: "info.bubble") {
                    withAnimation(animation(appear: threadVM?.forwardMessage != nil)) {
                        AppState.shared.objectsContainer.navVM.appendMessageParticipantsSeen(viewModel.message)
                    }
                }
            }

            ContextMenuButton(title: "Messages.ActionMenu.copy", image: "doc.on.doc") {
                UIPasteboard.general.string = message.message
            }

            if message.isFileType == true {
                ContextMenuButton(title: "Messages.ActionMenu.deleteCache", image: "cylinder.split.1x2") {
                    threadVM?.clearCacheFile(message: message)
                    threadVM?.animateObjectWillChange()
                }
            }

            let isPinned = message.id == viewModel.threadVM?.thread.pinMessage?.id && viewModel.threadVM?.thread.pinMessage != nil
            ContextMenuButton(title: isPinned ? "Messages.ActionMenu.unpinMessage" : "Messages.ActionMenu.pinMessage", image: "pin") {
                threadVM?.togglePinMessage(message)
                threadVM?.animateObjectWillChange()
            }

            ContextMenuButton(title: "General.select", image: "checkmark.circle") {
                withAnimation(animation(appear: threadVM?.isInEditMode == true)) {
                    threadVM?.isInEditMode = true
                    viewModel.isSelected = true
                    viewModel.animateObjectWillChange()
                    threadVM?.animateObjectWillChange()
                }
            }

            if viewModel.canDelete {
                ContextMenuButton(title: "General.delete", image: "trash", showSeparator: false) {
                    withAnimation(animation(appear: true)) {
                        if let threadVM {
                            threadVM.messageViewModels.first(where: {$0.message.id == message.id})?.isSelected = true
                            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteMessageDialog(viewModel: threadVM))
                        }
                    }
                }
                .foregroundStyle(Color.App.red)
                .disabled((message.deletable ?? false) == false)
                .opacity((message.deletable ?? false) == false  ? 0.3 : 1.0)
                .allowsHitTesting((message.deletable ?? false) == true)
            }
        }
        .foregroundColor(.primary)
        .frame(minWidth: 196)
        .background(MixMaterialBackground())
        .clipShape(RoundedRectangle(cornerRadius:((12))))
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }
}
