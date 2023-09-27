//
//  ThreadsViewModel+Events.swift
//  TalkViewModels
//
//  Created by hamed on 11/24/22.
//

import Foundation
import ChatCore
import Chat
import ChatModels

extension ThreadsViewModel {
    func onChatEvent(_ event: ChatEventType) {
        switch event {
        case .message(let messageEventTypes):
            onMessageEvent(messageEventTypes)
        case .thread(let threadEventTypes):
            onThreadEvent(threadEventTypes)
        case .call(let callEventTypes):
            onCallEvent(callEventTypes)
        default:
            break
        }
    }

    private func onParticipantEvent(_ event: ParticipantEventTypes) {
        switch event {
        case .add(let chatResponse):
            onAddPrticipant(chatResponse)
        case .deleted(let chatResponse):
            onDeletePrticipant(chatResponse)
        default:
            break
        }
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {

        switch event {
        case .threads(let response):
            onThreads(response)
            onPublicThreadSearch(response)
            onSearch(response)
        case .created(let response):
            onCreate(response)
        case .deleted(let response):
            onDeleteThread(response)
        case let .lastMessageDeleted(response), let .lastMessageEdited(response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }
        case .updatedInfo(let response):
            if let thread = response.result {
                updateThreadInfo(thread)
            }
        case .updatedUnreadCount(let response):
            if let index = firstIndex(response.result?.threadId) {
                threads[index].unreadCount = response.result?.unreadCount
                animateObjectWillChange()
            }
        case .mute(let response):
            onMuteThreadChanged(mute: true, threadId: response.result)
        case .unmute(let response):
            onMuteThreadChanged(mute: false, threadId: response.result)
        case .archive(let response):
            onArchive(response)
        case .unArchive(let response):
            onUNArchive(response)
        case .changedType(let response):
            onChangedType(response)
        case .spammed(let response):
            onSpam(response)
        case .unreadCount(let response):
            onUnreadCounts(response)
        case .pin(let response):
            onPin(response)
        case .unpin(let response):
            onUNPin(response)
        case .userRemoveFormThread(let response):
            onUserRemovedByAdmin(response)
        case .lastSeenMessageUpdated(let response):
            onLastSeenMessageUpdated(response)
        case .joined(let response):
            onJoinedToPublicConversatin(response)
        default:
            break
        }
    }

    private func onCallEvent(_ event: CallEventTypes) {
        switch event {
        case let .callEnded(response):
            activeCallThreads.removeAll(where: { $0.callId == response?.result })
        case let .groupCallCanceled(response):
            activeCallThreads.append(.init(threadId: response.subjectId ?? -1, callId: response.result?.callId ?? -1))
        case let .callReceived(response):
            activeCallThreads.append(.init(threadId: response.result?.conversation?.id ?? -1, callId: response.result?.callId ?? -1))
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case .new(let chatResponse):
            onNewMessage(chatResponse)
        case .cleared(let chatResponse):
            onClear(chatResponse)
        default:
            break
        }
    }
}
