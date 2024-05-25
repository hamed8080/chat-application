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
    private var hasEverDisonnected = false
    private var inQueueToGetReactions: [Int] = []
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
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                if status == .disconnected {
                    self?.hasEverDisonnected = true
                }
                if status == .connected && self?.hasEverDisonnected == true {
                    self?.onReconnected()
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
        chatReaction?.count(.init(messageIds: messageIds, conversationId: threadId))
    }

    public func getCurrentUserReaction(for messageId: Int) {
        chatReaction?.reaction(.init(messageId: messageId, conversationId: threadId))
    }

    public func getDetail(for messageId: Int, offset: Int = 0, count: Int, sticker: Sticker? = nil) {
        chatReaction?.get(.init(messageId: messageId,
                                offset: offset,
                                count: count,
                                conversationId: threadId,
                                sticker: sticker)
        )
    }

    @MainActor
    func onReactionEvent(_ event: ReactionEventTypes) async {
        switch event {
        case .inMemoryUpdate(let copies):
            await updateReactions(reactions: copies)
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
//                await threadVM?.scrollVM.scrollToBottomIfIsAtBottom()
            }
        }
    }

    func onReconnected() {
        // clear all reactions
        clearReactionsOnReconnect()
    }

    internal func fetchReactions(messages: [Message]) {
        if threadVM?.searchedMessagesViewModel.isInSearchMode == false {
            let messageIds = messages.filter({$0.id ?? -1 > 0}).filter({$0.reactionableType}).compactMap({$0.id})
            inQueueToGetReactions.append(contentsOf: messageIds)
            threadVM?.reactionViewModel.getReactionSummary(messageIds, conversationId: threadId)
        }
    }

    internal func updateReactions(reactions: [ReactionInMemoryCopy]) async {
        // We have to check if the response count is greater than zero because there is a chance to get reactions of zero count.
        // And we need to remove older reactions if any of them were removed.
        guard let historyVM = threadVM?.historyVM, reactions.count > 0 else { return }
        for copy in reactions {
            inQueueToGetReactions.removeAll(where: {$0 == copy.messageId})
            if let vm = historyVM.messageViewModel(for: copy.messageId) {
                await vm.setReaction(reactions: copy)
                vm.animateObjectWillChange()
            }
        }

        /// All things inisde the qeueu are old data and there will be a chance the reaction row has been removed.
        for id in inQueueToGetReactions {
            if let vm = historyVM.messageViewModel(for: id) {
                vm.clearReactions()
                vm.animateObjectWillChange()
            }
        }
        inQueueToGetReactions.removeAll()
    }

    internal func clearReactionsOnReconnect() {
        threadVM?.historyVM.sections.forEach { section in
            section.vms.forEach { vm in
                vm.invalid()
            }
        }
        fetchVisibleReactionsOnReconnect()
    }

    internal func fetchVisibleReactionsOnReconnect() {
        let visibleMessages = threadVM?.historyVM.getInvalidVisibleMessages() ?? []
        fetchReactions(messages: visibleMessages)
    }

}
