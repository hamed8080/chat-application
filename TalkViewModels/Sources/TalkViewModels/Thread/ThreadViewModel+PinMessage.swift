//
//  ThreadViewModel+PinMessage.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import ChatCore
import ChatModels

extension ThreadViewModel {

    public func togglePinMessage(_ message: Message) {
        guard let messageId = message.id else { return }
        if message.pinned == false || message.pinned == nil {
            pinMessage(messageId)
        } else {
            unpinMessage(messageId)
        }
    }
    
    public func pinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.pin(.init(messageId: messageId))
    }

    func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.id, let indices = indicesByMessageId(messageId) {
            sections[indices.sectionIndex].messages[indices.messageIndex].pinned = true
            thread.pinMessage = response.result
        }
    }

    public func unpinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.unpin(.init(messageId: messageId))
    }

    func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.id, let indices = indicesByMessageId(messageId)   {
            sections[indices.sectionIndex].messages[indices.messageIndex].pinned = false
            thread.pinMessage = nil
        }
    }
}
