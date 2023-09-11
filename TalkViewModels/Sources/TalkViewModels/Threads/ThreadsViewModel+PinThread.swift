//
//  ThreadsViewModel+PinThread.swift
//  TalkViewModels
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
    func onPin(_ response: ChatResponse<Conversation>)
    func onUNPin(_ response: ChatResponse<Conversation>)
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
        ChatManager.activeInstance?.conversation.pin(.init(subjectId: threadId))
    }

    public func unpin(_ threadId: Int) {
        ChatManager.activeInstance?.conversation.unpin(.init(subjectId: threadId))
    }

    public func onPin(_ response: ChatResponse<Conversation>) {
        if response.result != nil, let threadIndex = firstIndex(response.result?.id) {
            threads[threadIndex].pin?.toggle()
            sort()
        }
    }

    public func onUNPin(_ response: ChatResponse<Conversation>) {
        if response.result != nil, let threadIndex = firstIndex(response.result?.id) {
            threads[threadIndex].pin?.toggle()
            sort()
        }
    }
}
