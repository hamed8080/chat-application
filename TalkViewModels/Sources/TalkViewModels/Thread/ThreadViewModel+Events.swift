//
//  ThreadViewModel+Events.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat

extension ThreadViewModel {
    public func onChatEvent(_ event: ChatEventType) {
        switch event {
        case .message(let messageEventTypes):
            onMessageEvent(messageEventTypes)
        case .thread(let threadEventTypes):
            onThreadEvent(threadEventTypes)
        default:
            break
        }
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .lastMessageDeleted(let response), .lastMessageEdited(let response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }
        case .updatedUnreadCount(let response):
            onUnreadCount(response)
        case .created(let response):
            onCreateP2PThread(response)
        case .deleted(let response):
            onDeleteThread(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        default:
            break
        }
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .new(let response):
            onNewMessage(response)
        case .edited(let response):
            onEditedMessage(response)
        default:
            break
        }
    }
}
