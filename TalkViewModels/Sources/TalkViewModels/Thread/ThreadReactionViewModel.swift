//
//  ThreadReactionViewModel.swift
//  Talk
//
//  Created by hamed on 10/22/22.
//

import Chat
import Foundation
import ChatModels
import Combine
import ChatCore
import ChatDTO

public final class ThreadReactionViewModel: ObservableObject {
    private var cancelable: Set<AnyCancellable> = []
    private var inMemoryReactions: InMemoryReactionProtocol? { ChatManager.activeInstance?.reaction.inMemoryReaction }
    weak var threadVM: ThreadViewModel?
    private var thread: Conversation? { threadVM?.thread }
    private var threadId: Int { thread?.id ?? -1 }
    private var chatReaction: ReactionProtocol? { ChatManager.activeInstance?.reaction }
    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.threadVM = viewModel
        registerObservers()
    }

    private func registerObservers() {
        NotificationCenter.reaction.publisher(for: .reaction)
            .compactMap { $0.object as? ReactionEventTypes }
            .sink { reactionEvent in
                Task { [weak self] in
                    await self?.onReactionEvent(reactionEvent)
                }
            }
            .store(in: &cancelable)
    }

    /// Add/Remove/Replace
    public func reaction(_ sticker: Sticker, messageId: Int) {
        let myReaction = inMemoryReactions?.currentReaction(messageId)
        if myReaction?.reaction == sticker, let reactionId = myReaction?.id {
            let req = DeleteReactionRequest(reactionId: reactionId, conversationId: threadId)
            chatReaction?.delete(req)
        } else if let reacrionId = myReaction?.id {
            let req = ReplaceReactionRequest(messageId: messageId, conversationId: threadId, reactionId: reacrionId, reaction: sticker)
            chatReaction?.replace(req)
        } else {
            let req = AddReactionRequest(messageId: messageId,
                                         conversationId: threadId,
                                         reaction: sticker
            )
            chatReaction?.add(req)
        }
    }

    public func getReactionSummary(_ messageIds: [Int], conversationId: Int) {
        chatReaction?.count(.init(messageIds: messageIds, conversationId: conversationId))
    }

    public func getCurrentUserReaction(for messageId: Int, conversationId: Int) {
        chatReaction?.reaction(.init(messageId: messageId, conversationId: conversationId))
    }

    public func getDetail(for messageId: Int, offset: Int = 0, conversationId: Int, sticker: Sticker? = nil) {
        chatReaction?.get(.init(messageId: messageId,
                                                       offset: offset,
                                                       count: 25,
                                                       conversationId: conversationId,
                                                       sticker: sticker))
    }

    @MainActor
    func onReactionEvent(_ event: ReactionEventTypes) async {
        switch event {
        case .inMemoryUpdate(let copies):
            await threadVM?.historyVM.updateReactions(reactions: copies)
            break
        case .add(let chatResponse):
            scrollToLastMessageIfLastMessageReacionChanged(chatResponse)
        case .replace(let chatResponse):
            scrollToLastMessageIfLastMessageReacionChanged(chatResponse)
        case .delete(let chatResponse):
            scrollToLastMessageIfLastMessageReacionChanged(chatResponse)
        default:
            break
        }
    }

    func scrollToLastMessageIfLastMessageReacionChanged(_ response: ChatResponse<ReactionMessageResponse>) {
        if response.result?.messageId == thread?.lastMessageVO?.id {
            Task {
                await threadVM?.scrollVM.scrollToBottomIfIsAtBottom()
            }
        }
    }
}
