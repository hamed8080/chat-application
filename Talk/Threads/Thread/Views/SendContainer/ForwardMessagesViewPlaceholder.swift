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
    private var model: AppStateNavigationModel { AppState.shared.appStateNavigationModel }

    var body: some View {
        HStack {
            SendContainerButton(image: "arrow.turn.up.right")

            VStack(alignment: .leading, spacing: 0) {
                if isSingleForward {
                    Text("Thread.forwardTheMessage")
                        .foregroundStyle(Color.App.accent)
                        .font(.iransansCaption)
                    Text(singleForwardMessage)
                        .font(.iransansCaption2)
                        .foregroundColor(Color.App.textPlaceholder)
                        .lineLimit(2)
                } else {
                    Text(numberOfSelected)
                        .foregroundStyle(Color.App.accent)
                        .font(.iransansCaption)

                    Text(splitedMessages)
                        .font(.iransansCaption2)
                        .foregroundColor(Color.App.textPlaceholder)
                        .lineLimit(2)
                }
            }
            Spacer()
            CloseButton {
                onCloseButtonTapped()
            }
            .padding(.trailing, 4)
        }
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
        .frame(height: hasAnythingToForward ? nil : 0)
        .clipped()
    }

    private func onCloseButtonTapped() {
        Task {
            AppState.shared.appStateNavigationModel = .init()
            viewModel.selectedMessagesViewModel.clearSelection()
            await viewModel.scrollVM.scrollToBottomIfIsAtBottom()
            await viewModel.scrollVM.disableExcessiveLoading()
            viewModel.animateObjectWillChange()
        }
    }

    private var numberOfSelected: String {
        let model = AppState.shared.appStateNavigationModel
        let localized = String(localized: .init("Thread.forwardMessages"), bundle: Language.preferedBundle)
        let localNumber = (model.forwardMessages?.count ?? 0).localNumber(locale: Language.preferredLocale) ?? ""
        return String(format: localized, localNumber)
    }

    private var splitedMessages: String {
        return model.forwardMessages?.prefix(4).compactMap({$0.message?.prefix(20)}).joined(separator: ", ") ?? ""
    }

    private var isSingleForward: Bool {
        model.forwardMessageRequest?.messageIds.count ?? 0 == 1 && model.forwardMessages?.first != nil
    }

    private var singleForwardMessage: String {
        model.forwardMessages?.first?.message ?? ""
    }

    private var hasAnythingToForward: Bool {
        viewModel.threadId == model.forwardMessageRequest?.threadId && model.forwardMessageRequest != nil
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
