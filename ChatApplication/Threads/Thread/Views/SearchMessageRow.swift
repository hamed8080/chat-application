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
    @EnvironmentObject var viewModel: ThreadViewModel
    let message: Message
    @State var calculation = MessageRowCalculationViewModel()

    var body: some View {
        Button {
            if let time = message.time, let messageId = message.id {
                viewModel.moveToTime(time, messageId)
                viewModel.searchedMessages.removeAll()
                viewModel.searchMessageText = ""
            }
        } label: {
            TextMessageType(message: message)
                .environmentObject(calculation)
                .disabled(true)
        }
    }
}

struct SearchMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchMessageRow(message: MockData.message)
    }
}
