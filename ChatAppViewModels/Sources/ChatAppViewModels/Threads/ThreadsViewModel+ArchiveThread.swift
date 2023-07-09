//
//  ThreadsViewModel+ArchiveThread.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import ChatModels
import ChatCore

protocol ArchiveThreadProtocol {
    func toggleArchive(_ thread: Conversation)
    func archive(_ threadId: Int)
    func unarchive(_ threadId: Int)
    func onArchive(_ response: ChatResponse<Int>)
    func onUNArchive(_ response: ChatResponse<Int>)
}

extension ThreadsViewModel: ArchiveThreadProtocol {
    public func toggleArchive(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        if thread.isArchive == false {
            archive(threadId)
        } else {
            unarchive(threadId)
        }
    }

    public func archive(_ threadId: Int) {
        ChatManager.activeInstance?.conversation.archive(.init(subjectId: threadId))
    }

    public func unarchive(_ threadId: Int) {
        ChatManager.activeInstance?.conversation.unarchive(.init(subjectId: threadId))
    }

    public func onArchive(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil, let threadIndex = firstIndex(response.result) {
            threads[threadIndex].isArchive = true
            sort()
        }
    }

    public func onUNArchive(_ response: ChatResponse<Int>) {
        if response.result != nil, response.error == nil, let threadIndex = firstIndex(response.result) {
            threads[threadIndex].isArchive = false
            sort()
        }
    }
}
