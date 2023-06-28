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
            withAnimation {
                viewModel.replyMessage = message
            }
        } label: {
            Label("Reply", systemImage: "arrowshape.turn.up.left")
        }

        Button {
            withAnimation {
                viewModel.forwardMessage = message
            }
        } label: {
            Label("forward", systemImage: "arrowshape.turn.up.forward")
        }

        Button {
            withAnimation {
                viewModel.editMessage = message
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
            } label: {
                Label("Delete file from cache", systemImage: "cylinder.split.1x2")
            }
        }

        Button {
            viewModel.togglePinMessage(message)
        } label: {
            Label((message.pinned ?? false) ? "UnPin" : "Pin", systemImage: "pin")
        }

        Button {
            withAnimation {
                viewModel.isInEditMode = true
            }
        } label: {
            Label("Select", systemImage: "checkmark.circle")
        }

        Button(role: .destructive) {
            withAnimation {
                viewModel.deleteMessages([message])
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .disabled(message.deletable == false)
    }
}
