//
//  ForwardMessagesViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels

struct ForwardMessagesViewPlaceholder: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if viewModel.threadId == AppState.shared.forwardMessageRequest?.threadId, let forwardMessage = AppState.shared.forwardMessageRequest {
            HStack {
                SendContainerButton(image: "arrow.turn.up.right")

                VStack(alignment: .leading, spacing: 0) {
                    if forwardMessage.messageIds.count == 1, let message = AppState.shared.forwardMessages?.first {
                        Text("Thread.forwardTheMessage")
                            .foregroundStyle(Color.App.primary)
                            .font(.iransansCaption)
                        Text(message.message ?? "")
                            .font(.iransansCaption2)
                            .foregroundColor(Color.App.placeholder)
                    } else {
                        let localized = String(localized: .init("Thread.forwardMessages"))
                        let localNumber = (AppState.shared.forwardMessages?.count ?? 0).localNumber(locale: Language.preferredLocale) ?? ""
                        Text(String(format: localized, localNumber))
                            .foregroundStyle(Color.App.primary)
                            .font(.iransansCaption)
                        let messages = AppState.shared.forwardMessages?.prefix(4).compactMap({$0.message?.prefix(20)}).joined(separator: ", ")
                        Text(messages ?? "")
                            .font(.iransansCaption2)
                            .foregroundColor(Color.App.placeholder)
                    }
                }
                Spacer()
                CloseButton {
                    AppState.shared.forwardMessages = nil
                    AppState.shared.forwardMessageRequest = nil
                    viewModel.selectedMessagesViewModel.clearSelection()
                    viewModel.animateObjectWillChange()
                }
                .padding(.trailing, 4)
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
        }
    }
}

struct ForwardMessagesViewPlaceholder_Previews: PreviewProvider {
    struct Preview: View {
        var viewModel: ThreadViewModel {
            let viewModel = ThreadViewModel(thread: .init(id: 1))
            viewModel.replyMessage = .init(threadId: 1,
                                           message: "Test message", messageType: .text,
                                           participant: .init(name: "John Doe"))
            return viewModel
        }

        var body: some View {
            ReplyMessageViewPlaceholder()
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
