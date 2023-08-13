//
//  ThreadViewModel+Reaction.swift
//  Talk
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import UIKit
import ChatModels
import ChatAppExtensions
import ChatAppModels
import ChatDTO
import ChatCore
import OSLog

extension ThreadViewModel {

    public func getReaction(_ messageIds: [Int]) {
        var requestReactionIds: [Int] = []
        messageIds.forEach { id in
            if !ReactionViewModel.shared.reactions.keys.contains(id) {
                requestReactionIds.append(id)
            } else if let viewModel = messageViewModels.first(where: { $0.message.id == id }) {
                viewModel.onReactionList()
            }
        }
//        ChatManager.activeInstance?.reaction.get(.init(messageIds: requestReactionIds, conversationId: threadId))
    }

    public func getReactionDetail(_ messageId: Int) {
        ChatManager.activeInstance?.reaction.get(.init(messageId: messageId, conversationId: threadId))
    }
}
