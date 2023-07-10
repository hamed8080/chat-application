//
//  SearchMessageRow.swift
//  ChatApplication
//
//  Created by hamed on 6/21/22.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatModels
import SwiftUI

struct SearchMessageRow: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel { viewModel.threadVM }
    @EnvironmentObject var viewModel: MessageRowViewModel

    var body: some View {
        Button {
            if let time = message.time, let messageId = message.id {
                threadVM.moveToTime(time, messageId)
                threadVM.searchedMessages.removeAll()
                threadVM.animatableObjectWillChange()
            }
        } label: {
            TextMessageType()
                .environmentObject(viewModel)
                .disabled(true)
        }
    }
}

struct SearchMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchMessageRow()
            .environmentObject(MessageRowViewModel(message: MockData.message, viewModel: .init(thread: Conversation())))
    }
}
