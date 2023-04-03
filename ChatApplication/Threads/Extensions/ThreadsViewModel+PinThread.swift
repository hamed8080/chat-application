//
//  ThreadsViewModel+PinThread.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation

protocol PinThreadProtocol {
    func togglePin(_ thread: Conversation)
    func pin(_ threadId: Int)
    func unpin(_ threadId: Int)
    func onPinChanged(_ response: ChatResponse<Int>)
}

extension ThreadsViewModel: PinThreadProtocol {
    func togglePin(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        if thread.pin == false {
            pin(threadId)
        } else {
            unpin(threadId)
        }
    }

    func pin(_ threadId: Int) {
        ChatManager.activeInstance?.pinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    func unpin(_ threadId: Int) {
        ChatManager.activeInstance?.unpinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    func onPinChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil, let threadIndex = firstIndex(response.result) {
            threads[threadIndex].pin?.toggle()
            sort()
        }
    }
}
