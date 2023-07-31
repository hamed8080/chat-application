//
//  ThreadViewModel+History.swift
//  ChatApplication
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

extension ThreadViewModel {

    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    public func startFetchingHistory() {
        if isFetchedServerFirstResponse == true { return }
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
        let key = "GET_HISTORY-\(req.uniqueId)"
        requests[key] = req
        addCancelTimer(key: key)
        ChatManager.activeInstance?.message.history(req)
    }

    func onHistory(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId, requests["GET_HISTORY-\(uniqueId)"] != nil, let messages = response.result else { return }
        appendMessages(messages)
        if response.cache == false, isFetchedServerFirstResponse == false, let time = thread.lastSeenMessageTime, let lastSeenMessageId = thread.lastSeenMessageId {
            moveToTime(time, lastSeenMessageId, highlight: false)
        }
        if response.cache == false {
            isFetchedServerFirstResponse = true
            hasNextBottom = response.hasNext
            requests.removeValue(forKey: "GET_HISTORY-\(uniqueId)")
        }
        withAnimation {
            self.objectWillChange.send()
        }
    }

    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true) {
        if moveToMessageLocally(messageId, highlight: highlight) { return }
        let toTimeReq = GetHistoryRequest(threadId: threadId, count: 25, offset: 0, order: "desc", toTime: time.advanced(by: 100), readOnly: readOnly)
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: 25, fromTime: time.advanced(by: 100), offset: 0, order: "desc", readOnly: readOnly)
        let toTimeKey = "TO_TIME-\(toTimeReq.uniqueId)"
        let fromTimeKey = "FROM_TIME-\(fromTimeReq.uniqueId)"
        requests[toTimeKey] = (toTimeReq, messageId, highlight)
        requests[fromTimeKey] = (fromTimeReq, messageId, highlight)
        addCancelTimer(key: toTimeKey)
        ChatManager.activeInstance?.message.history(toTimeReq)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){ [weak self] in
            ChatManager.activeInstance?.message.history(fromTimeReq)
            self?.addCancelTimer(key: fromTimeKey)
        }
    }

    func onMoveToTime(_ response: ChatResponse<[Message]>) {
        onMoveTime(response: response, key: "TO_TIME")
    }

    func onMoveFromTime(_ response: ChatResponse<[Message]>) {
        onMoveTime(response: response, key: "FROM_TIME")
    }

    func onMoveTime(response: ChatResponse<[Message]>, key: String) {
        guard !response.cache,
              let uniqueId = response.uniqueId,
              let messages = response.result,
              let tuple = requests["\(key)-\(uniqueId)"] as? (request: GetHistoryRequest, messageId: Int, highlight: Bool)
        else { return }
        isFetchedServerFirstResponse = true
        appendMessages(messages, isToTime: key == "TO_TIME")
        self.disableScrolling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if !response.cache {
                self?.disableScrolling = false
                self?.objectWillChange.send()
            }
        }
        withAnimation(.spring()) {
            if !response.cache {
                hasNextTop = response.hasNext
                isFetchedServerFirstResponse = true
                requests.removeValue(forKey: "\(key)-\(uniqueId)")
                topLoading = false
            }
            if let indices = indicesByMessageId(tuple.messageId), let messageUniqueId = sections[indices.sectionIndex].messages[indices.messageIndex].uniqueId {
                showHighlighted(messageUniqueId, tuple.messageId, highlight: tuple.highlight)
            }
            objectWillChange.send()
        }
    }
    
    public func moveToLastMessage() {
        if bottomLoading { return }
        bottomLoading = true
        animatableObjectWillChange()
        Logger.viewModels.info("moveToLastMessage called")
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: thread.lastSeenMessageTime?.advanced(by: 100), readOnly: readOnly)
        let key = "LAST_MESSAGE_HISTORY-\(req.uniqueId)"
        requests[key] = req
        ChatManager.activeInstance?.message.history(req)
        addCancelTimer(key: key)
    }

    public func onLastMessageHistory(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId, requests["LAST_MESSAGE_HISTORY-\(uniqueId)"] != nil, let messages = response.result
        else { return }
        appendMessages(messages)
        if !response.cache {
            isFetchedServerFirstResponse = true
            bottomLoading = false
            requests.removeValue(forKey: "LAST_MESSAGE_HISTORY-\(uniqueId)")
        }
        /// If a message deleted from bottom of a history lastSeenMessageId is not exist in message response so we should move to lastMessageVO?.id
        let lastSeenUniqueId = messages.first(where: {$0.id == thread.lastSeenMessageId })?.uniqueId
        let lastMessageVOUniqueId = messages.first(where: {$0.id == thread.lastMessageVO?.id })?.uniqueId
        let computedLastUniqueId = lastSeenUniqueId ?? lastMessageVOUniqueId
        scrollTo(computedLastUniqueId ?? "")
    }

    public func moreTop(_ toTime: UInt?) {
        if !canLoadMoreTop { return }
        withAnimation {
            topLoading = true
        }
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)
        let key = "MORE_TOP-\(req.uniqueId)"
        requests[key] = (req, sections.first?.messages.first?.uniqueId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self != nil {
                ChatManager.activeInstance?.message.history(req)
            }
        }
        addCancelTimer(key: key)
    }

    public func onMoreTop(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId,
              let request = requests["MORE_TOP-\(uniqueId)"] as? (req: GetHistoryRequest, lastVisibleUniqueId: String?),
              let messages = response.result
        else { return }
        appendMessages(messages.sorted(by: {$0.time ?? 0 >= $1.time ?? 0}))
        self.disableScrolling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if !response.cache {
                self?.disableScrolling = false
                self?.objectWillChange.send()
            }
        }
        withAnimation(.spring()) {
            if !response.cache {
                hasNextTop = response.hasNext
                isFetchedServerFirstResponse = true
                requests.removeValue(forKey: "MORE_TOP-\(uniqueId)")
                topLoading = false
            }
            scrollProxy?.scrollTo(request.lastVisibleUniqueId, anchor: .center)
            objectWillChange.send()
        }
    }

    public func moreBottom(_ fromTime: UInt?) {
        if !canLoadMoreBottom { return }
        withAnimation {
            bottomLoading = true
        }
        let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "desc", readOnly: readOnly)
        let key = "MORE_BOTTOM-\(req.uniqueId)"
        requests[key] = (req, lastVisibleUniqueId)
        ChatManager.activeInstance?.message.history(req)
        addCancelTimer(key: key)
    }

    public func onMoreBottom(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId,
              let request = requests["MORE_BOTTOM-\(uniqueId)"] as? (req: GetHistoryRequest, lastVisibleUniqueId: String?),
              let messages = response.result
        else { return }
        appendMessages(messages)
        self.disableScrolling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if !response.cache {
                self?.disableScrolling = false
                self?.objectWillChange.send()
            }
        }
        withAnimation(.spring()) {
            if !response.cache {
                hasNextBottom = response.hasNext
                isFetchedServerFirstResponse = true
                requests.removeValue(forKey: "MORE_BOTTOM-\(uniqueId)")
                bottomLoading = false
            }
            scrollProxy?.scrollTo(request.lastVisibleUniqueId, anchor: .center)
            objectWillChange.send()
        }
    }
}
