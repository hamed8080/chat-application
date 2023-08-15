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

    public func onReaction(_ event: ReactionEventTypes) {
        switch event {
        case .count(let chatResponse):
            onCount(chatResponse)
        case .list(let chatResponse):
            onDetail(chatResponse)
        case .add(let chatResponse):
            onAdd(chatResponse)
        case .reaplce(let chatResponse):
            onReplace(chatResponse)
        case .delete(let chatResponse):
            onDelete(chatResponse)
        }
    }

    public func onCount(_ response: ChatResponse<[ReactionCountList]>) {
        response.result?.forEach{ item in
            if let index = reactionCountList.firstIndex(where: {$0.messageId == item.messageId}) {
                reactionCountList[index] = item
            } else {
                self.reactionCountList.append(item)
            }
        }

        if response.result?.count ?? 0 > 0 {
            animateObjectWillChange()
        }
    }

    public func getDetail(for messageId: Int, offset: Int = 0, conversationId: Int) {
        ChatManager.activeInstance?.reaction.get(.init(messageId: messageId, offset: offset, count: 25, conversationId: conversationId))
    }

    public func onDetail(_ response: ChatResponse<ReactionList>) {
        selectedMessageReactionDetails = response.result
        animateObjectWillChange()
    }

    public func onAdd(_ response: ChatResponse<ReactionMessageResponse>) {
        if let messageId = response.result?.messageId, let reaction = response.result?.reactoin {
            self.reactions[messageId]?.append(reaction)
        }
    }

    public func onReplace(_ response: ChatResponse<ReactionMessageResponse>) {
        if let messageId = response.result?.messageId, let reaction = response.result?.reactoin {
            self.reactions[messageId]?.removeAll(where: {$0.participant?.id == AppState.shared.user?.id})
            self.reactions[messageId]?.append(reaction)
        }
    }

    public func onDelete(_ response: ChatResponse<ReactionMessageResponse>) {
        if let reactionId = response.result?.reactoin?.id, let messageId = response.result?.messageId {
            self.reactions[messageId]?.removeAll(where: {$0.id == reactionId})
            selectedMessageReactionDetails?.reactions?.removeAll(where: { $0.id == reactionId })
            animateObjectWillChange()
        }
    }

    public func clearLogs() {
        reactions.removeAll()
    }
}
