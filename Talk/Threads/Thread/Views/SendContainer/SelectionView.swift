//
//  SelectionView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels

struct SelectionView: View {
    @EnvironmentObject var selectedMessagesViewModel: ThreadSelectedMessagesViewModel
    let threadVM: ThreadViewModel
    var viewModel: ThreadSelectedMessagesViewModel { threadVM.selectedMessagesViewModel }
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    private var selectedCount: Int { selectedMessagesViewModel.selectedMessages.count }

    var body: some View {
        HStack(spacing: 0) {
            if threadVM.selectedMessagesViewModel.selectedMessages.count == 1, let replyMessage = threadVM.selectedMessagesViewModel.selectedMessages.first?.message {
                SendContainerButton(image: "arrow.turn.up.left", fontWeight: .bold) {
                    threadVM.selectedMessagesViewModel.clearSelection()
                    threadVM.isInEditMode = false /// To hide the selection view and show reply bar and send container
                    threadVM.replyMessage = replyMessage
                    threadVM.focusOnTextInput = true
                    threadVM.animateObjectWillChange()
                }
            }

            SendContainerButton(image: "arrow.turn.up.right", fontWeight: .bold) {
                threadVM.sheetType = .threadPicker
                threadVM.animateObjectWillChange()
            }
            HStack(spacing: 2) {
                Text(selectedCount.localNumber(locale: Language.preferredLocale) ?? "")
                    .font(.iransansBoldBody)
                    .foregroundStyle(Color.App.primary)
                Text("General.selected")
                    .foregroundStyle(Color.App.hint)
                if threadVM.forwardMessage != nil {
                    Text("Thread.SendContainer.toForward")
                        .foregroundStyle(Color.App.hint)
                }
            }
            .padding(.trailing)
            .font(.iransansBody)
            .offset(x: 8)
            Spacer()

            /// Disable showing the delete button when forwarding in a conversation where we are not the admin and we just want to forward messages, so the delete button should be hidden.
            if !threadVM.thread.disableSend {
                let isAdmin = threadVM.thread.admin == true || threadVM.thread.group != true
                Button {
                    appOverlayVM.dialogView = AnyView(DeleteMessageDialog(deleteForMe: true, deleteForOthers: isAdmin, viewModel: threadVM))
                } label: {
                    Image("ic_delete")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 19, height: 18)
                        .tint(Color.App.gray5)
                }
                .frame(width: 36, height: 36)
                .buttonStyle(.borderless)
                .fontWeight(.medium)
            }

            CloseButton {
                selectedMessagesViewModel.clearSelection()
                threadVM.isInEditMode = false
                viewModel.clearSelection()
                viewModel.animateObjectWillChange()
            }            
        }
    }
}

struct SelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SelectionView(threadVM: .init(thread: .init(id: 1)))
    }
}
