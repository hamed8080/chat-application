//
//  DeleteMessageDialog.swift
//  
//
//  Created by hamed on 7/23/23.
//

import SwiftUI
import ChatModels
import TalkViewModels

public struct DeleteMessageDialog: View {
    let viewModel: ThreadViewModel
    private var messages: [Message] { viewModel.selectedMessages.compactMap({$0.message}) }

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text("DeleteMessageDialog.title")
                .font(.iransansTitle.bold())
                .foregroundColor(.red)
            Text("DeleteMessageDialog.subtitle")
                .foregroundColor(.secondaryLabel)
                .font(.iransansSubheadline)
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
                    viewModel.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}))
                    viewModel.isInEditMode = false
                    viewModel.deleteDialaog = false
                    viewModel.animateObjectWillChange()
                } label: {
                    Label("General.delete", systemImage: "trash.circle.fill")
                        .frame(minWidth: 256)
                        .font(.iransansBody)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)

                Button {
                    viewModel.clearSelection()
                    viewModel.isInEditMode = false
                    viewModel.deleteDialaog = false
                    viewModel.animateObjectWillChange()
                } label: {
                    Label("General.cancel", systemImage: "xmark.circle.fill")
                        .frame(minWidth: 256)
                        .font(.iransansBody)
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
        DeleteMessageDialog(viewModel: .init(thread: Conversation(id: 1)))
    }
}
