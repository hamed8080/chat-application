//
//  ReactionViewModel.swift
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

public final class ReactionViewModel: ObservableObject {
    public var reactions: [Int: [Reaction]] = [:]
    public var userSelectedReactions: [Int: Reaction] = [:]
    public var reactionCountList: [ReactionCountList] = []
    private var cancelable: Set<AnyCancellable> = []
    public static let shared: ReactionViewModel = .init()
    @Published public var selectedMessageReactionDetails: ReactionList?
    
    private init() {
        NotificationCenter.default.publisher(for: .reaction)
            .compactMap { $0.object as? ReactionEventTypes }
            .sink { [weak self] event in
                self?.onReaction(event)
            }
            .store(in: &cancelable)
    }

    /// Add/Remove/Replace
    public func reaction(_ sticker: Sticker, messageId: Int, conversationId: Int) {
        let myReaction = userSelectedReactions.first(where: {$0.key == messageId})?.value
        if myReaction?.reaction == sticker, let reactionId = myReaction?.id {
            let req = DeleteReactionRequest(reactionId: reactionId, conversationId: conversationId)
            ChatManager.activeInstance?.reaction.delete(req)
        } else if let reacrionId = myReaction?.id {
            let req = ReplaceReactionRequest(messageId: messageId, conversationId: conversationId, reactionId: reacrionId, reaction: sticker)
            ChatManager.activeInstance?.reaction.replace(req)
        } else {
            let req = AddReactionRequest(messageId: messageId,
                                         conversationId: conversationId,
                                         reaction: sticker
            )
            ChatManager.activeInstance?.reaction.add(req)
        }
    }

    public func onReaction(_ event: ReactionEventTypes) {
        switch event {
        case .reaction(let response):
            onCurrentUserReaction(response)
        case .count(let chatResponse):
            onCount(chatResponse)
        case .list(let chatResponse):
            onDetail(chatResponse)
        case .add(let chatResponse):
            onAdd(chatResponse)
        case .replace(let chatResponse):
            onReplace(chatResponse)
        case .delete(let chatResponse):
            onDelete(chatResponse)
        }
    }

    public func getReaction(_ messageIds: [Int], conversationId: Int) {
        var requestReactionIds: [Int] = []
        messageIds.forEach { id in
            if !ReactionViewModel.shared.reactions.keys.contains(id) {
                requestReactionIds.append(id)
            }
        }
        ChatManager.activeInstance?.reaction.count(.init(messageIds: requestReactionIds, conversationId: conversationId))
    }

    public func onCount(_ response: ChatResponse<[ReactionCountList]>) {
        response.result?.forEach{ item in
            if let index = reactionCountList.firstIndex(where: {$0.messageId == item.messageId}) {
                reactionCountList[index] = item
            } else {
                self.reactionCountList.append(item)
            }
        }
    }

    public func getCurrentUserReaction(for messageId: Int, conversationId: Int) {
        ChatManager.activeInstance?.reaction.reaction(.init(messageId: messageId, conversationId: conversationId))
    }

    public func getDetail(for messageId: Int, offset: Int = 0, conversationId: Int) {
        ChatManager.activeInstance?.reaction.get(.init(messageId: messageId, offset: offset, count: 25, conversationId: conversationId))
    }

    public func onDetail(_ response: ChatResponse<ReactionList>) {
        selectedMessageReactionDetails = response.result
        animateObjectWillChange()
    }

    public func onAdd(_ response: ChatResponse<ReactionMessageResponse>) {
        if let messageId = response.result?.messageId, let reaction = response.result?.reaction {
            calculateReactionCount(messageId: messageId, reaction: reaction, type: .addReaction)
            self.reactions[messageId]?.append(reaction)
            if reaction.participant?.id == AppState.shared.user?.id {
                userSelectedReactions[messageId] = reaction
            }
        }
    }

    public func onReplace(_ response: ChatResponse<ReactionMessageResponse>) {
        if let messageId = response.result?.messageId, let reaction = response.result?.reaction {
            calculateReactionCount(messageId: messageId, reaction: reaction, type: .replaceReaction)
            if reaction.participant?.id == AppState.shared.user?.id {
                userSelectedReactions[messageId] = reaction
            }
            self.reactions[messageId]?.removeAll(where: {$0.participant?.id == AppState.shared.user?.id})
            self.reactions[messageId]?.append(reaction)
        }
    }

    public func onDelete(_ response: ChatResponse<ReactionMessageResponse>) {
        if let reaction = response.result?.reaction, let messageId = response.result?.messageId {
            calculateReactionCount(messageId: messageId, reaction: reaction, type: .removeReaction)
            self.reactions[messageId]?.removeAll(where: {$0.id == reaction.id})
            selectedMessageReactionDetails?.reactions?.removeAll(where: { $0.id == reaction.id })
            if reaction.participant?.id == AppState.shared.user?.id {
                userSelectedReactions.removeValue(forKey: messageId)
            }
        }
    }

    public func onCurrentUserReaction(_ response: ChatResponse<CurrentUserReaction>) {
        if let reaction = response.result?.reactoin, let messageId = response.result?.messageId {
            userSelectedReactions[messageId] = reaction
            animateObjectWillChange()
        }
    }

    private func calculateReactionCount(messageId: Int, reaction: Reaction?, type: ChatMessageVOTypes) {
        switch type {
        case .removeReaction:
            removeReactionCount(messageId: messageId, reaction: reaction)
        case .addReaction:
            addReactionCount(messageId: messageId, reaction: reaction)
        case .replaceReaction:
            replaceReactionCount(messageId: messageId, reaction: reaction)
        default:
            break
        }
        NotificationCenter.default.post(name: .reactionMessageUpdated, object: messageId)
    }

    private func messageReactionCountListIndex(messageId: Int) -> Int? {
        reactionCountList.firstIndex(where: {$0.messageId == messageId})
    }

    private func itemIndex(messageId: Int, reactionSticker: Sticker?) -> Int? {
        reactionCountList.first(where: {$0.messageId == messageId})?.reactionCounts?.firstIndex(where: {$0.sticker == reactionSticker })
    }

    private func oldItemCount(messageId: Int, reaction: Reaction?) -> Int? {
        guard let index = itemIndex(messageId: messageId, reactionSticker: reaction?.reaction) else { return nil }
        return reactionCountList.first(where: {$0.messageId == messageId})?.reactionCounts?[index].count
    }

    private func addReactionCount(messageId: Int, reaction: Reaction?) {
        guard let messageCountIndex = messageReactionCountListIndex(messageId: messageId)
        else {
            reactionCountList.append(.init(messageId: messageId, reactionCounts: [.init(sticker: reaction?.reaction, count: 1)]))
            return
        }
        let oldCount = oldItemCount(messageId: messageId, reaction: reaction) ?? 0
        if let index = itemIndex(messageId: messageId, reactionSticker: reaction?.reaction) {
            reactionCountList[messageCountIndex].reactionCounts?[index].count = oldCount + 1
        } else {
            reactionCountList[messageCountIndex].reactionCounts?.append(.init(sticker: reaction?.reaction, count: 1))
        }
    }

    private func removeReactionCount(messageId: Int, reaction: Reaction?) {
        guard
            let messageCountIndex = messageReactionCountListIndex(messageId: messageId),
            let itemIndex = itemIndex(messageId: messageId, reactionSticker: reaction?.reaction),
            let oldCount = oldItemCount(messageId: messageId, reaction: reaction)
        else {
            return
        }
        reactionCountList[messageCountIndex].reactionCounts?[itemIndex].count = oldCount - 1
        if reactionCountList[messageCountIndex].reactionCounts?[itemIndex].count == 0 {
            reactionCountList[messageCountIndex].reactionCounts?.removeAll(where: {$0.sticker == reaction?.reaction})
        }
    }

    private func replaceReactionCount(messageId: Int, reaction: Reaction?) {
        if let selectedReaction = userSelectedReactions.first(where: {$0.key == messageId})?.value {
            removeReactionCount(messageId: messageId, reaction: selectedReaction)
        }
        addReactionCount(messageId: messageId, reaction: reaction)
    }

    public func clearLogs() {
        reactions.removeAll()
    }
}
