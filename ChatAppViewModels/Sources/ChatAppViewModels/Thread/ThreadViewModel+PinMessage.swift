//
//  ThreadViewModel+PinMessage.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import ChatCore
import ChatModels

extension ThreadViewModel {
    public func pinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.pin(.init(messageId: messageId))
    }

    func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if let message = response.result, let messageId = message.id {
            if let index = messageIndex(messageId) {
                messages[index].pinned = true
            }
            thread?.pinMessage = message
            animatableObjectWillChange()
        }
    }

    public func unpinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.unpin(.init(messageId: messageId))
    }

    func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.id {
            if let index = messageIndex(messageId) {
                messages[index].pinned = false
            }
            thread?.pinMessage = nil
            animatableObjectWillChange()
        }
    }
}
