//
//  MessageActionMenu.swift
//  ChatApplication
//
//  Created by hamed on 6/27/23.
//

import ChatAppViewModels
import ChatModels
import Foundation
import SwiftUI

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
            Label("Reply", systemImage: "arrowshape.turn.up.left")
        }

        Button {
            guard let participant = message.participant else { return }
            AppState.shared.replyPrivately = message
            AppState.shared.openThread(participant: participant)
        } label: {
            Label("ReplyPrivately", systemImage: "arrowshape.turn.up.left")
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
            Label("forward", systemImage: "arrowshape.turn.up.forward")
        }

        Button {
            withAnimation(animation(appear: threadVM?.editMessage != nil)) {
                threadVM?.editMessage = message
                threadVM?.objectWillChange.send()
            }
        } label: {
            Label("Edit", systemImage: "pencil.circle")
        }
        .disabled(message.editable == false)

        Button {
            UIPasteboard.general.string = message.message
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        if message.isFileType == true {
            Button {
                threadVM?.clearCacheFile(message: message)
                threadVM?.animateObjectWillChange()
            } label: {
                Label("Delete file from cache", systemImage: "cylinder.split.1x2")
            }
        }

        Button {
            threadVM?.togglePinMessage(message)
            threadVM?.animateObjectWillChange()
        } label: {
            Label((message.pinned ?? false) ? "UnPin" : "Pin", systemImage: "pin")
        }

        Button {
            withAnimation(animation(appear: threadVM?.isInEditMode == true)) {
                threadVM?.isInEditMode = true
                viewModel.isSelected = true
                viewModel.animateObjectWillChange()
                threadVM?.animateObjectWillChange()
            }
        } label: {
            Label("Select", systemImage: "checkmark.circle")
        }

        Button(role: .destructive) {
            threadVM?.deleteMessages([message])
            threadVM?.animateObjectWillChange()
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .disabled(message.deletable == false)
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }
}
