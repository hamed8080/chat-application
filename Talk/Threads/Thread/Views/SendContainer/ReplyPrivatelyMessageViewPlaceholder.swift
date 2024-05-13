//
//  ReplyPrivatelyMessageViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI

struct ReplyPrivatelyMessageViewPlaceholder: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @State private var message: String = ""

    var body: some View {
        if let replyMessage = AppState.shared.appStateNavigationModel.replyPrivately {
            HStack {
                SendContainerButton(image: "arrow.turn.up.left")

                VStack(alignment: .leading, spacing: 0) {
                    if let name = replyMessage.participant?.name {
                        Text(name)
                            .font(.iransansBoldBody)
                            .foregroundStyle(Color.App.accent)
                            .lineLimit(2)
                    }
                    Text(message)
                        .font(.iransansCaption2)
                        .foregroundColor(Color.App.textPlaceholder)
                        .lineLimit(2)
                        .onTapGesture {
                            // TODO: Go to reply message location
                        }
                }
                .frame(maxHeight: 48)

                Spacer()
                CloseButton {
                    Task {
                        await viewModel.scrollVM.disableExcessiveLoading()
                        AppState.shared.appStateNavigationModel = .init()
                        await viewModel.asyncAnimateObjectWillChange()
                        try? await Task.sleep(for: .milliseconds(300))
                        await viewModel.scrollVM.scrollToBottomIfIsAtBottom()
                    }
                }
                .padding(.trailing, 4)
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .task {
                self.message = replyMessage.message ?? replyMessage.fileMetaData?.name ?? ""
            }
        }
    }
}

struct ReplyPrivatelyMessageViewPlaceholder_Previews: PreviewProvider {
    struct Preview: View {
        var viewModel: ThreadViewModel {
            let viewModel = ThreadViewModel(thread: .init(id: 1))
            viewModel.replyMessage = .init(threadId: 1,
                                           message: "Test message", messageType: .text,
                                           participant: .init(name: "John Doe"))
            return viewModel
        }

        var body: some View {
            ReplyPrivatelyMessageViewPlaceholder()
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
