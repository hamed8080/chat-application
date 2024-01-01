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
    private var message: Message { viewModel.message }
    private var threadVM: ThreadViewModel? { viewModel.threadVM }
    @State var viewModel: MessageRowViewModel

    var body: some View {
        Button {
            if let time = message.time, let messageId = message.id {
                AppState.shared.objectsContainer.navVM.remove(type: DetailViewModel.self)
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
                        .foregroundStyle(Color.App.text)
                        .lineLimit(1)
                    HStack {
                        if let timeString = message.time?.date.localFormattedTime {
                            Text(timeString)
                                .foregroundStyle(Color.App.hint)
                        }
                        Spacer()
                        if let name = message.participant?.name {
                            Text(name)
                                .foregroundStyle(Color.App.hint)
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
        SearchMessageRow(viewModel: .init(message: .init(id: 1), viewModel: .init(thread: .init(id: 1))))
            .environmentObject(MessageRowViewModel(message: MockData.message, viewModel: .init(thread: Conversation())))
    }
}
