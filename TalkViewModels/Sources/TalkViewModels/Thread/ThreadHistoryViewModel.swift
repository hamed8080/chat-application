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
    public var needUpdates: ContiguousArray<MessageRowViewModel> = .init()
    public var hasNextTop = true
    public var hasNextBottom = true
    public let count: Int = 25
    private let thresholdToLoad = 20
    public var topLoading = false
    public var bottomLoading = false
    public var canLoadMoreTop: Bool { hasNextTop && !topLoading }
    public var canLoadMoreBottom: Bool { !bottomLoading && sections.last?.vms.last?.id != thread.lastMessageVO?.id && hasNextBottom }
    private var topSliceId: Int = 0
    private var bottomSliceId: Int = 0
    @MainActor
    public var lastTopVisibleMessage: Message?
    public var isFetchedServerFirstResponse: Bool = false
    private var cancelable: Set<AnyCancellable> = []
    public weak var threadViewModel: ThreadViewModel?
    private var thread: Conversation { threadViewModel?.thread ?? .init(id: -1) }
    private var threadId: Int { thread.id ?? -1 }
    var hasSentHistoryRequest = false
    public var shimmerViewModel: ShimmerViewModel = .init(delayToHide: 0)

    public var isEmptyThread: Bool {
        let noMessage = isFetchedServerFirstResponse == true && sections.count == 0
        let emptyThread = threadViewModel?.isSimulatedThared == true
        return emptyThread || noMessage
    }

    public init() {}

    public func setupNotificationObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancelable)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    self?.onCancelTimer(key: key)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.windowMode.publisher(for: .windowMode)
            .sink { [weak self] newValue in
                self?.updateAllRows()
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: Notification.Name("UPDATE_OLDER_SEENS_LOCALLY"))
            .compactMap {$0.object as? MessageResponse}
            .sink { [weak self] newValue in
                self?.updateOlderSeensLocally()
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: Notification.Name("HIGHLIGHT"))
            .compactMap {$0.object as? Int}
            .sink { [weak self] newValue in
                self?.setHighlight(messageId: newValue)
            }
            .store(in: &cancelable)
        threadViewModel?.selectedMessagesViewModel.$isInSelectMode
            .sink { [weak self] newValue in
                self?.setRowsIsInSelectMode(newValue: newValue)
            }
            .store(in: &cancelable)

        NotificationCenter.upload.publisher(for: .upload)
            .sink { [weak self] notification in
                self?.onUploadEvents(notification)
            }
            .store(in: &cancelable)

        NotificationCenter.reactionMessageUpdated.publisher(for: .reactionMessageUpdated)
            .sink { [weak self] notification in
                self?.onReactionEvent(notification)
            }
            .store(in: &cancelable)
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        let isSimulated = threadViewModel?.isSimulatedThared == true
        if !isSimulated, status == .connected, isFetchedServerFirstResponse == true, threadViewModel?.isActiveThread == true {
            // After connecting again get latest messages.
            tryFifthScenario(status: status)
        }

        /// Fetch the history for the first time if the internet connection is not available.
        if !isSimulated, status == .connected, hasSentHistoryRequest == true, sections.isEmpty {
            startFetchingHistory()
        }
    }

    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    public func startFetchingHistory() {
        /// We check this to prevent recalling these methods when the view reappears again.
        /// If centerLoading is true it is mean theat the array has gotten clear for Scenario 6 to move to a time.
        let isSimulatedThread = threadViewModel?.isSimulatedThared == true
        let hasAnythingToLoadOnOpen = AppState.shared.appStateNavigationModel.moveToMessageId != nil
        moveToMessageTimeOnOpenConversation()
        if sections.count > 0 || shimmerViewModel.isShowing == true || hasAnythingToLoadOnOpen || isSimulatedThread { return }
        hasSentHistoryRequest = true
        shimmerViewModel.show()
        tryFirstScenario()
        trySecondScenario()
        trySeventhScenario()
        tryEightScenario()
        tryNinthScenario()
    }

    public func moreTop(prepend: String = "MORE-TOP", delay: TimeInterval = 0.5, _ toTime: UInt?) {
        if !canLoadMoreTop { return }
        topLoading = true
        animateObjectWillChange()
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: threadViewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: prepend, value: req)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            if self != nil {
                ChatManager.activeInstance?.message.history(req)
            }
        }
    }

    public func onMoreTop(_ response: ChatResponse<[Message]>) {
        guard response.pop(prepend: "MORE-TOP") != nil, let messages = response.result else { return }
        Task { [weak self] in
            guard let self = self else { return }
            /// 3- Append and sort the array but not call to update the view.
            await appendMessagesAndSort(messages)
            /// 4- Disable excessive loading on the top part.
            threadViewModel?.scrollVM.disableExcessiveLoading()
            /// 5- Set whether it has more messages at the top or not.
            await setHasMoreTop(response)
            isFetchedServerFirstResponse = true
            /// 6- To update isLoading fields to hide the loading at the top.
            await asyncAnimateObjectWillChange()
//
//            if let uniqueId = await lastTopVisibleMessage?.uniqueId, let id = await lastTopVisibleMessage?.id {
//                threadViewModel?.scrollVM.showHighlighted(uniqueId, id, highlight: false, anchor: .bottom)
//                await MainActor.run { [weak self] in
//                    self?.lastTopVisibleMessage = nil
//                }
//            }
        }
    }

    public func moreBottom(prepend: String = "MORE-BOTTOM", _ fromTime: UInt?) {
        if !hasNextBottom || bottomLoading { return }
        bottomLoading = true
        animateObjectWillChange()
        let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: threadViewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: prepend, value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    public func onMoreBottom(_ response: ChatResponse<[Message]>) {
        guard response.pop(prepend: "MORE-BOTTOM") != nil, let messages = response.result else { return }
        Task { [weak self] in
            guard let self = self else { return }
            /// 3- Append and sort the array but not call to update the view.
            await appendMessagesAndSort(messages)
            /// 4- Disable excessive loading on the top part.
            threadViewModel?.scrollVM.disableExcessiveLoading()
            /// 7- Set whether it has more messages at the bottom or not.
            await setHasMoreBottom(response)
            isFetchedServerFirstResponse = true
            /// 8- To update isLoading fields to hide the loading at the bottom.
            await asyncAnimateObjectWillChange()
        }
    }

    func setHasMoreTop(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            topLoading = false
        }
    }

    func setHasMoreBottom(_ response: ChatResponse<[Message]>) async {
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
        guard response.pop(prepend: "MORE-TOP-FIRST-SCENARIO") != nil, let messages = response.result else { return }
        Task { [weak self] in
            guard let self = self else { return }
            /// 2- Append and sort  and calculate the array but not call to update the view.
            await appendMessagesAndSort(messages)
            /// 3- Find the last Seen message ID in the list of messages section and use the unique ID to scroll to.
            let lastSeenMessage = message(for: thread.lastSeenMessageId)?.message
            /// 4- Fetch from time messages to get to the bottom part and new messages to stay there if the user scrolls down.
            if let fromTime = lastSeenMessage?.time {
                moreBottom(prepend: "MORE-BOTTOM-FIRST-SCENARIO", fromTime.advanced(by: -1))
            }
            /// 5- Set whether it has more messages at the top or not.
            await setHasMoreTop(response)
        }
    }

    public func onMoreBottomFirstScenario(_ response: ChatResponse<[Message]>) {
        guard response.pop(prepend: "MORE-BOTTOM-FIRST-SCENARIO") != nil, let messages = response.result else { return }
        Task { [weak self] in
            guard let self = self else { return }
            /// 6- Append the unread message banner and after sorting it will sit below the last message seen. and it will be added into the secion of lastseen message no the new ones.
            await appenedUnreadMessagesBannerIfNeeed()
            /// 7- Append messages to the bottom part of the view and if the user scrolls down can see new messages.
            await appendMessagesAndSort(messages)
            /// 8-  Set whether it has more messages at the bottom or not.
            await setHasMoreBottom(response)
            /// 9- Update all the views to draw new messages for the bottom part and hide loading at the bottom.
            await asyncAnimateObjectWillChange()
            await threadViewModel?.scrollVM.showHighlightedAsync("\(LocalId.unreadMessageBanner.rawValue)", LocalId.unreadMessageBanner.rawValue, highlight: false)
            shimmerViewModel.hide()
        }
    }

    func appenedUnreadMessagesBannerIfNeeed() async {
        guard
            let tuples = message(for: thread.lastSeenMessageId),
            let threadViewModel = threadViewModel
        else { return }
        let time = (tuples.message.time ?? 0) + 1
        let unreadMessage = UnreadMessage(id: LocalId.unreadMessageBanner.rawValue, time: time, uniqueId: "\(LocalId.unreadMessageBanner.rawValue)")
        sections[tuples.sectionIndex].vms.append(.init(message: unreadMessage, viewModel: threadViewModel))
    }

    public func removeOldBanner() {
        if let indices = indicesByMessageUniqueId("\(LocalId.unreadMessageBanner.rawValue)") {
            sections[indices.sectionIndex].vms.remove(at: indices.messageIndex)
        }
    }

    /// Scenario 2
    func trySecondScenario() {
        /// 1- Get the top part to time messages
        if thread.lastMessageVO?.id ?? 0 == thread.lastSeenMessageId ?? 0, let toTime = thread.lastSeenMessageTime {
            moreTop(prepend: "MORE-TOP-SECOND-SCENARIO", toTime.advanced(by: 1))
        }
    }

    public func onMoreTopSecondScenario(_ response: ChatResponse<[Message]>) {
        guard response.pop(prepend: "MORE-TOP-SECOND-SCENARIO") != nil, let messages = response.result else { return }
        Task { [weak self] in
            guard let self = self else { return }
            if response.result?.count ?? 0 > 0 {
                /// 2- Append and sort the array but not call to update the view and do calculaiton.
                await appendMessagesAndSort(messages)
                /// 4- Disable excessive loading on the top part.
                threadViewModel?.scrollVM.disableExcessiveLoading()
            }
            isFetchedServerFirstResponse = true
            /// 5- To update isLoading fields to hide the loading at the top and prepare the ui for scrolling to.
            await asyncAnimateObjectWillChange()
            if let uniqueId = thread.lastMessageVO?.uniqueId, let messageId = thread.lastMessageVO?.id {
                await threadViewModel?.scrollVM.showHighlightedAsync(uniqueId, messageId, highlight: false)
            }
            /// 6- Set whether it has more messages at the top or not.
            await setHasMoreTop(response)
            shimmerViewModel.hide()
        }
    }

    /// Scenario 3 or 4 more top/bottom.

    /// Scenario 5
    func tryFifthScenario(status: ConnectionStatus) {
        /// 1- Get the bottom part of the list of what is inside the memory.
        if status == .connected,
           isFetchedServerFirstResponse == true,
           threadViewModel?.isActiveThread == true,
           let lastMessageInListTime = sections.first?.vms.first?.message.time {
            bottomLoading = true
            animateObjectWillChange()
            let fromTime = lastMessageInListTime.advanced(by: 1)
            let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: threadViewModel?.readOnly == true)
            RequestsManager.shared.append(prepend: "MORE-BOTTOM-FIFTH-SCENARIO", value: req)
            ChatManager.activeInstance?.message.history(req)
        }
    }

    public func onMoreBottomFifthScenario(_ response: ChatResponse<[Message]>) {
        guard response.pop(prepend: "MORE-BOTTOM-FIFTH-SCENARIO") != nil, let messages = response.result else { return }
        Task { [weak self] in
            guard let self = self else { return }
            /// 2- Append the unread message banner at the end of the array. It does not need to be sorted because it has been sorted by the above function.
            if response.result?.count ?? 0 > 0 {
                removeOldBanner()
                await appenedUnreadMessagesBannerIfNeeed()
                /// 3- Append and sort and calculate the array but not call to update the view.
                await appendMessagesAndSort(messages)
            }
            /// 4- Set whether it has more messages at the bottom or not.
            await setHasMoreBottom(response)
            /// 5- To update isLoading fields to hide the loading at the bottom.
            await asyncAnimateObjectWillChange()
        }
    }

    /// Scenario 6
    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true) {
        Task { [weak self] in
            guard let self = self else { return }
            /// 1- Move to a message locally if it exists.
            if await moveToMessageLocally(messageId, highlight: highlight) { return }
            shimmerViewModel.show()
            sections.removeAll()
            /// 2- Fetch the top part of the message with the message itself.
            let toTimeReq = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: time.advanced(by: 1), readOnly: threadViewModel?.readOnly == true)
            let timeReqManager = OnMoveTime(messageId: messageId, request: toTimeReq, highlight: highlight)
            RequestsManager.shared.append(prepend: "TO-TIME", value: timeReqManager)
            ChatManager.activeInstance?.message.history(toTimeReq)
        }
    }

    func onMoveToTime(_ response: ChatResponse<[Message]>) {
        guard let request = response.pop(prepend: "TO-TIME") as? OnMoveTime,
              let messages = response.result
        else { return }
        Task { [weak self] in
            guard let self = self else { return }
            /// 3- Append and sort the array but not call to update the view.
            await appendMessagesAndSort(messages)
            /// We set this property to true because in the seven scenario there is no way to set this property to true.
            /// 4- Disable excessive loading on the top part.
            threadViewModel?.scrollVM.disableExcessiveLoading()
            isFetchedServerFirstResponse = true
            /// 5- Update all the views to draw for the top part.
            await asyncAnimateObjectWillChange()
            /// 7- Fetch the From to time (bottom part) to have a little bit of messages from the bottom.
            let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: request.request.toTime?.advanced(by: -1), offset: 0, order: "asc", readOnly: threadViewModel?.readOnly == true)
            let fromReqManager = OnMoveTime(messageId: request.messageId, request: fromTimeReq, highlight: request.highlight)
            RequestsManager.shared.append(prepend: "FROM-TIME", value: fromReqManager)
            ChatManager.activeInstance?.message.history(fromTimeReq)
        }
    }

    func onMoveFromTime(_ response: ChatResponse<[Message]>) {
        guard
            let request = response.pop(prepend: "FROM-TIME") as? OnMoveTime,
            let messages = response.result
        else { return }
        Task { [weak self] in
            guard let self = self else { return }
            /// 8- Append and sort the array but not call to update the view.
            await appendMessagesAndSort(messages)
            await setHasMoreBottom(response)
            /// 9- Update all the views to draw for the bottom part.
            await asyncAnimateObjectWillChange()
            /// 6- Scroll to the message with its uniqueId.
            guard let uniqueId = message(for: request.messageId)?.message.uniqueId else { return }
            await threadViewModel?.scrollVM.showHighlightedAsync(uniqueId, request.messageId, highlight: request.highlight)
            shimmerViewModel.hide()
        }
    }

    func moreBottomMoveTo(_ message: Message) {
        /// 12- Fetch the next part of the bottom when the user scrolls to the bottom part of move to.
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: message.time, offset: 0, order: "asc", readOnly: threadViewModel?.readOnly == true)
        let fromReqManager = OnMoveTime(messageId: message.id ?? 0, request: fromTimeReq, highlight: false)
        RequestsManager.shared.append(prepend: "FROM-TIME", value: fromReqManager)
        ChatManager.activeInstance?.message.history(fromTimeReq)
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    func moveToMessageLocally(_ messageId: Int, highlight: Bool) async -> Bool {
        if let uniqueId = message(for: messageId)?.message.uniqueId {
            await threadViewModel?.scrollVM.showHighlightedAsync(uniqueId, messageId, highlight: highlight)
            return true
        }
        return false
    }

    /// Scenario 7 = When lastMessgeSeenId is bigger than thread.lastMessageVO.id as a result of server chat bug.
    func trySeventhScenario() {
        if thread.lastMessageVO?.id ?? 0 < thread.lastSeenMessageId ?? 0 {
            requestBottomPartByCountAndOffset()
        }
    }

    func requestBottomPartByCountAndOffset() {
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, readOnly: threadViewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: "FETCH-BY-OFFSET", value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    func onFetchByOffset(_ response: ChatResponse<[Message]>) {
        guard
            response.pop(prepend: "FETCH-BY-OFFSET") != nil,
            let messages = response.result
        else { return }
        Task { [weak self] in
            guard let self = self else { return }
            let sortedMessages = messages.sorted(by: {$0.time ?? 0 < $1.time ?? 0})
            await appendMessagesAndSort(sortedMessages)
            isFetchedServerFirstResponse = true
            await asyncAnimateObjectWillChange()
            await threadViewModel?.scrollVM.showHighlightedAsync(sortedMessages.last?.uniqueId ?? "", sortedMessages.last?.id ?? -1, highlight: false)
            shimmerViewModel.hide()
        }
    }

    /// Scenario 8 = When a new thread has been built and me is added by another person and this is our first time to visit the thread.
    func tryEightScenario() {
        if thread.lastSeenMessageId == 0, thread.lastSeenMessageTime == nil, let lastMSGId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            moveToTime(time, lastMSGId, highlight: false)
        }
    }

    /// When a new thread has been built and there is no message inside the thread yet.
    func tryNinthScenario() {
        if (thread.lastSeenMessageId == 0 || thread.lastSeenMessageId == nil) && thread.lastMessageVO == nil {
            requestBottomPartByCountAndOffset()
        }
    }

    func sectionIndexByUniqueId(_ uniqueId: String) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { $0.vms.contains(where: {$0.message.uniqueId == uniqueId }) })
    }

    func sectionIndexByMessageId(_ message: Message) -> Array<MessageSection>.Index? {
        sectionIndexByMessageId(message.id ?? 0)
    }

    func sectionIndexByMessageId(_ id: Int) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { $0.vms.contains(where: {$0.message.id == id }) })
    }

    func sectionIndexByDate(_ date: Date) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { Calendar.current.isDate(date, inSameDayAs: $0.date)})
    }

    public func messageIndex(_ messageId: Int, in section: Array<MessageSection>.Index) -> Array<Message>.Index? {
        sections[section].vms.firstIndex(where: { $0.id == messageId })
    }

    public func messageIndex(_ uniqueId: String, in section: Array<MessageSection>.Index) -> Array<Message>.Index? {
        sections[section].vms.firstIndex(where: { $0.message.uniqueId == uniqueId })
    }

    func message(for id: Int?) -> (message: Message, sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard
            let id = id,
            let sectionIndex = sectionIndexByMessageId(id),
            let messageIndex = messageIndex(id, in: sectionIndex)
        else { return nil }
        let message = sections[sectionIndex].vms[messageIndex].message
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
            let sectionIndex = sections.firstIndex(where: { $0.vms.contains(where: { $0.message.uniqueId == uniqueId || $0.id == id }) }),
            let messageIndex = sections[sectionIndex].vms.firstIndex(where: { $0.message.uniqueId == uniqueId || $0.id == id })
        else { return nil }
        return (sectionIndex: sectionIndex, messageIndex: messageIndex)
    }

    public func removeById(_ id: Int?) {
        guard let id = id, let indices = message(for: id) else { return }
        sections[indices.sectionIndex].vms.remove(at: indices.messageIndex)
    }

    public func removeByUniqueId(_ uniqueId: String?) {
        guard let uniqueId = uniqueId, let indices = indicesByMessageUniqueId(uniqueId) else { return }
        sections[indices.sectionIndex].vms.remove(at: indices.messageIndex)
    }

    public func deleteMessages(_ messages: [Message], forAll: Bool = false) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: forAll))
        threadViewModel?.selectedMessagesViewModel.clearSelection()
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    public func onDeleteMessage(_ response: ChatResponse<Message>) {
        guard let responseThreadId = response.subjectId ?? response.result?.threadId ?? response.result?.conversation?.id,
              threadId == responseThreadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId, response.result?.id)
        else { return }
        sections[indices.sectionIndex].vms.remove(at: indices.messageIndex)
        if sections[indices.sectionIndex].vms.count == 0 {
            sections.remove(at: indices.sectionIndex)
        }
        animateObjectWillChange()
    }

    public func sort() {
        let logger = Logger.viewModels
        logger.debug("Start o f the Sort function: \(Date().millisecondsSince1970)")
        sections.indices.forEach { sectionIndex in
            sections[sectionIndex].vms.sort { m1, m2 in
                if m1 is UnreadMessageProtocol {
                    return false
                }
                if let t1 = m1.message.time, let t2 = m2.message.time {
                    return t1 > t2
                } else {
                    return false
                }
            }
        }
        sections.sort(by: {$0.date > $1.date})
        logger.debug("End of the Sort function: \(Date().millisecondsSince1970)")
    }

    public func appendMessagesAndSort(_ messages: [Message], isToTime: Bool = false) async {
        let logger = Logger.viewModels
        logger.debug("Start of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
        guard messages.count > 0 else { return }
        var viewModels: [MessageRowViewModel?] = []
        for message in messages {
            let vm = insertOrUpdate(message)
            viewModels.append(vm)
        }
        sort()
        for viewModel in viewModels {
            await viewModel?.performaCalculation()
        }
        let flatMap = sections.flatMap{$0.vms}
        topSliceId = flatMap.suffix(thresholdToLoad).compactMap{$0.id}.first ?? 0
        bottomSliceId = flatMap.prefix(thresholdToLoad).compactMap{$0.id}.last ?? 0
        logger.debug("End of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
        fetchReactions(messages: messages)
    }

    fileprivate typealias SecionAndMessageIndex = (sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)
    fileprivate func updateMessage(_ message: Message, _ indices: SecionAndMessageIndex?) -> MessageRowViewModel? {
        guard let indices = indices else { return nil }
        let vm = sections[indices.sectionIndex].vms[indices.messageIndex]
        if vm.uploadViewModel != nil || vm.message is UploadFileWithLocationMessage {
            /// We have to update animateObjectWillChange because after onNewMessage we will not call it, so upload file not work properly.
            vm.swapUploadMessageWith(message)
        } else {
            vm.message.updateMessage(message: message)
        }
        return vm
    }

    func insertIntoSection(_ message: Message) -> MessageRowViewModel? {
        if message.threadId == threadId || message.conversation?.id == threadId, let threadViewModel = threadViewModel {
            let viewModel = MessageRowViewModel(message: message, viewModel: threadViewModel)
            if let sectionIndex = sectionIndexByDate(message.time?.date ?? Date()) {
                sections[sectionIndex].vms.append(viewModel)
                return viewModel
            } else {
                sections.append(.init(date: message.time?.date ?? Date(), vms: [viewModel]))
                return viewModel
            }
        }
        return nil
    }

    func insertOrUpdate(_ message: Message) -> MessageRowViewModel? {
        let indices = findIncicesBy(uniqueId: message.uniqueId ?? "", message.id ?? -1)
        if let vm = updateMessage(message, indices) {
            return vm
        }
        return insertIntoSection(message)
    }

    func appendToNeedUpdate(_ vm: MessageRowViewModel) {
        needUpdates.append(vm)
    }

    func updateNeeded() async {
        for (_, vm) in needUpdates.enumerated() {
            await vm.asyncAnimateObjectWillChange()
        }
        needUpdates.removeAll()
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
    public func messageViewModel(for message: Message) -> MessageRowViewModel? {
        /// For unsent messages, uniqueId has value but message.id is always nil, so we have to check both to make sure we get the right viewModel, unless it will lead to an overwrite on a message and it will break down all the things.
        let messageViewModels = sections.flatMap{$0.vms}
        if let viewModel = messageViewModels.first(where: {  $0.message.uniqueId == message.uniqueId && $0.message.id == message.id }){
            return viewModel
        } else if let threadViewModel = threadViewModel {
            let newViewModel = MessageRowViewModel(message: message, viewModel: threadViewModel)
            if let lastIndex = sections.indices.last {
                sections[lastIndex].vms.append(newViewModel)
            } else {
                sections.append(.init(date: Date(), vms: [.init(message: message, viewModel: threadViewModel)]))
            }
            return newViewModel
        } else {
            return nil
        }
    }

    @discardableResult
    public func messageViewModel(for messageId: Int) -> MessageRowViewModel? {
        return sections.flatMap{$0.vms}.first(where: { $0.message.id == messageId })
    }

    @discardableResult
    public func messageViewModel(for uniqueId: String) -> MessageRowViewModel? {
        return sections.flatMap{$0.vms}.first(where: { $0.message.uniqueId == uniqueId })
    }

    public func moveToMessageTimeOnOpenConversation() {
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

    @MainActor
    public func onMessageAppear(_ message: Message) async {
        guard let threadViewModel = threadViewModel else { return }
        let scrollVM = threadViewModel.scrollVM
        if message.id == sections.last?.vms.last?.id {
            lastTopVisibleMessage = message
        } else {
            lastTopVisibleMessage = nil
        }
        Task { [weak self] in
            guard let self = self else { return }
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
            if scrollVM.scrollingUP == true, section.vms.indices.contains(messageIndex + 1) == true {
                let message = section.vms[messageIndex + 1].message
                log("Scrolling Up with id:\(message.id ?? 0) uniqueId:\(message.uniqueId ?? "") text:\(message.message ?? "")")
            } else if scrollVM.scrollingUP == false, section.vms.indices.contains(messageIndex - 1), section.vms.first?.id != message.id {
                let message = section.vms[messageIndex - 1].message
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
                moreTop(sections.last?.vms.last?.message.time)
            }

            if scrollVM.scrollingUP == false, scrollVM.isProgramaticallyScroll == false, isInBottomSlice(message) {
                moreBottom(sections.first?.vms.first?.message.time?.advanced(by: 1))
            }
        }
    }

    public func onMessegeDisappear(_ message: Message) async {
        if message.id == thread.lastMessageVO?.id, threadViewModel?.scrollVM.isAtBottomOfTheList == true {
            threadViewModel?.scrollVM.isAtBottomOfTheList = false
            threadViewModel?.scrollVM.animateObjectWillChange()
        }
    }

    public func onSent(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId else { return }
        if let messageId = response.result?.messageId, let vm = messageViewModel(for: messageId) {
            vm.setSent(messageTime: response.result?.messageTime)
        }
    }

    func replaceUploadMessage(_ response: ChatResponse<MessageResponse>) -> Bool {
        let lasSectionIndex = sections.firstIndex(where: {$0.id == sections.last?.id})
        if  let threadViewModel = threadViewModel,
            let lasSectionIndex,
           sections.indices.contains(lasSectionIndex),
           let oldUploadFileIndex = sections[lasSectionIndex].vms.firstIndex(where: { $0.message.isUploadMessage && $0.message.uniqueId == response.uniqueId }) {
            sections[lasSectionIndex].vms.remove(at: oldUploadFileIndex) /// Remove because it was of type UploadWithTextMessageProtocol
            let message = Message(threadId: response.subjectId, id: response.result?.messageId, time: response.result?.messageTime, uniqueId: response.uniqueId)
            let viewModel = MessageRowViewModel(message: message, viewModel: threadViewModel)
            sections[lasSectionIndex].vms.append(viewModel)
            return true
        }
        return false
    }

    public func onDeliver(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId else { return }
        if let messageId = response.result?.messageId, let vm = messageViewModel(for: messageId) {
            vm.setDelivered()
        }
    }

    public func onSeen(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId, let messageId = response.result?.messageId else { return }
        if let vm = messageViewModel(for: messageId) {
            vm.setSeen()
        }
        setSeenForOlderMessages(messageId: response.result?.messageId)
    }

    private func setSeenForOlderMessages(messageId: Int?) {
        if let messageId = messageId {
            sections.indices.forEach { sectionIndex in
                sections[sectionIndex].vms.indices.forEach { messageIndex in
                    let message = sections[sectionIndex].vms[messageIndex].message
                    if (message.id ?? 0 < messageId) &&
                        (message.seen ?? false == false || message.delivered ?? false == false)
                        && message.ownerId == ChatManager.activeInstance?.userInfo?.id {
                        sections[sectionIndex].vms[messageIndex].message.delivered = true
                        sections[sectionIndex].vms[messageIndex].message.seen = true
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
            let logger = Logger.viewModels
            if !response.cache, response.subjectId == threadId {
                logger.debug("Start on history:\(Date().millisecondsSince1970)")
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

                /// For the seventh scenario.
                onFetchByOffset(response)

                /// For the sixth scenario.
                onMoveToTime(response)
                onMoveFromTime(response)
                logger.debug("End on history:\(Date().millisecondsSince1970)")
            }
            //            if response.cache == true {
            //                isProgramaticallyScroll = true
            //                appendMessagesAndSort(response.result ?? [])
            //                animateObjectWillChange()
            //            }
            break
        case .new(let response):
            onNewMessage(response)
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
        case .edited(let response):
            onEdited(response)
        default:
            break
        }
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if threadId == response.subjectId, let message = response.result {
            Task { [weak self] in                
                guard let self = self else { return }
                await appendMessagesAndSort([message])
                await updateNeeded()
                await asyncAnimateObjectWillChange()
                await threadViewModel?.scrollVM.scrollToLastMessageIfLastMessageIsVisible(message)
                setSeenForAllOlderMessages(newMessage: message)
            }
        }
    }

    private func onEdited(_ response: ChatResponse<Message>) {
        if let message = response.result, let vm = messageViewModel(for: message.id ?? -1) {
            vm.setEdited(message)
        }
    }

    func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.messageId, let vm = messageViewModel(for: messageId) {
            vm.pinMessage(time: response.result?.time)
        }
    }

    func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.messageId, let vm = messageViewModel(for: messageId) {
            vm.unpinMessage()
        }
    }

    /// When you have sent messages for example 5 messages and your partner didn't read messages and send a message directly it will send you only one seen.
    /// So you have to set seen to true for older unread messages you have sent, because the partner has read all messages and after you back to the list of thread the server will respond with seen == true for those messages.
    public func setSeenForAllOlderMessages(newMessage: Message) {
        let unseenMessages = sections.last?.vms.filter({($0.message.seen == false || $0.message.seen == nil) && $0.message.isMe(currentUserId: AppState.shared.user?.id)})
        let isNotMe = !newMessage.isMe(currentUserId: AppState.shared.user?.id)
        if isNotMe, unseenMessages?.count ?? 0 > 0 {
            unseenMessages?.forEach { vm in
                vm.message.seen = true
                vm.animateObjectWillChange()
            }
        }
    }

    public func updateAllRows() {
        sections.forEach { section in
            section.vms.forEach { vm in
                Task {
                    await vm.recalculateWithAnimation()
                }
            }
        }
    }

    public func updateOlderSeensLocally() {
        sections.forEach { section in
            section.vms.forEach { vm in
                if vm.message.seen == false || vm.message.seen == nil {
                    vm.message.delivered = true
                    vm.message.seen = true
                    vm.animateObjectWillChange()
                }
            }
        }
    }

    public func setHighlight(messageId: Int) {
        if let vm = messageViewModel(for: messageId) {
            vm.setHighlight()
        }
    }

    public func setRowsIsInSelectMode(newValue: Bool) {
        sections.forEach { section in
            section.vms.forEach { vm in
                if newValue != vm.isInSelectMode {
                    vm.isInSelectMode = newValue
                    vm.animateObjectWillChange()
                }
            }
        }
    }

    private func onReactionEvent(_ notification: Notification) {
        if let messageId = notification.object as? Int, let vm = messageViewModel(for: messageId) {
            vm.reactionsVM.updateWithDelay()
        }
    }

    private func onUploadEvents(_ notification: Notification) {
        guard let event = notification.object as? UploadEventTypes else { return }
        switch event {
        case .canceled(let uniqueId):
            onUploadCanceled(uniqueId)
        case .completed(let uniqueId, let fileMetaData, let data, let error):
            onUploadCompleted(uniqueId, fileMetaData, data, error)
        default:
            break
        }
    }

    private func onUploadCompleted(_ uniqueId: String?, _ fileMetaData: FileMetaData?, _ data: Data?, _ error: Error?) {
        if let uniqueId = uniqueId, let vm = messageViewModel(for: uniqueId) {
            vm.uploadCompleted(uniqueId, fileMetaData, data, error)
        }
    }

    private func onUploadCanceled(_ uniqueId: String?) {
        if let uniqueId = uniqueId {
            removeByUniqueId(uniqueId)
            animateObjectWillChange()
        }
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }

    private func fetchReactions(messages: [Message]) {
        if threadViewModel?.searchedMessagesViewModel.isInSearchMode == false {
            let messageIds = messages.filter({$0.reactionableType}).compactMap({$0.id})
            ReactionViewModel.shared.getReactionSummary(messageIds, conversationId: threadId)
        }
    }

    public func sendSeenForAllUnreadMessages() {
        if let message = thread.lastMessageVO,
           message.seen == nil || message.seen == false,
           message.participant?.id != AppState.shared.user?.id,
           thread.unreadCount ?? 0 > 0
        {
            threadViewModel?.sendSeen(for: message)
        }
    }

    func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}
