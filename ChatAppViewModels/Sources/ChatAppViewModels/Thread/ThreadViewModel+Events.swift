//
//  ThreadViewModel+Events.swift
//  ChatApplication
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
        case .participant(let participantEventTypes):
            onParticipantEvent(participantEventTypes)
        default:
            break
        }
    }

    public func onParticipantEvent(_ event: ParticipantEventTypes?) {
        switch event {
        case .participants(let response):
            onMentionParticipants(response)
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
        case .lastSeenMessageUpdated(let response):
            onLastSeenMessageUpdated(response)
        case .created(let response):
            onCreateP2PThread(response)
        default:
            break
        }
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            onLastMessageHistory(response)
            onHistory(response)
            onSearch(response)
            onMoveToTime(response)
            onMoveFromTime(response)
            onMoreTop(response)
            onMoreBottom(response)
            break
        case .queueTextMessages(let response):
            onQueueTextMessages(response)
        case .queueEditMessages(let response):
            onQueueEditMessages(response)
        case .queueForwardMessages(let response):
            onQueueForwardMessages(response)
        case .queueFileMessages(let response):
            onQueueFileMessages(response)
        case .new(let response):
            onNewMessage(response)
        case .sent(let response):
            onSent(response)
        case .delivered(let response):
            onDeliver(response)
        case .seen(let response):
            onSeen(response)
        case .deleted(let response):
            onDeleteMessage(response)
        case .pin(let response):
            onPinMessage(response)
        case .unpin(let response):
            onUNPinMessage(response)
        case .edited(let response):
            onEditedMessage(response)
        default:
            break
        }
    }
}
