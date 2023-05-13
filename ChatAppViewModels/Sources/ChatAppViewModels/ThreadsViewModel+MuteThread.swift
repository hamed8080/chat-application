//
//  ThreadsViewModel+MuteThread.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import ChatCore
import ChatModels

protocol MuteThreadProtocol {
    func toggleMute(_ thread: Conversation)
    func mute(_ threadId: Int)
    func unmute(_ threadId: Int)
    func onMuteChanged(_ response: ChatResponse<Int>)
}

extension ThreadsViewModel: MuteThreadProtocol {
    public func toggleMute(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        if thread.mute ?? false == false {
            mute(threadId)
        } else {
            unmute(threadId)
        }
    }

    public func mute(_ threadId: Int) {
        ChatManager.activeInstance?.muteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    public func unmute(_ threadId: Int) {
        ChatManager.activeInstance?.unmuteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    public func onMuteChanged(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil, let threadIndex = firstIndex(response.result) {
            threads[threadIndex].mute?.toggle()
            sort()
        }
    }
}
