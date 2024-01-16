//
//  ThreadViewModel+Events.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat

extension ThreadViewModel {

    func registerNotifications() {
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)

        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)
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
