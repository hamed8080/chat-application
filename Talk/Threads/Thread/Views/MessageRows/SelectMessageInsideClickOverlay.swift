//
//  SelectMessageInsideClickOverlay.swift
//  Talk
//
//  Created by hamed on 12/13/23.
//

import SwiftUI
import TalkViewModels

/// This view is for when the user is in selection mode to tap to select a message and if the user clicks inside the message, it will conflict with default actions inside the message view such as opening a map, opening the gallery, etc...
struct SelectMessageInsideClickOverlay: View {
    var viewModel: MessageRowViewModel

    var body: some View {
        if viewModel.threadVM?.selectedMessagesViewModel.isInSelectMode == true {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.state.isSelected.toggle()
                    viewModel.threadVM?.selectedMessagesViewModel.animateObjectWillChange()
                }
        }
    }
}

struct SelectMessageInsideClickOverlay_Previews: PreviewProvider {
    static var previews: some View {
        SelectMessageInsideClickOverlay(viewModel: .init(message: .init(), viewModel: .init(thread: .init())))
    }
}
