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

struct MessageActionMenu: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel
    @EnvironmentObject var navVM: NavigationModel

    var body: some View {
        Button {
            withAnimation(animation(appear: threadVM?.replyMessage != nil)) {
                threadVM?.replyMessage = message
                threadVM?.objectWillChange.send()
            }
        } label: {
            Label("Messages.ActionMenu.reply", systemImage: "arrowshape.turn.up.left")
        }

        Button {
            guard let participant = message.participant else { return }
            AppState.shared.replyPrivately = message
            AppState.shared.openThread(participant: participant)
        } label: {
            Label("Messages.ActionMenu.replyPrivately", systemImage: "arrowshape.turn.up.left")
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
            Label("Messages.ActionMenu.forward", systemImage: "arrowshape.turn.up.forward")
        }

        Button {
            withAnimation(animation(appear: threadVM?.editMessage != nil)) {
                threadVM?.editMessage = message
                threadVM?.objectWillChange.send()
            }
        } label: {
            Label("General.edit", systemImage: "pencil.circle")
        }
        .disabled(message.editable == false)

        Button {
            UIPasteboard.general.string = message.message
        } label: {
            Label("Messages.ActionMenu.copy", systemImage: "doc.on.doc")
        }

        if message.isFileType == true {
            Button {
                threadVM?.clearCacheFile(message: message)
                threadVM?.animateObjectWillChange()
            } label: {
                Label("Messages.ActionMenu.deleteCache", systemImage: "cylinder.split.1x2")
            }
        }

        Button {
            threadVM?.togglePinMessage(message)
            threadVM?.animateObjectWillChange()
        } label: {
            Label((message.pinned ?? false) ? "Messages.ActionMenu.unpinMessage" : "Messages.ActionMenu.pinMessage", systemImage: "pin")
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

        Button(role: .destructive) {
            threadVM?.deleteMessages([message])
            threadVM?.animateObjectWillChange()
        } label: {
            Label("General.delete", systemImage: "trash")
        }
        .disabled(message.deletable == false)
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }
}
