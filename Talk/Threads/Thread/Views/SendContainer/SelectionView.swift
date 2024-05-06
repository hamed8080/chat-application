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
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    private var selectedCount: Int { selectedMessagesViewModel.selectedMessages.count }

    var body: some View {
        HStack(spacing: 0) {
            SendContainerButton(image: "arrow.turn.up.right", fontWeight: .bold) {
                threadVM.sheetType = .threadPicker
                threadVM.animateObjectWillChange()
            }
            .disabled(selectedCount > 50)
            .opacity(selectedCount > 50 ? 0.3 : 1.0)

            HStack(spacing: 2) {
                Text(selectedCount.localNumber(locale: Language.preferredLocale) ?? "")
                    .font(.iransansBoldBody)
                    .foregroundStyle(Color.App.accent)
                Text("General.selected")
                    .foregroundStyle(Color.App.textSecondary)
                if threadVM.forwardMessage != nil {
                    Text("Thread.SendContainer.toForward")
                        .foregroundStyle(Color.App.textSecondary)
                }
            }
            .padding(.trailing)
            .font(.iransansBody)
            .offset(x: 8)
            Spacer()

            /// Disable showing the delete button when forwarding in a conversation where we are not the admin and we just want to forward messages, so the delete button should be hidden.
            if !threadVM.thread.disableSend {
                Button {
                    let viewModel = DeleteMessagesViewModelModel()
                    viewModel.setup(viewModel: self.threadVM)
                    appOverlayVM.dialogView = AnyView(DeleteMessageDialog(viewModel: viewModel))
                } label: {
                    Image("ic_delete")
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .tint(Color.App.iconSecondary)
                }
                .frame(width: 36, height: 36)
                .buttonStyle(.borderless)
                .fontWeight(.medium)
            }

            CloseButton {
                selectedMessagesViewModel.clearSelection()
                selectedMessagesViewModel.animateObjectWillChange()
            }
        }
    }
}

struct SelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SelectionView(threadVM: .init(thread: .init(id: 1)))
    }
}
