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
    private var cancelable: Set<AnyCancellable> = []
    public static let shared: ReactionViewModel = .init()
    var inMemoryReactions: InMemoryReactionProtocol? { ChatManager.activeInstance?.reaction.inMemoryReaction }
    
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
        let myReaction = inMemoryReactions?.currentReaction(messageId)
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
        case .inMemoryUpdate(let messageId):
            NotificationCenter.default.post(name: .reactionMessageUpdated, object: messageId)
        default:
            break
        }
    }

    public func getReactionSummary(_ messageIds: [Int], conversationId: Int) {
        ChatManager.activeInstance?.reaction.count(.init(messageIds: messageIds, conversationId: conversationId))
    }

    public func onCount(_ response: ChatResponse<[ReactionCountList]>) {
        response.result?.forEach{ item in
            NotificationCenter.default.post(name: .reactionMessageUpdated, object: item.messageId)
        }
    }

    public func getCurrentUserReaction(for messageId: Int, conversationId: Int) {
        ChatManager.activeInstance?.reaction.reaction(.init(messageId: messageId, conversationId: conversationId))
    }

    public func getDetail(for messageId: Int, offset: Int = 0, conversationId: Int, sticker: Sticker) {
        ChatManager.activeInstance?.reaction.get(.init(messageId: messageId,
                                                       offset: offset,
                                                       count: 25,
                                                       conversationId: conversationId,
                                                       sticker: sticker))
    }

    public func clear() {
        
    }
}
