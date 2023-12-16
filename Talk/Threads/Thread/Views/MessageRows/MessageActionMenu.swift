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
import TalkUI
import TalkModels

struct MessageActionMenu: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel
    @EnvironmentObject var navVM: NavigationModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(animation(appear: threadVM?.replyMessage != nil)) {
                    threadVM?.replyMessage = message
                    threadVM?.objectWillChange.send()
                }
            } label: {
                Label("Messages.ActionMenu.reply", systemImage: "arrowshape.turn.up.left")
            }

            if threadVM?.thread.group == true, !viewModel.isMe {
                Button {
                    withAnimation(animation(appear: true)) {
                        guard let participant = message.participant else { return }
                        AppState.shared.appStateNavigationModel.replyPrivately = message
                        AppState.shared.openThread(participant: participant)
                    }
                } label: {
                    Label("Messages.ActionMenu.replyPrivately", systemImage: "arrowshape.turn.up.left")
                }
            }


            Button {
                withAnimation(animation(appear: threadVM?.forwardMessage != nil)) {
                    threadVM?.forwardMessage = message
                    viewModel.isSelected = true
                    threadVM?.isInEditMode = true
                    viewModel.animateObjectWillChange()
                    threadVM?.animateObjectWillChange()
                }
            } label: {
                Label("Messages.ActionMenu.forward", systemImage: "arrowshape.turn.up.right")
            }

            if viewModel.canEdit {
                Button {
                    withAnimation(animation(appear: threadVM?.editMessage != nil)) {
                        threadVM?.editMessage = message
                        threadVM?.objectWillChange.send()
                    }
                } label: {
                    Label("General.edit", systemImage: "pencil.circle")
                }
                .disabled((message.editable ?? false) == false)
                .opacity((message.editable ?? false) == false ? 0.3 : 1.0)
                .allowsHitTesting((message.editable ?? false) == true)
            }

            if viewModel.message.ownerId == AppState.shared.user?.id && viewModel.threadVM?.thread.group == true {
                Button {
                    withAnimation(animation(appear: threadVM?.forwardMessage != nil)) {
                        AppState.shared.objectsContainer.navVM.appendMessageParticipantsSeen(viewModel.message)
                    }
                } label: {
                    Label("SeenParticipants.title", systemImage: "info.bubble")
                }
            }

            Group {
                if viewModel.message.isImage,
                   let url = viewModel.downloadFileVM?.fileURL,
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    Button {
                        UIImageWriteToSavedPhotosAlbum(image, viewModel, nil, nil)
                        let icon = Image(systemName: "externaldrive.badge.checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.App.white)
                        AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, text: "General.imageSaved")
                    } label: {
                        Label("Messages.ActionMenu.saveImage", systemImage: "square.and.arrow.down")
                    }
                }

                if !viewModel.message.isFileType || message.message?.isEmpty == false {
                    Button {
                        UIPasteboard.general.string = message.message
                    } label: {
                        Label("Messages.ActionMenu.copy", systemImage: "doc.on.doc")
                    }
                }
            }

            if message.isFileType == true {
                Button {
                    threadVM?.clearCacheFile(message: message)
                    threadVM?.animateObjectWillChange()
                } label: {
                    Label("Messages.ActionMenu.deleteCache", systemImage: "cylinder.split.1x2")
                }
            }

            let isPinned = message.id == viewModel.threadVM?.thread.pinMessage?.id && viewModel.threadVM?.thread.pinMessage != nil
            if threadVM?.thread.admin == true {
                Button {
                    threadVM?.togglePinMessage(message)
                    threadVM?.animateObjectWillChange()
                } label: {
                    Label(isPinned ? "Messages.ActionMenu.unpinMessage" : "Messages.ActionMenu.pinMessage", systemImage: "pin")
                }
            }

            Button {
                withAnimation(animation(appear: threadVM?.isInEditMode == true)) {
                    threadVM?.isInEditMode = true
                    viewModel.isSelected = true
                    viewModel.animateObjectWillChange()
                    threadVM?.animateObjectWillChange()
                }
            } label: {
                Label("General.select", systemImage: "checkmark.circle")
            }

            let delete = MessageRowViewModel.isDeletable(isMe: viewModel.isMe, message: viewModel.message, thread: viewModel.threadVM?.thread)
            if delete.forMe || delete.ForOthers {
                Button(role: .destructive) {
                    withAnimation(animation(appear: true)) {
                        if let threadVM {
                            threadVM.messageViewModels.first(where: {$0.message.id == message.id})?.isSelected = true
                            let dialog = DeleteMessageDialog(deleteForMe: delete.forMe,
                                                             deleteForOthers: delete.ForOthers,
                                                             viewModel: threadVM)
                            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
                        }
                    }
                } label: {
                    Label("General.delete", systemImage: "trash")
                }
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
