//
//  Sticker+.swift
//  Talk
//
//  Created by hamed on 8/12/23.
//

import TalkViewModels
import ChatModels
import SwiftUI
import TalkExtensions
import Chat
import ActionableContextMenu
import TalkUI

struct ReactionMenuView: View {
    @EnvironmentObject var contextMenuVM: ContextMenuModel
    @EnvironmentObject var viewModel: MessageRowViewModel
    var currentSelectedReaction: Reaction? { ChatManager.activeInstance?.reaction.inMemoryReaction.currentReaction(viewModel.message.id ?? 0)}
    @State var show = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Sticker.allCases, id: \.self) { sticker in
                    let isFirst = sticker == Sticker.allCases.first
                    let isLast = sticker == Sticker.allCases.last
                    Button {
                        if let messageId = viewModel.message.id, let conversationId = viewModel.threadVM?.threadId {
                            ReactionViewModel.shared.reaction(sticker, messageId: messageId, conversationId: conversationId)
                            contextMenuVM.hide()
                        }
                    } label: {
                        Text(verbatim: sticker.emoji)
                            .frame(width: 26, height: 26)
                            .font(.system(size: 24))
                            .padding(4)
                            .background(currentSelectedReaction?.reaction == sticker ? Color.App.primary.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius:(currentSelectedReaction?.reaction == sticker ? 20 : 0)))
                    }
                    .padding([isFirst ? .leading : isLast ? .trailing : .all], isFirst || isLast ? 16 : 0)
                    .scaleEffect(x: show ? 1.0 : 0.001, y: show ? 1.0 : 0.001, anchor: .center)
                    .transition(.scale)
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.55, blendDuration: 0.5)) {
                                show = true
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .frame(height: 52)
        .background(MixMaterialBackground())
        .clipShape(RoundedRectangle(cornerRadius:(21)))
    }
}

struct ReactionMenuView_Previews: PreviewProvider {
    struct Preview: View {
        static let message = Message(id: 1, message: "TEST", messageType: .text)
        @StateObject var viewModel = MessageRowViewModel(message: Preview.message, viewModel: ThreadViewModel(thread: Conversation(id: 1)))
        var body: some View {
            ReactionMenuView()
                .environmentObject(viewModel)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                        viewModel.showReactionsOverlay = true
                        viewModel.animateObjectWillChange()
                    }
                }
        }
    }

    static var previews: some View {
        Preview()
    }
}
