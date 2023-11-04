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
    let viewModel: ThreadViewModel
    private var messages: [Message] { viewModel.selectedMessages.compactMap({$0.message}) }

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
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
                    viewModel.isInEditMode = false
                    appOverlayVM.dialogView = nil
                    viewModel.animateObjectWillChange()
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.placeholder)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }

                Button {
                    viewModel.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}))
                    viewModel.isInEditMode = false
                    appOverlayVM.dialogView = nil
                    viewModel.animateObjectWillChange()
                } label: {
                    Text("Messages.deleteForMe")
                        .foregroundStyle(Color.App.orange)
                        .font(.iransansBoldBody)
                        .frame(minWidth: 48, minHeight: 48)
                }

                Button {
                    viewModel.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}), forAll: true)
                    viewModel.isInEditMode = false
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
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 6)
        .background(MixMaterialBackground())
    }
}

struct DeleteMessageDialog_Previews: PreviewProvider {
    static var previews: some View {
        DeleteMessageDialog(viewModel: .init(thread: Conversation(id: 1)))
    }
}
