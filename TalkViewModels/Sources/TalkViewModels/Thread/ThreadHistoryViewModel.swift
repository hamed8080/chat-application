//
//  ThreadHistoryViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Foundation
import Chat
import SwiftUI
import ChatDTO
import ChatCore
import ChatModels
import OSLog
import TalkModels
import Combine

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

public final class ThreadHistoryViewModel: ObservableObject {
    public var sections: ContiguousArray<MessageSection> = .init()
    public var hasNextTop = true
    public var hasNextBottom = true
    public let count: Int = 50
    private let thresholdToLoad = 40
    public var topLoading = false
    public var bottomLoading = false
    public var canLoadMoreTop: Bool { hasNextTop && !topLoading }
    public var canLoadMoreBottom: Bool { !bottomLoading && sections.last?.messages.last?.id != thread.lastMessageVO?.id && hasNextBottom }
    private var topSliceId: Int = 0
    private var bottomSliceId: Int = 0
    public var lastTopVisibleMessage: Message?
    public var messageViewModels: ContiguousArray<MessageRowViewModel> = .init()
    public var isFetchedServerFirstResponse: Bool = false
    private var cancelable: Set<AnyCancellable> = []
    public weak var threadViewModel: ThreadViewModel!
    private var thread: Conversation { threadViewModel!.thread }
    private var threadId: Int { thread.id ?? -1 }
    var hasSentHistoryRequest = false

    public init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
        RequestsManager.shared.$cancelRequest
            .sink { [weak self] newValue in
                if let newValue {
                    self?.onCancelTimer(key: newValue)
                }
            }
            .store(in: &cancelable)
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if status == .connected, isFetchedServerFirstResponse == true, threadViewModel.isActiveThread {
            // After connecting again get latest messages.
            tryFifthScenario(status: status)
        }

        /// Fetch the history for the first time if the internet connection is not available.
        if status == .connected, hasSentHistoryRequest == true, sections.isEmpty {
            startFetchingHistory()
        }
    }

    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    public func startFetchingHistory() {
        /// We check this to prevent recalling these methods when the view reappears again.
        /// If centerLoading is true it is mean theat the array has gotten clear for Scenario 6 to move to a time.
        let hasAnythingToLoadOnOpen = AppState.shared.appStateNavigationModel.moveToMessageId != nil
        moveToMessageTimeOnOpenConversation()
        if sections.count > 0 || threadViewModel.centerLoading || hasAnythingToLoadOnOpen { return }
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
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: threadViewModel.readOnly)
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
        threadViewModel.scrollVM.disableExcessiveLoading()
        /// 5- Set whether it has more messages at the top or not.
        setHasMoreTop(response)
        /// 6- To update isLoading fields to hide the loading at the top.
        animateObjectWillChange()

        if let uniqueId = lastTopVisibleMessage?.uniqueId, let id = lastTopVisibleMessage?.id {
            threadViewModel.scrollVM.showHighlighted(uniqueId, id, highlight: false, anchor: .top)
            lastTopVisibleMessage = nil
        }
    }

    public func moreBottom(prepend: String = "MORE-BOTTOM", _ fromTime: UInt?) {
        if !hasNextBottom || bottomLoading { return }
        bottomLoading = true
        animateObjectWillChange()
        let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: threadViewModel.readOnly)
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
        threadViewModel.scrollVM.disableExcessiveLoading()
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

    /// Scenario 1
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
        threadViewModel.scrollVM.disableExcessiveLoading()
        /// 6- Find the last Seen message ID in the list of messages section and use the unique ID to scroll to.
        let lastSeenMessage = message(for: thread.lastSeenMessageId)?.message
        if let uniqueId = lastSeenMessage?.uniqueId, let lastSeenMessageId = lastSeenMessage?.id {
            threadViewModel.scrollVM.showHighlighted(uniqueId, lastSeenMessageId, highlight: false)
            /// 9- Fetch from time messages to get to the bottom part and new messages to stay there if the user scrolls down.
            if let fromTime = lastSeenMessage?.time {
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
        guard
            let tuples = message(for: sections.last?.messages.last?.id)
        else { return }
        let time = (tuples.message.time ?? 0) + 1
        let unreadMessage = UnreadMessage(id: LocalId.unreadMessageBanner.rawValue, time: time)
        sections[tuples.sectionIndex].messages.append(unreadMessage)
    }

    /// Scenario 2
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
            threadViewModel.scrollVM.disableExcessiveLoading()
        }
        if let uniqueId = thread.lastMessageVO?.uniqueId, let messageId = thread.lastMessageVO?.id {
            threadViewModel.scrollVM.showHighlighted(uniqueId, messageId, highlight: false)
        }
        /// 5- Set whether it has more messages at the top or not.
        setHasMoreTop(response)
        /// 6- To update isLoading fields to hide the loading at the top.
        animateObjectWillChange()
    }

    /// Scenario 3 or 4 more top/bottom.

    /// Scenario 5
    func tryFifthScenario(status: ConnectionStatus) {
        /// 1- Get the bottom part of the list of what is inside the memory.
        if status == .connected,
           isFetchedServerFirstResponse == true,
           threadViewModel.isActiveThread,
           let lastMessageInListTime = sections.last?.messages.last?.time {
            bottomLoading = true
            animateObjectWillChange()
            let fromTime = lastMessageInListTime.advanced(by: 1)
            let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: threadViewModel.readOnly)
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

    /// Scenario 6
    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true) {
        /// 1- Move to a message locally if it exists.
        if moveToMessageLocally(messageId, highlight: highlight) { return }
        sections.removeAll()
        threadViewModel.centerLoading = true
        threadViewModel.animateObjectWillChange()
        /// 2- Fetch the top part of the message with the message itself.
        let toTimeReq = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: time.advanced(by: 1), readOnly: threadViewModel.readOnly)
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
        threadViewModel.centerLoading = false
        threadViewModel.animateObjectWillChange()
        /// We set this property to true because in the seven scenario there is no way to set this property to true.
        /// 4- Disable excessive loading on the top part.
        threadViewModel.scrollVM.disableExcessiveLoading()
        isFetchedServerFirstResponse = true
        /// 5- Update all the views to draw for the top part.
        animateObjectWillChange()
        /// 6- Scroll to the message with its uniqueId.
        guard let uniqueId = message(for: request.messageId)?.message.uniqueId else { return }
        threadViewModel.scrollVM.showHighlighted(uniqueId, request.messageId, highlight: request.highlight)
        /// 7- Fetch the From to time (bottom part) to have a little bit of messages from the bottom.
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: request.request.toTime?.advanced(by: -1), offset: 0, order: "asc", readOnly: threadViewModel.readOnly)
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
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: message.time, offset: 0, order: "asc", readOnly: threadViewModel.readOnly)
        let fromReqManager = OnMoveTime(messageId: message.id ?? 0, request: fromTimeReq, highlight: false)
        RequestsManager.shared.append(prepend: "FROM-TIME", value: fromReqManager)
        ChatManager.activeInstance?.message.history(fromTimeReq)
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    func moveToMessageLocally(_ messageId: Int, highlight: Bool) -> Bool {
        if let uniqueId = message(for: messageId)?.message.uniqueId {
            threadViewModel.scrollVM.showHighlighted(uniqueId, messageId, highlight: highlight)
            return true
        }
        return false
    }

    /// Scenario 7 = When lastMessgeSeenId is bigger than thread.lastMessageVO.id as a result of server chat bug.
    func trySeventhScenario() {
        if thread.lastMessageVO?.id ?? 0 < thread.lastSeenMessageId ?? 0 {
            moveToTime(thread.lastMessageVO?.time ?? 0, thread.lastMessageVO?.id ?? 0, highlight: false)
        }
    }

    /// Scenario 8 = When a new thread has been built and me is added by another person and this is our first time to visit the thread.
    func tryEightScenario() {
        if thread.lastSeenMessageId == 0, thread.lastSeenMessageTime == nil, let lastMSGId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            moveToTime(time, lastMSGId, highlight: false)
        }
    }

    func sectionIndexByUniqueId(_ uniqueId: String) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { $0.messages.contains(where: {$0.uniqueId == uniqueId }) })
    }

    func sectionIndexByMessageId(_ message: Message) -> Array<MessageSection>.Index? {
        sectionIndexByMessageId(message.id ?? 0)
    }

    func sectionIndexByMessageId(_ id: Int) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { $0.messages.contains(where: {$0.id == id }) })
    }

    func sectionIndexByDate(_ date: Date) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { Calendar.current.isDate(date, inSameDayAs: $0.date)})
    }

    public func messageIndex(_ messageId: Int, in section: Array<MessageSection>.Index) -> Array<Message>.Index? {
        sections[section].messages.firstIndex(where: { $0.id == messageId })
    }

    public func messageIndex(_ uniqueId: String, in section: Array<MessageSection>.Index) -> Array<Message>.Index? {
        sections[section].messages.firstIndex(where: { $0.uniqueId == uniqueId })
    }

    func message(for id: Int?) -> (message: Message, sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard
            let id = id,
            let sectionIndex = sectionIndexByMessageId(id),
            let messageIndex = messageIndex(id, in: sectionIndex)
        else { return nil }
        let message = sections[sectionIndex].messages[messageIndex]
        return (message: message, sectionIndex: sectionIndex, messageIndex: messageIndex)
    }

    func indicesByMessageUniqueId(_ uniqueId: String) -> (sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard
            let sectionIndex = sectionIndexByUniqueId(uniqueId),
            let messageIndex = messageIndex(uniqueId, in: sectionIndex)
        else { return nil }
        return (sectionIndex: sectionIndex, messageIndex: messageIndex)
    }

    func findIncicesBy(uniqueId: String?, _ id: Int?) -> (sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard
            let sectionIndex = sections.firstIndex(where: { $0.messages.contains(where: { $0.uniqueId == uniqueId || $0.id == id }) }),
            let messageIndex = sections[sectionIndex].messages.firstIndex(where: { $0.uniqueId == uniqueId || $0.id == id })
        else { return nil }
        return (sectionIndex: sectionIndex, messageIndex: messageIndex)
    }

    public func removeById(_ id: Int?) {
        guard let id = id, let indices = message(for: id) else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
    }

    public func removeByUniqueId(_ uniqueId: String?) {
        guard let uniqueId = uniqueId, let indices = indicesByMessageUniqueId(uniqueId) else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
    }

    public func deleteMessages(_ messages: [Message], forAll: Bool = false) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: forAll))
        threadViewModel.selectedMessagesViewModel.clearSelection()
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    public func onDeleteMessage(_ response: ChatResponse<Message>) {
        guard let responseThreadId = response.subjectId ?? response.result?.threadId ?? response.result?.conversation?.id,
              threadId == responseThreadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId, response.result?.id)
        else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
        if sections[indices.sectionIndex].messages.count == 0 {
            sections.remove(at: indices.sectionIndex)
        }
        animateObjectWillChange()
    }

    public func sort() {
        sections.indices.forEach { sectionIndex in
            sections[sectionIndex].messages.sort { m1, m2 in
                if m1 is UnreadMessageProtocol {
                    return false
                }
                if let t1 = m1.time, let t2 = m2.time {
                    return t1 < t2
                } else {
                    return false
                }
            }
        }
        sections.sort(by: {$0.date < $1.date})
    }


    public func appendMessagesAndSort(_ messages: [Message], isToTime: Bool = false) {
        guard messages.count > 0 else { return }
        messages.forEach { message in
            insertOrUpdate(message)
        }
        sort()
        topSliceId = sections.flatMap{$0.messages}.prefix(thresholdToLoad).compactMap{$0.id}.last ?? 0
        bottomSliceId = sections.flatMap{$0.messages}.suffix(thresholdToLoad).compactMap{$0.id}.first ?? 0
    }

    func insertOrUpdate(_ message: Message) {
        let indices = findIncicesBy(uniqueId: message.uniqueId ?? "", message.id ?? -1)
        if let indices = indices {
            sections[indices.sectionIndex].messages[indices.messageIndex].updateMessage(message: message)
        } else if message.threadId == threadId || message.conversation?.id == threadId {
            if let sectionIndex = sectionIndexByDate(message.time?.date ?? Date()) {
                sections[sectionIndex].messages.append(message)
            } else {
                sections.append(.init(date: message.time?.date ?? Date(), messages: [message]))
            }
        }
        /// Create if there is no viewModel inside messageViewModels array. It is essential for highlighting and more
        messageViewModel(for: message)
    }

    func sectionIndexByUniqueId(_ message: Message) -> Array<MessageSection>.Index? {
        sectionIndexByUniqueId(message.uniqueId ?? "")
    }
    
    private func isInTopSlice(_ message: Message) -> Bool {
        return message.id ?? 0 <= topSliceId
    }

    private func isInBottomSlice(_ message: Message) -> Bool {
        return message.id ?? 0 >= bottomSliceId
    }

    @discardableResult
    public func messageViewModel(for message: Message) -> MessageRowViewModel {
        /// For unsent messages, uniqueId has value but message.id is always nil, so we have to check both to make sure we get the right viewModel, unless it will lead to an overwrite on a message and it will break down all the things.
        if let viewModel = messageViewModels.first(where: {  $0.message.uniqueId == message.uniqueId && $0.message.id == message.id }){
            return viewModel
        } else {
            let newViewModel = MessageRowViewModel(message: message, viewModel: threadViewModel)
            messageViewModels.append(newViewModel)
            return newViewModel
        }
    }

    func moveToMessageTimeOnOpenConversation() {
        if let moveToMessageId = AppState.shared.appStateNavigationModel.moveToMessageId, let moveToMessageTime = AppState.shared.appStateNavigationModel.moveToMessageTime {
            moveToTime(moveToMessageTime, moveToMessageId, highlight: true)
            AppState.shared.appStateNavigationModel = .init()
        }
    }

    private func onCancelTimer(key: String) {
        if topLoading || bottomLoading {
            topLoading = false
            bottomLoading = false
            animateObjectWillChange()
        }
    }

    public func onMessageAppear(_ message: Message) {
        let scrollVM = threadViewModel.scrollVM
        if message.id == sections.first?.messages.first?.id {
            lastTopVisibleMessage = message
        }
        if message.id == thread.lastMessageVO?.id, threadViewModel.scrollVM.isAtBottomOfTheList == false {
            threadViewModel.scrollVM.isAtBottomOfTheList = true
            threadViewModel.scrollVM.animateObjectWillChange()
        }
        /// We get next item in the list because when we are scrolling up the message is beneth NavigationView so we should get the next item to ensure we are in right position
        guard
            let sectionIndex = sectionIndexByMessageId(message),
            let messageIndex = messageIndex(message.id ?? -1, in: sectionIndex)
        else { return }
        let section = sections[sectionIndex]
        if scrollVM.scrollingUP == true, section.messages.indices.contains(messageIndex + 1) == true {
            let message = section.messages[messageIndex + 1]
            log("Scrolling Up with id:\(message.id ?? 0) uniqueId:\(message.uniqueId ?? "") text:\(message.message ?? "")")
        } else if scrollVM.scrollingUP == false, section.messages.indices.contains(messageIndex - 1), section.messages.last?.id != message.id {
            let message = section.messages[messageIndex - 1]
            log("Scroling Down with id:\(message.id ?? 0) uniqueId:\(message.uniqueId ?? "") text:\(message.message ?? "")")
            threadViewModel.reduceUnreadCountLocaly(message)
            threadViewModel.seenPublisher.send(message)
        } else {
            // Last Item
            log("Last Item with id:\(message.id ?? 0) uniqueId:\(message.uniqueId ?? "") text:\(message.message ?? "")")
            threadViewModel.reduceUnreadCountLocaly(message)
            threadViewModel.seenPublisher.send(message)
        }

        if scrollVM.scrollingUP == true, scrollVM.isProgramaticallyScroll == false, isInTopSlice(message) {
            moreTop(sections.first?.messages.first?.time)
        }

        if scrollVM.scrollingUP == false, scrollVM.isProgramaticallyScroll == false, isInBottomSlice(message) {
            moreBottom(sections.last?.messages.last?.time?.advanced(by: 1))
        }
    }

    public func onMessegeDisappear(_ message: Message) {
        if message.id == thread.lastMessageVO?.id, threadViewModel.scrollVM.isAtBottomOfTheList == true {
            threadViewModel.scrollVM.isAtBottomOfTheList = false
            threadViewModel.scrollVM.animateObjectWillChange()
        }
    }

    public func onSent(_ response: ChatResponse<MessageResponse>) {
        guard
            threadId == response.result?.threadId,
            let indices = indicesByMessageUniqueId(response.uniqueId ?? "")
        else { return }
        if !replaceUploadMessage(response) {
            sections[indices.sectionIndex].messages[indices.messageIndex].id = response.result?.messageId
            sections[indices.sectionIndex].messages[indices.messageIndex].time = response.result?.messageTime
        }
    }

    func replaceUploadMessage(_ response: ChatResponse<MessageResponse>) -> Bool {
        let lasSectionIndex = sections.firstIndex(where: {$0.id == sections.last?.id})
        if let lasSectionIndex,
           sections.indices.contains(lasSectionIndex),
           let oldUploadFileIndex = sections[lasSectionIndex].messages.firstIndex(where: { $0.isUploadMessage && $0.uniqueId == response.uniqueId }) {
            sections[lasSectionIndex].messages.remove(at: oldUploadFileIndex) /// Remove because it was of type UploadWithTextMessageProtocol
            sections[lasSectionIndex].messages.append(.init(threadId: response.subjectId, id: response.result?.messageId, time: response.result?.messageTime, uniqueId: response.uniqueId))
            return true
        }
        return false
    }

    public func onDeliver(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId ?? "", response.result?.messageId ?? 0)
        else { return }
        sections[indices.sectionIndex].messages[indices.messageIndex].delivered = true
    }

    public func onSeen(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId ?? "", response.result?.messageId ?? 0),
              sections[indices.sectionIndex].messages[indices.messageIndex].seen == nil
        else { return }
        sections[indices.sectionIndex].messages[indices.messageIndex].delivered = true
        sections[indices.sectionIndex].messages[indices.messageIndex].seen = true
        setSeenForOlderMessages(messageId: response.result?.messageId)
    }

    private func setSeenForOlderMessages(messageId: Int?) {
        if let messageId = messageId {
            sections.indices.forEach { sectionIndex in
                sections[sectionIndex].messages.indices.forEach { messageIndex in
                    let message = sections[sectionIndex].messages[messageIndex]
                    if (message.id ?? 0 < messageId) &&
                        (message.seen ?? false == false || message.delivered ?? false == false)
                        && message.ownerId == ChatManager.activeInstance?.userInfo?.id {
                        sections[sectionIndex].messages[messageIndex].delivered = true
                        sections[sectionIndex].messages[messageIndex].seen = true
                        let result = MessageResponse(messageState: .seen, threadId: threadId, messageId: message.id)
                        NotificationCenter.default.post(name: Notification.Name("UPDATE_OLDER_SEENS_LOCALLY"), object: result)
                    }
                }
            }
        }
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            if !response.cache {
                /// For the first scenario.
                onMoreTopFirstScenario(response)
                onMoreBottomFirstScenario(response)

                /// For the second scenario.
                onMoreTopSecondScenario(response)

                /// For the scenario three and four.
                onMoreTop(response)

                /// For the scenario three and four.
                onMoreBottom(response)

                /// For the fifth scenario.
                onMoreBottomFifthScenario(response)

                /// For the sixth scenario.
                onMoveToTime(response)
                onMoveFromTime(response)
            }

            //            if response.cache == true {
            //                isProgramaticallyScroll = true
            //                appendMessagesAndSort(response.result ?? [])
            //                animateObjectWillChange()
            //            }
            if !response.cache,
               let messageIds = response.result?.filter({$0.reactionableType}).compactMap({$0.id}),
               !threadViewModel.searchedMessagesViewModel.isInSearchMode {
                ReactionViewModel.shared.getReactionSummary(messageIds, conversationId: threadId)
            }
            break
        case .delivered(let response):
            onDeliver(response)
        case .seen(let response):
            onSeen(response)
        case .sent(let response):
            onSent(response)
        case .deleted(let response):
            onDeleteMessage(response)
        case .pin(let response):
            onPinMessage(response)
        case .unpin(let response):
            onUNPinMessage(response)
        default:
            break
        }
    }

    func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if let indices = message(for: response.result?.id) {
            sections[indices.sectionIndex].messages[indices.messageIndex].pinned = true
        }
    }

    func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if let indices = message(for: response.result?.id) {
            sections[indices.sectionIndex].messages[indices.messageIndex].pinned = false
        }
    }

    func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}
