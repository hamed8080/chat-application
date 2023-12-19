//
//  ThreadViewModel+ServerHistory.swift
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
        /// We check this to prevent recalling these methods when the view reappears again.
        /// If centerLoading is true it is mean theat the array has gotten clear for Scenario 6 to move to a time.
        let hasAnythingToLoadOnOpen = AppState.shared.appStateNavigationModel.moveToMessageId != nil
        moveToMessageTimeOnOpenConversation()
        if sections.count > 0 || centerLoading || hasAnythingToLoadOnOpen { return }
        hasSentHistoryRequest = true
        tryFirstScenario()
        trySecondScenario()
        trySeventhScenario()
        tryEightScenario()
    }

    public func moreTop(prepend: String = "MORE-TOP", delay: TimeInterval = 0.5, _ toTime: UInt?) {
        if !canLoadMoreTop { return }
        topLoading = true
        animateObjectWillChange()
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)
        RequestsManager.shared.append(prepend: prepend, value: req)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            if self != nil {
                ChatManager.activeInstance?.message.history(req)
            }
        }
    }

    public func onMoreTop(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "MORE-TOP") != nil,
              let messages = response.result,
              !response.cache
        else { return }
        /// 3- Append and sort the array but not call to update the view.
        appendMessagesAndSort(messages)
        /// 4- Disable excessive loading on the top part.
        disableExcessiveLoading()
        /// 5- Set whether it has more messages at the top or not.
        setHasMoreTop(response)
        /// 6- To update isLoading fields to hide the loading at the top.
        animateObjectWillChange()
    }

    public func moreBottom(prepend: String = "MORE-BOTTOM", _ fromTime: UInt?) {
        if !hasNextBottom || bottomLoading { return }
        bottomLoading = true
        animateObjectWillChange()
        let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: readOnly)
        RequestsManager.shared.append(prepend: prepend, value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    public func onMoreBottom(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "MORE-BOTTOM") != nil,
              let messages = response.result,
              !response.cache
        else { return }
        /// 3- Append and sort the array but not call to update the view.
        appendMessagesAndSort(messages)
        /// 4- Disable excessive loading on the top part.
        disableExcessiveLoading()
        /// 7- Set whether it has more messages at the bottom or not.
        setHasMoreBottom(response)
        /// 8- To update isLoading fields to hide the loading at the bottom.
        animateObjectWillChange()
    }

    func setHasMoreTop(_ response: ChatResponse<[Message]>) {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            topLoading = false
        }
    }

    func setHasMoreBottom(_ response: ChatResponse<[Message]>) {
        if !response.cache {
            hasNextBottom = response.hasNext
            isFetchedServerFirstResponse = true
            bottomLoading = false
        }
    }
}


/// Scenario 1
extension ThreadViewModel {

    func tryFirstScenario() {
        /// 1- Get the top part to time messages
        if thread.lastMessageVO?.id ?? 0 > thread.lastSeenMessageId ?? 0, let toTime = thread.lastSeenMessageTime {
            moreTop(prepend: "MORE-TOP-FIRST-SCENARIO", delay: TimeInterval(0), toTime.advanced(by: 1))
        }
    }

    public func onMoreTopFirstScenario(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "MORE-TOP-FIRST-SCENARIO") != nil,
              let messages = response.result,
              !response.cache
        else { return }
        /// 2- Append and sort the array but not call to update the view.
        appendMessagesAndSort(messages)
        /// 3- Append the unread message banner at the end of the array. It does not need to be sorted because it has been sorted by the above function.
        appenedUnreadMessagesBannerIfNeeed()
        /// 4- Disable excessive loading on the top part.
        disableExcessiveLoading()
        /// 6- Find the last Seen message ID in the list of messages section and use the unique ID to scroll to.
        if let lastSeenMessageId = thread.lastSeenMessageId, let indices = indicesByMessageId(lastSeenMessageId),
           let uniqueId = sections[indices.sectionIndex].messages[indices.messageIndex].uniqueId {
            showHighlighted(uniqueId, lastSeenMessageId, highlight: false)
            /// 9- Fetch from time messages to get to the bottom part and new messages to stay there if the user scrolls down.
            if let fromTime = sections[indices.sectionIndex].messages[indices.messageIndex].time {
                moreBottom(prepend: "MORE-BOTTOM-FIRST-SCENARIO", fromTime.advanced(by: -1))
            }
        }
        /// 7- Set whether it has more messages at the top or not.
        setHasMoreTop(response)
        /// 8- To update isLoading fields to hide the loading at the top.
        animateObjectWillChange()
    }

    public func onMoreBottomFirstScenario(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "MORE-BOTTOM-FIRST-SCENARIO") != nil,
              let messages = response.result,
              !response.cache
        else { return }
        /// 10- Append messages to the bottom part of the view and if the user scrolls down can see new messages.
        appendMessagesAndSort(messages)
        /// 11-  Set whether it has more messages at the bottom or not.
        setHasMoreBottom(response)
        /// 12- Update all the views to draw new messages for the bottom part and hide loading at the bottom.
        animateObjectWillChange()
    }

    func appenedUnreadMessagesBannerIfNeeed() {
        guard let lastSeenMessage = sections.last?.messages.last,
              let lastSeenMessageId = lastSeenMessage.id,
              let indices = indicesByMessageId(lastSeenMessageId)
        else { return }
        let time = (lastSeenMessage.time ?? 0) + 1
        let unreadMessage = UnreadMessage(id: LocalId.unreadMessageBanner.rawValue, time: time)
        sections[indices.sectionIndex].messages.append(unreadMessage)
    }
}

/// Scenario 2
extension ThreadViewModel {
    func trySecondScenario() {
        /// 1- Get the top part to time messages
        if thread.lastMessageVO?.id ?? 0 == thread.lastSeenMessageId ?? 0, let toTime = thread.lastSeenMessageTime {
            moreTop(prepend: "MORE-TOP-SECOND-SCENARIO", toTime.advanced(by: 1))
        }
    }

    public func onMoreTopSecondScenario(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "MORE-TOP-SECOND-SCENARIO") != nil,
              let messages = response.result,
              !response.cache
        else { return }
        if response.result?.count ?? 0 > 0 {
            /// 2- Append and sort the array but not call to update the view.
            appendMessagesAndSort(messages)
            /// 4- Disable excessive loading on the top part.
            disableExcessiveLoading()
        }
        if let uniqueId = thread.lastMessageVO?.uniqueId, let messageId = thread.lastMessageVO?.id {
            showHighlighted(uniqueId, messageId, highlight: false)
        }
        /// 5- Set whether it has more messages at the top or not.
        setHasMoreTop(response)
        /// 6- To update isLoading fields to hide the loading at the top.
        animateObjectWillChange()
    }
}

/// Scenario 3 or 4 more top/bottom.

/// Scenario 5
extension ThreadViewModel {
    func tryFifthScenario(status: ConnectionStatus) {
        /// 1- Get the bottom part of the list of what is inside the memory.
        if status == .connected,
           isFetchedServerFirstResponse == true,
           isActiveThread,
           let lastMessageInListTime = sections.last?.messages.last?.time {
            bottomLoading = true
            animateObjectWillChange()
            let fromTime = lastMessageInListTime.advanced(by: 1)
            let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: readOnly)
            RequestsManager.shared.append(prepend: "MORE-BOTTOM-FIFTH-SCENARIO", value: req)
            ChatManager.activeInstance?.message.history(req)
        }
    }

    public func onMoreBottomFifthScenario(_ response: ChatResponse<[Message]>) {
        guard response.value(prepend: "MORE-BOTTOM-FIFTH-SCENARIO") != nil,
              let messages = response.result,
              !response.cache
        else { return }
        /// 2- Append the unread message banner at the end of the array. It does not need to be sorted because it has been sorted by the above function.
        if response.result?.count ?? 0 > 0 {
            appenedUnreadMessagesBannerIfNeeed()
            /// 3- Append and sort the array but not call to update the view.
            appendMessagesAndSort(messages)
        }
        /// 4- Set whether it has more messages at the bottom or not.
        setHasMoreBottom(response)
        /// 5- To update isLoading fields to hide the loading at the bottom.
        animateObjectWillChange()
    }
}

/// Scenario 6
extension ThreadViewModel {
    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true) {
        /// 1- Move to a message locally if it exists.
        if moveToMessageLocally(messageId, highlight: highlight) { return }
        sections.removeAll()
        centerLoading = true
        animateObjectWillChange()
        /// 2- Fetch the top part of the message with the message itself.
        let toTimeReq = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: time.advanced(by: 1), readOnly: readOnly)
        let timeReqManager = OnMoveTime(messageId: messageId, request: toTimeReq, highlight: highlight)
        RequestsManager.shared.append(prepend: "TO-TIME", value: timeReqManager)
        ChatManager.activeInstance?.message.history(toTimeReq)
    }

    func onMoveToTime(_ response: ChatResponse<[Message]>) {
        guard let request = response.value(prepend: "TO-TIME") as? OnMoveTime,
              let messages = response.result
        else { return }
        /// 3- Append and sort the array but not call to update the view.
        appendMessagesAndSort(messages)
        centerLoading = false
        /// We set this property to true because in the seven scenario there is no way to set this property to true.
        /// 4- Disable excessive loading on the top part.
        disableExcessiveLoading()
        isFetchedServerFirstResponse = true
        /// 5- Update all the views to draw for the top part.
        animateObjectWillChange()
        /// 6- Scroll to the message with its uniqueId.
        guard
            let indices = indicesByMessageId(request.messageId),
            let uniqueId = sections[indices.sectionIndex].messages[indices.messageIndex].uniqueId
        else { return }
        showHighlighted(uniqueId, request.messageId, highlight: request.highlight)        
        /// 7- Fetch the From to time (bottom part) to have a little bit of messages from the bottom.
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: request.request.toTime?.advanced(by: -1), offset: 0, order: "asc", readOnly: readOnly)
        let fromReqManager = OnMoveTime(messageId: request.messageId, request: fromTimeReq, highlight: request.highlight)
        RequestsManager.shared.append(prepend: "FROM-TIME", value: fromReqManager)
        ChatManager.activeInstance?.message.history(fromTimeReq)
    }

    func onMoveFromTime(_ response: ChatResponse<[Message]>) {
        guard
            response.value(prepend: "FROM-TIME") != nil,
            let messages = response.result
        else { return }
        let sortedMessages = messages.sorted(by: {$0.time ?? 0 < $1.time ?? 0})
        /// 8- Append and sort the array but not call to update the view.
        appendMessagesAndSort(sortedMessages)
        setHasMoreBottom(response)
        /// 9- Update all the views to draw for the bottom part.
        animateObjectWillChange()
    }

    func moreBottomMoveTo(_ message: Message) {
        /// 12- Fetch the next part of the bottom when the user scrolls to the bottom part of move to.
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: message.time, offset: 0, order: "asc", readOnly: readOnly)
        let fromReqManager = OnMoveTime(messageId: message.id ?? 0, request: fromTimeReq, highlight: false)
        RequestsManager.shared.append(prepend: "FROM-TIME", value: fromReqManager)
        ChatManager.activeInstance?.message.history(fromTimeReq)
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    func moveToMessageLocally(_ messageId: Int, highlight: Bool) -> Bool {
        if let indices = indicesByMessageId(messageId), let uniqueId = sections[indices.sectionIndex].messages[indices.messageIndex].uniqueId {
            showHighlighted(uniqueId, messageId, highlight: highlight)
            return true
        }
        return false
    }
}

/// Scenario 7 = When lastMessgeSeenId is bigger than thread.lastMessageVO.id as a result of server chat bug.
extension ThreadViewModel {
    func trySeventhScenario() {
        if thread.lastMessageVO?.id ?? 0 < thread.lastSeenMessageId ?? 0 {
            moveToTime(thread.lastMessageVO?.time ?? 0, thread.lastMessageVO?.id ?? 0, highlight: false)
        }
    }
}

/// Scenario 8 = When a new thread has been built and me is added by another person and this is our first time to visit the thread.
extension ThreadViewModel {
    func tryEightScenario() {
        if thread.lastSeenMessageId == 0, thread.lastSeenMessageTime == nil, let lastMSGId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            moveToTime(time, lastMSGId, highlight: false)
        }
    }
}

public extension ThreadViewModel {
    func moveToFirstUnreadMessage() {
        if let unreadMessage = unreadMentionsViewModel.unreadMentions.first, let time = unreadMessage.time {
            moveToTime(time, unreadMessage.id ?? -1, highlight: true)
            unreadMentionsViewModel.setAsRead(id: unreadMessage.id)
            if unreadMentionsViewModel.unreadMentions.count == 0 {
                thread.mentioned = false
                thread.animateObjectWillChange()
                animateObjectWillChange()
            }
        }
    }
}

public extension ThreadViewModel {
    func moveToMessageTimeOnOpenConversation() {
        if let moveToMessageId = AppState.shared.appStateNavigationModel.moveToMessageId, let moveToMessageTime = AppState.shared.appStateNavigationModel.moveToMessageTime {
            moveToTime(moveToMessageTime, moveToMessageId, highlight: true)
            AppState.shared.appStateNavigationModel = .init()
        }
    }
}
