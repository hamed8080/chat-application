//
//  ThreadViewModel+History.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import SwiftUI
import ChatDTO
import ChatCore
import ChatModels
import OSLog
import TalkModels

struct OnMoveTime: ChatDTO.UniqueIdProtocol {
    let uniqueId: String
    let messageId: Int
    let request: GetHistoryRequest
    let highlight: Bool

    init(messageId: Int, request: GetHistoryRequest, highlight: Bool) {
        self.messageId = messageId
        self.request = request
        self.highlight = highlight
        uniqueId = request.uniqueId
    }
}

extension ThreadViewModel {

    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    public func startFetchingHistory() {
        if threadId == LocalId.emptyThread.rawValue || isFetchedServerFirstResponse == true { return }
        if thread.lastSeenMessageId == thread.lastMessageVO?.id {
            moveToLastMessage()
        } else if thread.lastSeenMessageId ?? 0 < thread.lastMessageVO?.id ?? 0, let lastMessageSeenTime = thread.lastSeenMessageTime, let messageId = thread.lastSeenMessageId {
            moveToTime(lastMessageSeenTime, messageId, highlight: false)
        } else {
            /// If lastMessageDeleted it cause the view not render because lastSeenMessageId is ahead of real lastMessage
            moveToLastMessage()
        }
    }

    public func getHistory(_ toTime: UInt? = nil) {
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)
        RequestsManager.shared.append(prepend: "GET-HISTORY", value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    func onHistory(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "GET-HISTORY") != nil, let messages = response.result else { return }
        appendMessages(messages)
        if response.cache == false, isFetchedServerFirstResponse == false, let time = thread.lastSeenMessageTime, let lastSeenMessageId = thread.lastSeenMessageId {
            moveToTime(time, lastSeenMessageId, highlight: false)
        }
        if response.cache == false {
            isFetchedServerFirstResponse = true
            hasNextBottom = response.hasNext
        }
        animateObjectWillChange()
    }

    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true) {
        if moveToMessageLocally(messageId, highlight: highlight) { return }
        let toTimeReq = GetHistoryRequest(threadId: threadId, count: 25, offset: 0, order: "desc", toTime: time.advanced(by: 100), readOnly: readOnly)
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: 25, fromTime: time.advanced(by: 100), offset: 0, order: "desc", readOnly: readOnly)
        let timeReqManager = OnMoveTime(messageId: messageId, request: toTimeReq, highlight: highlight)
        let fromReqManager = OnMoveTime(messageId: messageId, request: fromTimeReq, highlight: highlight)
        RequestsManager.shared.append(prepend: "TO-TIME", value: timeReqManager)
        RequestsManager.shared.append(prepend: "FROM-TIME", value: fromReqManager)
        ChatManager.activeInstance?.message.history(toTimeReq)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            ChatManager.activeInstance?.message.history(fromTimeReq)
        }
    }

    func onMoveToTime(_ response: ChatResponse<[Message]>) {
        onMoveTime(response: response, key: "TO-TIME")
    }

    func onMoveFromTime(_ response: ChatResponse<[Message]>) {
        onMoveTime(response: response, key: "FROM-TIME")
    }

    func onMoveTime(response: ChatResponse<[Message]>, key: String) {
        guard !response.cache,
              let request = response.value(prepend: key) as? OnMoveTime,
              let messages = response.result
        else { return }
        isFetchedServerFirstResponse = true
        appendMessages(messages, isToTime: key.contains("TO-TIME"))
        self.disableScrolling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if !response.cache {
                self?.disableScrolling = false
                self?.animateObjectWillChange()
            }
        }
        withAnimation(.spring()) {
            if !response.cache {
                if key.contains("TO-TIME") {
                    hasNextTop = response.hasNext
                } else if key.contains("FROM-TIME") {
                    hasNextBottom = response.hasNext
                }
                isFetchedServerFirstResponse = true
                topLoading = false
            }
            if let indices = indicesByMessageId(request.messageId), let messageUniqueId = sections[indices.sectionIndex].messages[indices.messageIndex].uniqueId {
                showHighlighted(messageUniqueId, request.messageId, highlight: request.highlight)
            }
            objectWillChange.send()
        }
    }
    
    public func moveToLastMessage() {
        if bottomLoading { return }
        bottomLoading = true
        animateObjectWillChange()
        Logger.viewModels.info("moveToLastMessage called")
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: thread.lastSeenMessageTime?.advanced(by: 100), readOnly: readOnly)
        RequestsManager.shared.append(prepend: "LAST-MESSAGE-HISTORY", value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    public func onLastMessageHistory(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "LAST-MESSAGE-HISTORY") != nil, let messages = response.result
        else { return }
        appendMessages(messages)
        if !response.cache {
            isFetchedServerFirstResponse = true
            bottomLoading = false
        }
        animateObjectWillChange()
        /// If a message deleted from bottom of a history lastSeenMessageId is not exist in message response so we should move to lastMessageVO?.id
        let lastSeenUniqueId = messages.first(where: {$0.id == thread.lastSeenMessageId })?.uniqueId
        let lastMessageVOUniqueId = messages.first(where: {$0.id == thread.lastMessageVO?.id })?.uniqueId
        let computedLastUniqueId = lastSeenUniqueId ?? lastMessageVOUniqueId
        scrollTo(computedLastUniqueId ?? "")
    }

    public func moreTop(_ toTime: UInt?) {
        if !canLoadMoreTop { return }
        topLoading = true
        animateObjectWillChange()
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)
        RequestsManager.shared.append(prepend: "MORE-TOP", value: req)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self != nil {
                ChatManager.activeInstance?.message.history(req)
            }
        }
    }

    public func onMoreTop(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "MORE-TOP") != nil, let messages = response.result
        else { return }
        appendMessages(messages.sorted(by: {$0.time ?? 0 >= $1.time ?? 0}))
        self.disableScrolling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if !response.cache {
                self?.disableScrolling = false
                self?.animateObjectWillChange()
            }
        }
        withAnimation(.spring()) {
            if !response.cache {
                hasNextTop = response.hasNext
                isFetchedServerFirstResponse = true
                topLoading = false
            }
            scrollProxy?.scrollTo(lastVisibleUniqueId, anchor: .center)
            objectWillChange.send()
        }
    }

    public func moreBottom(_ fromTime: UInt?) {
        if !canLoadMoreBottom { return }
        bottomLoading = true
        animateObjectWillChange()
        let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "desc", readOnly: readOnly)
        RequestsManager.shared.append(prepend: "MORE-BOTTOM", value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    public func onMoreBottom(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "MORE-BOTTOM") != nil, let messages = response.result
        else { return }
        appendMessages(messages)
        self.disableScrolling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if !response.cache {
                self?.disableScrolling = false
                self?.animateObjectWillChange()
            }
        }
        withAnimation(.spring()) {
            if !response.cache {
                hasNextBottom = response.hasNext
                isFetchedServerFirstResponse = true
                bottomLoading = false
            }
            scrollProxy?.scrollTo(lastVisibleUniqueId, anchor: .center)
            objectWillChange.send()
        }
    }
}
