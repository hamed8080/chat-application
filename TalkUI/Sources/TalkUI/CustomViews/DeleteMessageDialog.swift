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
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    let threadVM: ThreadViewModel
    var viewModel: ThreadSelectedMessagesViewModel { threadVM.selectedMessagesViewModel }
    private var messages: [Message] { viewModel.selectedMessages.compactMap({$0.message}) }

    public init(viewModel: ThreadViewModel) {
        self.threadVM = viewModel
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("DeleteMessageDialog.title")
                .foregroundStyle(Color.App.text)
                .font(.iransansBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("DeleteMessageDialog.subtitle")
                .foregroundStyle(Color.App.text)
                .font(.iransansBody)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Button {
                    viewModel.clearSelection()
                    threadVM.isInEditMode = false
                    appOverlayVM.dialogView = nil
                    viewModel.animateObjectWillChange()
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.placeholder)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }

                Button {
                    threadVM.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}))
                    threadVM.isInEditMode = false
                    appOverlayVM.dialogView = nil
                    viewModel.animateObjectWillChange()
                } label: {
                    Text("Messages.deleteForMe")
                        .foregroundStyle(Color.App.orange)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }

                Button {
                    threadVM.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}), forAll: true)
                    threadVM.isInEditMode = false
                    appOverlayVM.dialogView = nil
                    viewModel.animateObjectWillChange()
                } label: {
                    Text("Messages.deleteForAll")
                        .foregroundStyle(Color.App.red)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct DeleteMessageDialog_Previews: PreviewProvider {
    static var previews: some View {
        DeleteMessageDialog(viewModel: .init(thread: Conversation(id: 1)))
    }
}
