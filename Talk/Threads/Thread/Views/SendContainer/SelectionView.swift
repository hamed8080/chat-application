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
    let viewModel: ThreadViewModel
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @State private var selectedCount: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            SendContainerButton(image: "arrow.turn.up.right") {
                viewModel.sheetType = .threadPicker
                viewModel.animateObjectWillChange()
            }
            HStack(spacing: 2) {
                Text(selectedCount.localNumber(locale: Language.preferredLocale) ?? "")
                    .font(.iransansBoldBody)
                    .foregroundStyle(Color.App.primary)
                Text("General.selected")
                    .foregroundStyle(Color.App.hint)
                if viewModel.forwardMessage != nil {
                    Text("Thread.SendContainer.toForward")
                        .foregroundStyle(Color.App.hint)
                }
            }
            .padding(.trailing)
            .font(.iransansBody)
            .offset(x: 8)
            Spacer()

            /// Disable showing the delete button when forwarding in a conversation where we are not the admin and we just want to forward messages, so the delete button should be hidden.
            if !viewModel.thread.disableSend {
                Button {
                    appOverlayVM.dialogView = AnyView(DeleteMessageDialog(viewModel: viewModel))
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
                viewModel.isInEditMode = false
                viewModel.clearSelection()
                viewModel.animateObjectWillChange()
            }            
        }
        .onReceive(viewModel.objectWillChange) { _ in
            withAnimation {
                selectedCount = viewModel.selectedMessages.count
            }
        }
    }
}

struct SelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SelectionView(viewModel: .init(thread: .init(id: 1)))
    }
}
