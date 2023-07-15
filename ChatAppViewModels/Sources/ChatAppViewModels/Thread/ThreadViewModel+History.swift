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
        requests["GET_HISTORY-\(req.uniqueId)"] = req
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
        requests["TO_TIME-\(toTimeReq.uniqueId)"] = (toTimeReq, messageId, highlight)
        requests["FROM_TIME-\(fromTimeReq.uniqueId)"] = (fromTimeReq, messageId, highlight)
        ChatManager.activeInstance?.message.history(toTimeReq)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            ChatManager.activeInstance?.message.history(fromTimeReq)
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
        objectWillChange.send()
        if let messageIdUniqueId = self.messages.first(where: {$0.id == tuple.messageId})?.uniqueId {
            showHighlighted(messageIdUniqueId, tuple.messageId, highlight: tuple.highlight)
        }
        requests.removeValue(forKey: "\(key)-\(uniqueId)")
    }
    
    public func moveToLastMessage() {
        if bottomLoading { return }
        bottomLoading = true
        animatableObjectWillChange()
        print("moveToLastMessage called")
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: thread.lastSeenMessageTime?.advanced(by: 100), readOnly: readOnly)
        requests["LAST_MESSAGE_HISTORY-\(req.uniqueId)"] = req
        ChatManager.activeInstance?.message.history(req)
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
        print("moreTop called")
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)
        requests["MORE_TOP-\(req.uniqueId)"] = (req, lastVisibleUniqueId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ChatManager.activeInstance?.message.history(req)
        }
    }

    public func onMoreTop(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId,
              let request = requests["MORE_TOP-\(uniqueId)"] as? (req: GetHistoryRequest, lastVisibleUniqueId: String?),
              let messages = response.result
        else { return }
        let beforeTopUniqueId = self.messages.first?.uniqueId
        messages.sorted(by: {$0.time ?? 0 >= $1.time ?? 0}).forEach { message in
            self.messages.insert(message, at: 0)
        }


        self.disableScrolling = true
        self.objectWillChange.send()
        let firstId = abs(oldTopItemId) + 1
        let endId = firstId + 25
        let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: oldTopItem?.date ?? .now)!
        let messages: [Message] = (firstId...endId).map({.init(id: -$0, text: "Text-\(-$0)", date: previousDate)})
        self.sections.insert(.init(date: previousDate, messages: messages.sorted(by: {$0.id < $1.id})), at: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation {
                self.disableScrolling = false
                self.scrollProxy?.scrollTo(oldTopItemId, anchor: .top)
                self.isLoading = false
                self.objectWillChange.send()
            }
        }


        self.messages.insert(contentsOf: messages.sorted(by: {$0.time ?? 0 >= $1.time ?? 0}), at: 0)
//        appendMessages(messages)
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            topLoading = false
            requests.removeValue(forKey: "MORE_TOP-\(uniqueId)")
        }
//        animatableObjectWillChange()
        scrollProxy?.scrollTo(beforeTopUniqueId, anchor: .top)
        objectWillChange.send()

//        scrollTo(request.lastVisibleUniqueId ?? "", anchor: .top)
    }

    public func moreBottom(_ fromTime: UInt?) {
        if !canLoadMoreBottom { return }
        withAnimation {
            bottomLoading = true
        }
        print("moreBottom called")
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: fromTime, readOnly: readOnly)
        requests["MORE_BOTTOM-\(req.uniqueId)"] = (req, lastVisibleUniqueId)
        ChatManager.activeInstance?.message.history(req)
    }

    public func onMoreBottom(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId,
              let request = requests["MORE_BOTTOM-\(uniqueId)"] as? (req: GetHistoryRequest, lastVisibleUniqueId: String?),
              let messages = response.result
        else { return }
        appendMessages(messages)
        if !response.cache {
            isFetchedServerFirstResponse = true
            bottomLoading = false
            requests.removeValue(forKey: "MORE_BOTTOM-\(uniqueId)")
        }
        objectWillChange.send()
        scrollTo(request.lastVisibleUniqueId ?? "", anchor: .bottom)
    }
}
