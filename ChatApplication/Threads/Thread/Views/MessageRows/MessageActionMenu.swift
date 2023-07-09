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
    var message: Message
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        Button {
            withAnimation(animation(appear: viewModel.replyMessage != nil)) {
                viewModel.replyMessage = message
                viewModel.objectWillChange.send()
            }
        } label: {
            Label("Reply", systemImage: "arrowshape.turn.up.left")
        }

        Button {
            withAnimation(animation(appear: viewModel.forwardMessage != nil)) {
                viewModel.forwardMessage = message
                viewModel.isInEditMode = true
                viewModel.objectWillChange.send()
            }
        } label: {
            Label("forward", systemImage: "arrowshape.turn.up.forward")
        }

        Button {
            withAnimation(animation(appear: viewModel.editMessage != nil)) {
                viewModel.editMessage = message
                viewModel.objectWillChange.send()
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
                viewModel.clearCacheFile(message: message)
                viewModel.animatableObjectWillChange()
            } label: {
                Label("Delete file from cache", systemImage: "cylinder.split.1x2")
            }
        }

        Button {
            viewModel.togglePinMessage(message)
            viewModel.animatableObjectWillChange()
        } label: {
            Label((message.pinned ?? false) ? "UnPin" : "Pin", systemImage: "pin")
        }

        Button {
            withAnimation(animation(appear: viewModel.isInEditMode)) {
                viewModel.isInEditMode = true
                viewModel.objectWillChange.send()
            }
        } label: {
            Label("Select", systemImage: "checkmark.circle")
        }

        Button(role: .destructive) {
            viewModel.deleteMessages([message])
            viewModel.animatableObjectWillChange()
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .disabled(message.deletable == false)
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }
}
