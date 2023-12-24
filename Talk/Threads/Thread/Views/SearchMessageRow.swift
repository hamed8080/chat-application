//
//  SearchMessageRow.swift
//  Talk
//
//  Created by hamed on 6/21/22.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct SearchMessageRow: View {
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @State var viewModel: MessageRowViewModel

    var body: some View {
        Button {
            if let time = message.time, let messageId = message.id {
                threadVM?.historyVM.moveToTime(time, messageId)
                threadVM?.searchedMessagesViewModel.cancel()
                threadVM?.animateObjectWillChange()
            }
        } label: {
            MessageRowFactory(viewModel: viewModel)
                .disabled(true)
        }
    }
}

struct SearchMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchMessageRow(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
            .environmentObject(MessageRowViewModel(message: MockData.message, viewModel: .init(thread: Conversation())))
    }
}
