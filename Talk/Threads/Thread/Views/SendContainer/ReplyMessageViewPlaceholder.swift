//
//  ReplyMessageViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI

struct ReplyMessageViewPlaceholder: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @State private var message: String = ""

    var body: some View {
        if let replyMessage = viewModel.replyMessage {
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
                        viewModel.replyMessage = nil
                        viewModel.sendContainerViewModel.focusOnTextInput = false
                        viewModel.selectedMessagesViewModel.clearSelection()
                        viewModel.animateObjectWillChange()
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

struct ReplyMessageViewPlaceholder_Previews: PreviewProvider {
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
