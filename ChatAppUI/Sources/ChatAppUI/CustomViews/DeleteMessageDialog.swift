//
//  DeleteMessageDialog.swift
//  
//
//  Created by hamed on 7/23/23.
//

import SwiftUI
import ChatModels
import ChatAppViewModels

public struct DeleteMessageDialog: View {
    let viewModel:ThreadViewModel
    @Binding var showDialog: Bool
    private var messages: [Message] { viewModel.selectedMessages }

    public init(viewModel: ThreadViewModel, showDialog: Binding<Bool>) {
        self.viewModel = viewModel
        self._showDialog = showDialog
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text("Delete selected messages")
                .font(.iransansTitle.bold())
                .foregroundColor(.red)
            Text("Are you sure you want to delete all selected messages?")
                .foregroundColor(.secondaryLabel)
                .font(.subheadline)
            VStack {
                ForEach(messages.prefix(3)) { message in
                    Text(message.message ?? "")
                        .font(.iransansCaption)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }
            if messages.count > 3 {
                Text("...")
            }

            VStack {
                Button(role: .destructive) {
                    viewModel.deleteMessages(viewModel.selectedMessages)
                    viewModel.isInEditMode = false
                    showDialog = false
                    viewModel.animateObjectWillChange()
                } label: {
                    Label("Delete", systemImage: "trash.circle.fill")
                        .frame(minWidth: 256)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)

                Button {
                    viewModel.selectedMessages.removeAll()
                    viewModel.isInEditMode = false
                    showDialog = false
                    viewModel.animateObjectWillChange()
                } label: {
                    Label("Cancel", systemImage: "xmark.circle.fill")
                        .frame(minWidth: 256)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
            .padding()
        }
        .padding(24)
        .background(.ultraThickMaterial)
        .cornerRadius(16)
    }
}

struct DeleteMessageDialog_Previews: PreviewProvider {
    static var previews: some View {
        DeleteMessageDialog(viewModel: .init(thread: Conversation(id: 1)), showDialog: .constant(false))
    }
}
