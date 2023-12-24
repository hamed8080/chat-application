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

    public func togglePinMessage(_ message: Message, notifyAll: Bool) {
        guard let messageId = message.id else { return }
        if message.pinned == false || message.pinned == nil {
            pinMessage(messageId, notifyAll: notifyAll)
        } else {
            unpinMessage(messageId)
        }
    }
    
    public func pinMessage(_ messageId: Int, notifyAll: Bool) {
        ChatManager.activeInstance?.message.pin(.init(messageId: messageId, notifyAll: notifyAll))
    }

    func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.subjectId == threadId {
            thread.pinMessage = response.result
        }
    }

    public func unpinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.unpin(.init(messageId: messageId))
    }

    func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if response.subjectId == threadId {
            thread.pinMessage = nil
        }
    }
}
