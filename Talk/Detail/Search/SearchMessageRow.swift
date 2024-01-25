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
import TalkModels

struct SearchMessageRow: View {
    let message: Message
    let threadVM: ThreadViewModel?

    var body: some View {
        Button {
            if let time = message.time, let messageId = message.id {
                AppState.shared.objectsContainer.navVM.remove(type: ThreadDetailViewModel.self)
                AppState.shared.objectsContainer.navVM.paths.removeLast() /// For click on item search                
                threadVM?.historyVM.moveToTime(time, messageId)
                threadVM?.searchedMessagesViewModel.cancel()
                threadVM?.animateObjectWillChange()
            }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(message.message ?? "")
                        .font(.iransansBody)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.App.textPrimary)
                        .lineLimit(1)
                    HStack {
                        if let timeString = message.time?.date.localFormattedTime {
                            Text(timeString)
                                .foregroundStyle(Color.App.textSecondary)
                        }
                        Spacer()
                        if let name = message.participant?.name {
                            Text(name)
                                .foregroundStyle(Color.App.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
            }
            .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
            .padding()
        }
    }
}

struct SearchMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchMessageRow(message: .init(id: 1), threadVM: .init(thread: .init(id: 1)))
            .environmentObject(MessageRowViewModel(message: MockData.message, viewModel: .init(thread: Conversation())))
    }
}
