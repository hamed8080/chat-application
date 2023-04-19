//
//  ThreadsViewModel+PinThread.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import ChatModels
import ChatCore

protocol PinThreadProtocol {
    func togglePin(_ thread: Conversation)
    func pin(_ threadId: Int)
    func unpin(_ threadId: Int)
    func onPinChanged(_ response: ChatResponse<Int>)
}

extension ThreadsViewModel: PinThreadProtocol {
    public func togglePin(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        if thread.pin == false {
            pin(threadId)
        } else {
            unpin(threadId)
        }
    }

    public func pin(_ threadId: Int) {
        ChatManager.activeInstance?.pinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    public func unpin(_ threadId: Int) {
        ChatManager.activeInstance?.unpinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    public func onPinChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil, let threadIndex = firstIndex(response.result) {
            threads[threadIndex].pin?.toggle()
            sort()
        }
    }
}
