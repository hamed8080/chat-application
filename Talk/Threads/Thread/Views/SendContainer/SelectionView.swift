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

struct SelectionView: View {
    let viewModel: ThreadViewModel
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @State private var selectedCount: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            SendContainerButton(image: "arrowshape.turn.up.right.fill") {
                viewModel.sheetType = .threadPicker
                viewModel.animateObjectWillChange()
            }
            HStack(spacing: 2) {
                Text("\(selectedCount)")
                    .font(.iransansBoldBody)
                    .foregroundStyle(Color.App.hint)
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
                SendContainerButton(image: "trash.fill", imageColor: Color.App.red.opacity(0.58)) {
                    appOverlayVM.dialogView = AnyView(DeleteMessageDialog(viewModel: viewModel))
                }
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
