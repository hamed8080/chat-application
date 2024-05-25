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

public final class ThreadHistoryViewModel {
    // MARK: Stored Properties
    public var sections: ContiguousArray<MessageSection> = .init()
    private var needUpdates: ContiguousArray<MessageRowViewModel> = .init()
    private var hasNextTop = true
    private var hasNextBottom = true
    private let count: Int = 25
    public var threshold: CGFloat = 800
    public private(set) var topLoading = false
    public private(set) var bottomLoading = false
    private var topSliceId: Int = 0
    private var isFetchedServerFirstResponse: Bool = false
    private var cancelable: Set<AnyCancellable> = []
    public weak var delegate: HistoryScrollDelegate?
    private var hasSentHistoryRequest = false
    public var shimmerViewModel: ShimmerViewModel = .init(delayToHide: 0)
    internal var seenVM: HistorySeenViewModel? { viewModel?.seenVM }
    public var created: Bool = false
    private var isJumpedToLastMessage = false
    // Prevent Message rows view models from requesting any reconfigure for row until this insertion happens whether in the top or bottom
    public var isInInsertionTop = false
    public var isInInsertionBottom = false
    private let thresholdToLoad = 20
    private var bottomSliceId: Int = 0
    public var isTopEndListAppeared: Bool = false
    private var oldFirstMessageInFirstSection: Message?
    private weak var viewModel: ThreadViewModel?
    private var tasks: [Task<Void, Error>] = []
    private var visibleTracker = VisibleMessagesTracker()
    private let logger = Logger.viewModels

    // MARK: Computed Properties
    @MainActor public var isEmptyThread: Bool {
        let noMessage = isFetchedServerFirstResponse == true && sections.count == 0
        let emptyThread = viewModel?.isSimulatedThared == true
        return emptyThread || noMessage
    }
    private var thread: Conversation { viewModel?.thread ?? .init(id: -1) }
    private var threadId: Int { thread.id ?? -1 }
    private var isSimulated: Bool { viewModel?.isSimulatedThared == true }
    private var lastItemIdInSections = 0
    public var canLoadMoreTop: Bool { hasNextTop && !topLoading }
    public var canLoadMoreBottom: Bool { !bottomLoading && lastItemIdInSections != thread.lastMessageVO?.id && hasNextBottom }
    public typealias Indices = (message: Message, indexPath: IndexPath)

    private var objectId = UUID().uuidString
    private let MORE_TOP_KEY: String
    private let MORE_BOTTOM_KEY: String
    private let MORE_TOP_FIRST_SCENARIO_KEY: String
    private let MORE_BOTTOM_FIRST_SCENARIO_KEY: String
    private let MORE_TOP_SECOND_SCENARIO_KEY: String
    private let MORE_BOTTOM_FIFTH_SCENARIO_KEY: String
    private let TO_TIME_KEY: String
    private let FROM_TIME_KEY: String
    private let FETCH_BY_OFFSET_KEY: String

    // MARK: Initializer
    public init() {
        MORE_TOP_KEY = "MORE-TOP-\(objectId)"
        MORE_BOTTOM_KEY = "MORE-BOTTOM-\(objectId)"
        MORE_TOP_FIRST_SCENARIO_KEY = "MORE-TOP-FIRST-SCENARIO-\(objectId)"
        MORE_BOTTOM_FIRST_SCENARIO_KEY = "MORE-BOTTOM-FIRST-SCENARIO-\(objectId)"
        MORE_TOP_SECOND_SCENARIO_KEY = "MORE-TOP-SECOND-SCENARIO-\(objectId)"
        MORE_BOTTOM_FIFTH_SCENARIO_KEY = "MORE-BOTTOM-FIFTH-SCENARIO-\(objectId)"
        TO_TIME_KEY = "TO-TIME-\(objectId)"
        FROM_TIME_KEY = "FROM-TIME-\(objectId)"
        FETCH_BY_OFFSET_KEY = "FETCH-BY-OFFSET-\(objectId)"
    }

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        visibleTracker.delegate = self
        setupNotificationObservers()
    }

    // MARK: Scenarios Common Functions
    public func start() {
        /// After deleting a thread it will again tries to call histroy,
        /// we should prevent it from calling it to not get any error.
        if isFetchedServerFirstResponse == false {
            startFetchingHistory()
            viewModel?.threadsViewModel?.clearAvatarsOnSelectAnotherThread()
        } else if isFetchedServerFirstResponse == true {
            /// try to open reply privately if user has tried to click on  reply privately and back button multiple times
            /// iOS has a bug where it tries to keep the object in the memory, so multiple back and forward doesn't lead to destroy the object.
            moveToMessageTimeOnOpenConversation()
        }
    }
    
    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    private func startFetchingHistory() {
        /// We check this to prevent recalling these methods when the view reappears again.
        /// If centerLoading is true it is mean theat the array has gotten clear for Scenario 6 to move to a time.
        let isSimulatedThread = viewModel?.isSimulatedThared == true
        let hasAnythingToLoadOnOpen = AppState.shared.appStateNavigationModel.moveToMessageId != nil
        moveToMessageTimeOnOpenConversation()
        if sections.count > 0 || shimmerViewModel.isShowing == true || hasAnythingToLoadOnOpen || isSimulatedThread { return }
        hasSentHistoryRequest = true
        if !created {
            shimmerViewModel.show()
        }
        tryFirstScenario()
        trySecondScenario()
        trySeventhScenario()
        tryEightScenario()
        tryNinthScenario()
    }

    private func insertSortIndicesAtTop(_ messages: [Message]) async -> (insertedSections: IndexSet, insertedRowsInOldSectionZero: [IndexPath]) {
        let beforeRowsSectionZeroCount = sections.first?.vms.count ?? 0
        let beforeSectionCount = sections.count
        await appendSortCalculate(messages)
        let afterSectionCount = sections.count

        let newSectionCount = afterSectionCount - beforeSectionCount
        let oldSectionZeroIndex = newSectionCount

        /// 5- Set whether it has more messages at the top or not.
        /// 6- To update isLoading fields to hide the loading at the top.
        let insertedSections = IndexSet(0..<newSectionCount)
        var insertedRowsInOldSectionZero: [IndexPath] = []
        if sections.indices.contains(oldSectionZeroIndex) {
            let newCountRowsInOldSectionZero = sections[oldSectionZeroIndex].vms.count
            let insertedItems = newCountRowsInOldSectionZero - beforeRowsSectionZeroCount
            for i in 0..<insertedItems {
                insertedRowsInOldSectionZero.append(.init(row: i, section: oldSectionZeroIndex))
            }
        }
        return (insertedSections, insertedRowsInOldSectionZero)
    }

    private func insertSortIndicesAtBottom(_ messages: [Message], countBanner: Bool) async -> (insertedSections: IndexSet, insertedRowsInOldLastSection: [IndexPath]) {
        let beforeRowsCountLastSection = sections
            .last?.vms
            .filter{($0.message as? UnreadMessage) == nil } // Filter out banner
            .count ?? 0
        let beforeSectionCount = sections.count
        await appendSortCalculate(messages)
        let afterSectionCount = sections.count
        let beforeLastSectionindex = beforeSectionCount - 1

//        let newSectionCount = afterSectionCount - beforeSectionCount

        /// 5- Set whether it has more messages at the top or not.
        /// 6- To update isLoading fields to hide the loading at the top.
        let insertedSections = IndexSet(beforeSectionCount..<afterSectionCount)
        var insertedRowsInOldLastSection: [IndexPath] = []
        if sections.indices.contains(beforeLastSectionindex) {
            let newCountRowsInOldLastSection = sections[beforeLastSectionindex]
                .vms
                .filter{($0.message as? UnreadMessage) == nil}
                .count
            let insertedItems = newCountRowsInOldLastSection - beforeRowsCountLastSection
            for i in 0..<insertedItems {
                insertedRowsInOldLastSection.append(
                    .init(
                        row: beforeRowsCountLastSection + i + (countBanner ? 1 : 0), // plus one for banner
                        section: beforeLastSectionindex
                    )
                )
            }
        }
        return (insertedSections, insertedRowsInOldLastSection)
    }

    @MainActor
    private func moreTop(prepend: String = "MORE-TOP", _ toTime: UInt?) async {
        if !canLoadMoreTop { return }
        topLoading = true
        oldFirstMessageInFirstSection = sections.first?.vms.first?.message
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: viewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: prepend, value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func onMoreTop(_ response: ChatResponse<[Message]>) async {
        isInInsertionTop = true
        let messages = response.result ?? []
        /// 3- Append and sort the array but not call to update the view.
        let tuple = await insertSortIndicesAtTop(messages)
        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        delegate?.inserted(tuple.insertedSections, tuple.insertedRowsInOldSectionZero)
        await setHasMoreTop(response)
        isInInsertionTop = false
    }

    @MainActor
    private func moreBottom(prepend: String = "MORE-BOTTOM", _ fromTime: UInt?) async {
        if !hasNextBottom || bottomLoading { return }
        bottomLoading = true
        viewModel?.delegate?.startBottomAnimation(true)
        let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: viewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: prepend, value: req)
        logHistoryRequest(req: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func onMoreBottom(_ response: ChatResponse<[Message]>) async {
        isInInsertionBottom = true
        let messages = response.result ?? []
        /// 3- Append and sort the array but not call to update the view.
        let tuple = await insertSortIndicesAtBottom(messages, countBanner: false)
        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        delegate?.inserted(tuple.insertedSections, tuple.insertedRowsInOldLastSection)
        /// 7- Set whether it has more messages at the bottom or not.
        await setHasMoreBottom(response)
        isFetchedServerFirstResponse = true
        isInInsertionBottom = false
    }

    // MARK: Scenarios utilities
    @MainActor
    private func setHasMoreTop(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            topLoading = false
            viewModel?.delegate?.startBottomAnimation(false)
        }
    }

    @MainActor
    private func setHasMoreBottom(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextBottom = response.hasNext
            isFetchedServerFirstResponse = true
            bottomLoading = false
            viewModel?.delegate?.startBottomAnimation(false)
        }
    }

    @discardableResult
    private func appenedUnreadMessagesBannerIfNeeed() async -> IndexPath? {
        guard
            let tuples = message(for: thread.lastSeenMessageId),
            let viewModel = viewModel
        else { return nil }
        let time = (tuples.message.time ?? 0) + 1
        let unreadMessage = UnreadMessage(id: LocalId.unreadMessageBanner.rawValue, time: time, uniqueId: "\(LocalId.unreadMessageBanner.rawValue)")
        let indexPath = tuples.indexPath
        sections[indexPath.section].vms.append(.init(message: unreadMessage, viewModel: viewModel))
        return .init(row: sections[indexPath.section].vms.indices.last!, section: indexPath.section)
    }

    private func removeOldBanner() {
        if let indices = indicesByMessageUniqueId("\(LocalId.unreadMessageBanner.rawValue)") {
            sections[indices.section].vms.remove(at: indices.row)
        }
    }

    // MARK: Scenario 1
    private func tryFirstScenario() {
        /// 1- Get the top part to time messages
        if thread.lastMessageVO?.id ?? 0 > thread.lastSeenMessageId ?? 0, let toTime = thread.lastSeenMessageTime {
            Task {
                await moreTop(prepend: MORE_TOP_FIRST_SCENARIO_KEY, toTime.advanced(by: 1))
            }
        }
    }

    private func onMoreTopFirstScenario(_ response: ChatResponse<[Message]>) async {
        isInInsertionTop = true
        let messages = response.result ?? []
        /// 2- Append and sort  and calculate the array but not call to update the view.
        await appendSortCalculate(messages)
        let uniqueId = message(for: thread.lastSeenMessageId)?.message.uniqueId
        delegate?.reload()
        delegate?.scrollTo(uniqueId: uniqueId ?? "", position: .bottom, animate: false)
        /// 3- Get the last Seen message time.
        let lastSeenMessageTime = thread.lastSeenMessageTime
        /// 4- Fetch from time messages to get to the bottom part and new messages to stay there if the user scrolls down.
        if let fromTime = lastSeenMessageTime {
            await moreBottom(prepend: "MORE-BOTTOM-FIRST-SCENARIO", fromTime.advanced(by: 1))
        }
        /// 5- Set whether it has more messages at the top or not.
        await setHasMoreTop(response)
        isInInsertionTop = false
    }

    private func onMoreBottomFirstScenario(_ response: ChatResponse<[Message]>) async {
        isInInsertionBottom = true
        let messages = response.result ?? []
        /// 6- Append the unread message banner and after sorting it will sit below the last message seen. and it will be added into the secion of lastseen message no the new ones.
        let sorted = messages.sortedByTime()
        let bannerIndexPath = await appenedUnreadMessagesBannerIfNeeed()
        let tuple = await insertSortIndicesAtBottom(sorted, countBanner: true)
        var insertedRowsInOldLastSection = tuple.insertedRowsInOldLastSection
        if let bannerIndexPath = bannerIndexPath {
            insertedRowsInOldLastSection.append(bannerIndexPath)
        }
        delegate?.inserted(tuple.insertedSections, insertedRowsInOldLastSection)
        /// 8-  Set whether it has more messages at the bottom or not.
        await setHasMoreBottom(response)
        isInInsertionBottom = false
    }

    // MARK: Scenario 2
    private func trySecondScenario() {
        /// 1- Get the top part to time messages
        if thread.lastMessageVO?.id ?? 0 == thread.lastSeenMessageId ?? 0, let toTime = thread.lastSeenMessageTime {
            Task {
                await moreTop(prepend: MORE_TOP_SECOND_SCENARIO_KEY, toTime.advanced(by: 1))
            }
        }
    }

    private func onMoreTopSecondScenario(_ response: ChatResponse<[Message]>) async {
        isInInsertionTop = true
        let messages = response.result ?? []
        if response.result?.count ?? 0 > 0 {
            /// 2- Append and sort the array but not call to update the view and do calculaiton.
            await appendSortCalculate(messages)
            /// 4- Disable excessive loading on the top part.
            viewModel?.scrollVM.disableExcessiveLoading()
        }
        if let uniqueId = thread.lastMessageVO?.uniqueId, let messageId = thread.lastMessageVO?.id {
            delegate?.reload()
            delegate?.scrollTo(uniqueId: uniqueId, position: .bottom, animate: false)
            await viewModel?.scrollVM.showHighlightedAsync(uniqueId, messageId, highlight: false)
        }
        /// 6- Set whether it has more messages at the top or not.
        await setHasMoreTop(response)
        shimmerViewModel.hide()
        isInInsertionTop = false
    }

    // MARK: Scenario 3 or 4 more top/bottom.

    // MARK: Scenario 5
    private func tryFifthScenario(status: ConnectionStatus) {
        /// 1- Get the bottom part of the list of what is inside the memory.
        if status == .connected,
           isFetchedServerFirstResponse == true,
           viewModel?.isActiveThread == true,
           let lastMessageInListTime = sections.last?.vms.last?.message.time {

            bottomLoading = true
            viewModel?.delegate?.startBottomAnimation(true)
            let fromTime = lastMessageInListTime.advanced(by: 1)
            let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: viewModel?.readOnly == true)
            RequestsManager.shared.append(prepend: MORE_BOTTOM_FIFTH_SCENARIO_KEY, value: req)
            logHistoryRequest(req: req)
            ChatManager.activeInstance?.message.history(req)
        }
    }

    private func onMoreBottomFifthScenario(_ response: ChatResponse<[Message]>) async {
        isInInsertionBottom = true
        let messages = response.result ?? []
        /// 2- Append the unread message banner at the end of the array. It does not need to be sorted because it has been sorted by the above function.
        if response.result?.count ?? 0 > 0 {
            removeOldBanner()
            await appenedUnreadMessagesBannerIfNeeed()
            /// 3- Append and sort and calculate the array but not call to update the view.
            await appendSortCalculate(messages)
        }
        /// 4- Set whether it has more messages at the bottom or not.
        await setHasMoreBottom(response)
        isInInsertionBottom = false
    }

    // MARK: Scenario 6
    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true, moveToBottom: Bool = false) {
        Task { [weak self] in
            guard let self = self else { return }
            /// 1- Move to a message locally if it exists.
            if await moveToMessageLocally(messageId, highlight: highlight, animate: true) { return }
            sections.removeAll()
            /// 2- Fetch the top part of the message with the message itself.
            let toTimeReq = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: time.advanced(by: 1), readOnly: viewModel?.readOnly == true)
            let timeReqManager = OnMoveTime(messageId: messageId, request: toTimeReq, highlight: highlight)
            RequestsManager.shared.append(prepend: TO_TIME_KEY, value: timeReqManager)
            logHistoryRequest(req: toTimeReq)
            ChatManager.activeInstance?.message.history(toTimeReq)
        }
    }

    private func onMoveToTime(_ request: OnMoveTime, _ response: ChatResponse<[Message]>) async {
        isInInsertionTop = true
        let messages = response.result ?? []
        /// 3- Append and sort the array but not call to update the view.
        await appendSortCalculate(messages)
        /// We set this property to true because in the seven scenario there is no way to set this property to true.
        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        isFetchedServerFirstResponse = true
        /// 5- Update all the views to draw for the top part.
        /// 7- Fetch the From to time (bottom part) to have a little bit of messages from the bottom.
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: request.request.toTime?.advanced(by: -1), offset: 0, order: "asc", readOnly: viewModel?.readOnly == true)
        let fromReqManager = OnMoveTime(messageId: request.messageId, request: fromTimeReq, highlight: request.highlight)
        RequestsManager.shared.append(prepend: "FROM-TIME", value: fromReqManager)
        logHistoryRequest(req: fromTimeReq)
        ChatManager.activeInstance?.message.history(fromTimeReq)
        isInInsertionTop = false
    }

    private func onMoveFromTime(_ request: OnMoveTime, _ response: ChatResponse<[Message]>) async {
        isInInsertionBottom = true
        let messages = response.result ?? []
        /// 8- Append and sort the array but not call to update the view.
        await appendSortCalculate(messages)
        await setHasMoreBottom(response)
        /// 6- Scroll to the message with its uniqueId.
        guard let uniqueId = message(for: request.messageId)?.message.uniqueId else { return }
        await viewModel?.scrollVM.showHighlightedAsync(uniqueId, request.messageId, highlight: request.highlight)
        isInInsertionBottom = false
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    private func moveToMessageLocally(_ messageId: Int, highlight: Bool, animate: Bool = false) async -> Bool {
        if let uniqueId = message(for: messageId)?.message.uniqueId {
            await viewModel?.scrollVM.showHighlightedAsync(uniqueId, messageId, highlight: highlight, animate: animate)
            return true
        }
        return false
    }

    // MARK: Scenario 7
    /// When lastMessgeSeenId is bigger than thread.lastMessageVO.id as a result of server chat bug or when the conversation is empty.
    private func trySeventhScenario() {
        if thread.lastMessageVO?.id ?? 0 < thread.lastSeenMessageId ?? 0 {
            requestBottomPartByCountAndOffset()
        }
    }

    private func requestBottomPartByCountAndOffset() {
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, readOnly: viewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: FETCH_BY_OFFSET_KEY, value: req)
        logHistoryRequest(req: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func onFetchByOffset(_ response: ChatResponse<[Message]>) async {
        isInInsertionTop = true
        let messages = response.result ?? []
        let sortedMessages = messages.sortedByTime()
        await appendSortCalculate(sortedMessages)
        isFetchedServerFirstResponse = true
        delegate?.reload()
        await viewModel?.scrollVM.showHighlightedAsync(sortedMessages.last?.uniqueId ?? "", sortedMessages.last?.id ?? -1, highlight: false)
        isInInsertionTop = false
    }

    // MARK: Scenario 8
    /// When a new thread has been built and me is added by another person and this is our first time to visit the thread.
    private func tryEightScenario() {
        if thread.lastSeenMessageId == 0, thread.lastSeenMessageTime == nil, let lastMSGId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            moveToTime(time, lastMSGId, highlight: false)
        }
    }

    // MARK: Scenario 9
    /// When a new thread has been built and there is no message inside the thread yet.
    private func tryNinthScenario() {
        if (thread.lastSeenMessageId == 0 || thread.lastSeenMessageId == nil) && thread.lastMessageVO == nil {
            requestBottomPartByCountAndOffset()
        }
    }

    // MARK: Scenario 10
    public func moveToMessageTimeOnOpenConversation() {
        let model = AppState.shared.appStateNavigationModel
        if let id = model.moveToMessageId, let time = model.moveToMessageTime {
            moveToTime(time, id, highlight: true)
            AppState.shared.appStateNavigationModel = .init()
        }
    }

    // MARK: On Cache History Response
    private func onHistoryCacheRsponse(_ response: ChatResponse<[Message]> ) async {
        isInInsertionTop = true
        let messages = response.result ?? []
        let sortedMessages = messages.sortedByTime()
        await appendSortCalculate(sortedMessages)
        viewModel?.scrollVM.disableExcessiveLoading()
        isFetchedServerFirstResponse = false
        if response.containsPartial(prependedKey: MORE_TOP_KEY) {
            hasNextTop = messages.count >= count // We just need the top part when the user open the thread while it's not connected.
        }
        topLoading = false
        bottomLoading = false
        shimmerViewModel.hide()
        delegate?.reload()
        if !isJumpedToLastMessage {
            await viewModel?.scrollVM.showHighlightedAsync(sortedMessages.last?.uniqueId ?? "", sortedMessages.last?.id ?? -1, highlight: false)
            isJumpedToLastMessage = true
        }
        isInInsertionTop = false
    }

    // MARK: Delete Message
    internal func removeByUniqueId(_ uniqueId: String?) {
        guard let uniqueId = uniqueId, let indices = indicesByMessageUniqueId(uniqueId) else { return }
        sections[indices.section].vms.remove(at: indices.row)
    }

    public func deleteMessages(_ messages: [Message], forAll: Bool = false) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: forAll))
        viewModel?.selectedMessagesViewModel.clearSelection()
    }

    // MARK: Appending and Sorting
    internal func appendSortCalculate(_ messages: [Message]) async {
        log("Start of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
        guard messages.count > 0 else { return }
        var viewModels: [MessageRowViewModel?] = []
        let set = Set(messages)
        for message in set {
            let vm = insertOrUpdate(message)
            viewModels.append(vm)
        }
        sort()
        for viewModel in viewModels {
            await viewModel?.performaCalculation()
        }
        logger.debug("End of the appendMes sagesAndSort: \(Date().millisecondsSince1970)")
        fetchReactions(messages: messages)
    }

    fileprivate func updateMessage(_ message: Message, _ indices: IndexPath?) -> MessageRowViewModel? {
        guard let indices = indices else { return nil }
        let vm = sections[indices.section].vms[indices.row]
        if vm.uploadViewModel != nil || vm.message is UploadFileWithLocationMessage {
            /// We have to update animateObjectWillChange because after onNewMessage we will not call it, so upload file not work properly.
            vm.swapUploadMessageWith(message)
        } else {
            vm.message.updateMessage(message: message)
        }
        needUpdates.append(vm)
        return vm
    }

    private func insertIntoSection(_ message: Message) -> MessageRowViewModel? {
        if message.threadId == threadId || message.conversation?.id == threadId, let viewModel = viewModel {
            let viewModel = MessageRowViewModel(message: message, viewModel: viewModel)
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

    private func insertOrUpdate(_ message: Message) -> MessageRowViewModel? {
        let indices = findIncicesBy(uniqueId: message.uniqueId ?? "", message.id ?? -1)
        if let vm = updateMessage(message, indices) {
            return vm
        }
        return insertIntoSection(message)
    }

    private func sort() {
        log("Start of the Sort function: \(Date().millisecondsSince1970)")
        sections.indices.forEach { sectionIndex in
            sections[sectionIndex].vms.sort { m1, m2 in
                if m1 is UnreadMessageProtocol {
                    return false
                }
                if let t1 = m1.message.time, let t2 = m2.message.time {
                    return t1 < t2
                } else {
                    return false
                }
            }
        }
        sections.sort(by: {$0.date < $1.date})
        log("End of the Sort function: \(Date().millisecondsSince1970)")
    }

    private func fetchReactions(messages: [Message]) {
        if viewModel?.searchedMessagesViewModel.isInSearchMode == false {
            let messageIds = messages.filter({$0.reactionableType}).compactMap({$0.id})
//            ReactionViewModel.shared.getReactionSummary(messageIds, conversationId: threadId)
        }
    }

    // MARK: Appear & Disappear
    public func onMessageAppear(_ message: Message) {
        Task { [weak self] in
            guard let self = self else { return }
            log("Message appeared id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") message:\(message.message ?? "") isAtBottomOfTheList:\(viewModel?.scrollVM.isAtBottomOfTheList == true)")
            if message.id == thread.lastMessageVO?.id {
                viewModel?.scrollVM.isAtBottomOfTheList = true
                viewModel?.delegate?.lastMessageAppeared(true)
            }
            seenVM?.onAppear(message)
        }
    }

    public func willDisplay(_ indexPath: IndexPath) {
        guard let message = viewModelWith(indexPath)?.message else { return }
        onMessageAppear(message)
    }

    public func didEndDisplay(_ indexPath: IndexPath) {
        guard let message = viewModelWith(indexPath)?.message else { return }
        onMessegeDisappear(message)
    }

    public func loadMoreTop(message: Message) {
        if let time = message.time {
            Task { [weak self] in
                await self?.moreTop(time)
            }
        }
    }

    public func loadMoreBottom(message: Message) {
        if let time = message.time {
            Task { [weak self] in
                await self?.moreBottom(time)
            }
        }
    }

    public func onMessegeDisappear(_ message: Message) {
        Task { [weak self] in
            guard let self = self else { return }
            log("Message disappear\(message.id ?? 0) uniqueId: \(message.uniqueId ?? "")")
            if message.id == thread.lastMessageVO?.id, viewModel?.scrollVM.isAtBottomOfTheList == true {
                viewModel?.scrollVM.isAtBottomOfTheList = false
                viewModel?.delegate?.lastMessageAppeared(false)
            }
        }
    }

    public func didScrollTo(_ contentOffset: CGPoint, _ contentSize: CGSize) {
        guard let scrollVM = viewModel?.scrollVM else { return }
        if contentOffset.y > scrollVM.lastContentOffsetY {
            // scroll down
            scrollVM.scrollingUP = false
            if contentSize.height > contentSize.height + threshold, let message = sections.last?.vms.last?.message {
                loadMoreBottom(message: message)
            }
        } else {
            // scroll up
            print("scrollViewDidScroll \(contentOffset.y)")
            scrollVM.scrollingUP = true
            if contentOffset.y < threshold, let message = sections.first?.vms.first?.message {
                loadMoreTop(message: message)
            }
        }
        scrollVM.lastContentOffsetY = contentOffset.y
    }

    // MARK: Event Handlers

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
//            animateObjectWillChange()
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            if !response.cache, response.subjectId == threadId {
                Task {
                    logger.debug("Start on history:\(Date().millisecondsSince1970)")
                    /// For the first scenario.
                    if response.pop(prepend: MORE_TOP_FIRST_SCENARIO_KEY) != nil {
                        await onMoreTopFirstScenario(response)
                    }

                    if response.pop(prepend: MORE_BOTTOM_FIRST_SCENARIO_KEY) != nil {
                        await onMoreBottomFirstScenario(response)
                    }

                    if response.pop(prepend: MORE_TOP_SECOND_SCENARIO_KEY) != nil {
                        /// For the second scenario.
                        await onMoreTopSecondScenario(response)
                    }

                    /// For the scenario three and four.
                    if response.pop(prepend: MORE_TOP_KEY) != nil {
                        await onMoreTop(response)
                    }

                    /// For the scenario three and four.
                    if response.pop(prepend: MORE_BOTTOM_KEY) != nil {
                        await onMoreBottom(response)
                    }

                    /// For the fifth scenario.
                    if response.pop(prepend: MORE_BOTTOM_FIFTH_SCENARIO_KEY) != nil {
                        await onMoreBottomFifthScenario(response)
                    }

                    /// For the seventh scenario.
                    if response.pop(prepend: FETCH_BY_OFFSET_KEY) != nil {
                        await onFetchByOffset(response)
                    }

                    /// For the sixth scenario.
                    if let request = response.pop(prepend: TO_TIME_KEY) as? OnMoveTime {
                        await onMoveToTime(request, response)
                    }

                    if let request = response.pop(prepend: FROM_TIME_KEY) as? OnMoveTime {
                        await onMoveFromTime(request, response)
                    }
                    logger.debug("End on history:\(Date().millisecondsSince1970)")
                    logger.debug("End on history:\(Date().millisecondsSince1970)")
                }
            } else if response.cache && ChatManager.activeInstance?.state != .chatReady {
                Task {
                    await onHistoryCacheRsponse(response)
                }
            }
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

    private func onNewMessage(_ response: ChatResponse<Message>) {
        if threadId == response.subjectId, let message = response.result {
            isInInsertionTop = true
            let isMe = (response.result?.participant?.id ?? -1) == AppState.shared.user?.id
            Task { [weak self] in
                guard let self = self else { return }
                // MARK: Update thread properites
                /*
                 We have to set it, because in server chat response when we send a message Message.Conversation.lastSeenMessageId / Message.Conversation.lastSeenMessageTime / Message.Conversation.lastSeenMessageNanos are wrong.
                 Although in message object Message.id / Message.time / Message.timeNanos are right.
                 We only do this for ourselves, because the only person who can change these values is ourselves.
                 We do this in ThreadsViewModel too, because there is a chance of reconnect so objects are distinict
                 or if we are in forward mode the objects are different than what exist in ThreadsViewModel.
                 */
                if isMe {
                    thread.lastSeenMessageId = message.id
                    thread.lastSeenMessageTime = message.time
                    thread.lastSeenMessageNanos = message.timeNanos
                }
                thread.time = message.time
                thread.lastMessageVO = message
                thread.lastMessage = response.result?.message
                if response.result?.mentioned == true {
                    thread.mentioned = true
                }
                // MARK: End Update thread properites

                print("before: section count \(sections.count) rowsCount:\(sections.last?.vms.count ?? 0)")
                let tuple = await insertSortIndicesAtBottom([message], countBanner: false)
                /// 4- Disable excessive loading on the top part.
                viewModel?.scrollVM.disableExcessiveLoading()
                await updateNeeded()
                print("after: section count \(sections.count) rowsCount:\(sections.last?.vms.count ?? 0)")
                delegate?.inserted(tuple.insertedSections, tuple.insertedRowsInOldLastSection)
                await viewModel?.scrollVM.scrollToLastMessageIfLastMessageIsVisible(message)
                setSeenForAllOlderMessages(newMessage: message)
                isInInsertionTop = false
            }
        }
    }

    private func onEdited(_ response: ChatResponse<Message>) {
        if let message = response.result, let vm = messageViewModel(for: message.id ?? -1) {
            vm.setEdited(message)
//            Task { @MainActor in
//                await viewModel?.scrollVM.scrollToBottomIfIsAtBottom()
//            }
        }
    }

    private func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.messageId, let vm = messageViewModel(for: messageId) {
            vm.pinMessage(time: response.result?.time)
        }
    }

    private func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.messageId, let vm = messageViewModel(for: messageId) {
            vm.unpinMessage()
        }
    }

    private func onDeliver(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId else { return }
        if let messageId = response.result?.messageId, let vm = messageViewModel(for: messageId) {
            vm.setDelivered()
        }
    }

    private func onSeen(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId, let messageId = response.result?.messageId else { return }
        if let vm = messageViewModel(for: messageId) {
            vm.setSeen()
        }
        setSeenForOlderMessages(messageId: response.result?.messageId)
    }

    private func onSent(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId else { return }
        if let messageId = response.result?.messageId, let vm = messageViewModel(for: messageId) {
            vm.setSent(messageTime: response.result?.messageTime)
        }
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    internal func onDeleteMessage(_ response: ChatResponse<Message>) {
        guard let responseThreadId = response.subjectId ?? response.result?.threadId ?? response.result?.conversation?.id,
              threadId == responseThreadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId, response.result?.id)
        else { return }
        sections[indices.section].vms.remove(at: indices.row)
        if sections[indices.section].vms.count == 0 {
            sections.remove(at: indices.section)
        }
        delegate?.remove(at: indices)
    }

    // MARK: Check Same User
    internal func isLastMessageOfTheUser(_ message: Message) async -> Bool {
        guard let indexPath = self.message(for: message.id)?.indexPath else { return false }
        let sectionIndex = indexPath.section
        let nextIndex = indexPath.row + 1
        let isNextIndexExist = sections[sectionIndex].vms.indices.contains(nextIndex)
        if isNextIndexExist {
            let nextMessage = sections[sectionIndex].vms[nextIndex]
            return nextMessage.message.participant?.id != message.participant?.id
        }
        return true
    }

    internal func isFirstMessageOfTheUser(_ message: Message) async -> Bool {
        guard let indePath = self.message(for: message.id)?.indexPath else { return false }
        let sectionIndex = indePath.section
        let prevIndex = indePath.row - 1
        let isPreviousIndexExist = sections[sectionIndex].vms.indices.contains(prevIndex)
        if isPreviousIndexExist {
            let prevMessage = sections[sectionIndex].vms[prevIndex]
            return prevMessage.message.participant?.id != message.participant?.id
        }
        return true
    }

    // MARK: Logging
    private func logHistoryRequest(req: GetHistoryRequest) {
#if DEBUG
        Task.detached {
            let date = Date().millisecondsSince1970
            Logger.viewModels.debug("Start of sending history request: \(date) milliseconds")
        }
#endif
    }

    private func log(_ string: String) {
#if DEBUG
        Task.detached {
            Logger.viewModels.info("\(string, privacy: .sensitive)")
        }
#endif
    }

    // MARK: Cancel Task and Observers
    internal func cancel() {
        cancelTasks()
        cancelAllObservers()
    }

    internal func cancelTasks() {
        tasks.forEach { task in
            task.cancel()
        }
        tasks = []
    }

    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }

    // MARK: Cleanup
    @MainActor
    private func onCancelTimer(key: String) {
        if topLoading || bottomLoading {
            topLoading = false
            bottomLoading = false
            viewModel?.delegate?.startTopAnimation(false)
            viewModel?.delegate?.startBottomAnimation(false)
        }
    }

    // MARK: On Notifications actions
    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if !isSimulated, status == .connected, isFetchedServerFirstResponse == true, viewModel?.isActiveThread == true {
            // After connecting again get latest messages.
            tryFifthScenario(status: status)
        }

        /// Fetch the history for the first time if the internet connection is not available.
        if !isSimulated, status == .connected, hasSentHistoryRequest == true, sections.isEmpty {
            startFetchingHistory()
        }
    }

    private func setHighlight(messageId: Int) {
        if let vm = messageViewModel(for: messageId) {
            vm.setHighlight()
        }
    }

    private func setRowsIsInSelectMode(newValue: Bool) {
        sections.forEach { section in
            section.vms.forEach { vm in
                if newValue != vm.state.isInSelectMode {
                    vm.state.isInSelectMode = newValue
                    vm.animateObjectWillChange()
                }
            }
        }
    }

    private func updateAllRows() {
        sections.forEach { section in
            section.vms.forEach { vm in
                Task {
                    await vm.recalculateWithAnimation()
                }
            }
        }
    }

    // MARK: New Message handlers
    private func updateNeeded() async {
        for (_, vm) in needUpdates.enumerated() {
//            vm.reconfigRow()
        }
        needUpdates.removeAll()
    }

    /// When you have sent messages for example 5 messages and your partner didn't read messages and send a message directly it will send you only one seen.
    /// So you have to set seen to true for older unread messages you have sent, because the partner has read all messages and after you back to the list of thread the server will respond with seen == true for those messages.
    private func setSeenForAllOlderMessages(newMessage: Message) {
        let unseenMessages = sections.last?.vms.filter({($0.message.seen == false || $0.message.seen == nil) && $0.message.isMe(currentUserId: AppState.shared.user?.id)})
        let isNotMe = !newMessage.isMe(currentUserId: AppState.shared.user?.id)
        if isNotMe, unseenMessages?.count ?? 0 > 0 {
            unseenMessages?.forEach { vm in
                vm.message.seen = true
//                vm.reconfigRow()
            }
        }
    }

    private func setSeenForOlderMessages(messageId: Int?) {
        if let messageId = messageId {
            let isMeId = ChatManager.activeInstance?.userInfo?.id ?? 0
            sections
                .flatMap { $0.vms }
                .filter {
                    let message = $0.message
                    let notDelivered = message.delivered ?? false == false
                    let notSeen = message.seen ?? false == false
                    let isValidToChange = (message.id ?? 0 < messageId) && (notSeen || notDelivered) && message.ownerId == isMeId
                    return isValidToChange
                }
                .forEach { vm in
                    vm.message.delivered = true
                    vm.message.seen = true
//                    vm.reconfigRow()
                }
        }        
    }

    // MARK: Finding index and ViewModels
    public func viewModelWith(_ indexPath: IndexPath) -> MessageRowViewModel? {
        if sections.indices.contains(indexPath.section), sections[indexPath.section].vms.indices.contains(indexPath.row) {
            return sections[indexPath.section].vms[indexPath.row]
        } else {
            return nil
        }
    }

    private func isInTopSlice(_ messageId: Int?) -> Bool {
        return messageId ?? 0 <= topSliceId
    }

    private func isInBottomSlice(_ messageId: Int?) -> Bool {
        return messageId ?? 0 >= bottomSliceId
    }

    private func sectionIndexByUniqueId(_ message: Message) -> Array<MessageSection>.Index? {
        sectionIndexByUniqueId(message.uniqueId ?? "")
    }

    internal func sectionIndexByUniqueId(_ uniqueId: String) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { $0.vms.contains(where: {$0.message.uniqueId == uniqueId }) })
    }

    internal func sectionIndexByMessageId(_ message: Message) -> Array<MessageSection>.Index? {
        sectionIndexByMessageId(message.id ?? 0)
    }

    private func sectionIndexByMessageId(_ id: Int) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { $0.vms.contains(where: {$0.message.id == id }) })
    }

    private func sectionIndexByDate(_ date: Date) -> Array<MessageSection>.Index? {
        sections.firstIndex(where: { Calendar.current.isDate(date, inSameDayAs: $0.date)})
    }

    internal func messageIndex(_ messageId: Int, in section: Array<MessageSection>.Index) -> Array<Message>.Index? {
        sections[section].vms.firstIndex(where: { $0.id == messageId })
    }

    private func messageIndex(_ uniqueId: String, in section: Array<MessageSection>.Index) -> Array<Message>.Index? {
        sections[section].vms.firstIndex(where: { $0.message.uniqueId == uniqueId })
    }

    internal func message(for id: Int?) -> (message: Message, indexPath: IndexPath)? {
        guard
            let id = id,
            let sectionIndex = sectionIndexByMessageId(id),
            let messageIndex = messageIndex(id, in: sectionIndex)
        else { return nil }
        let message = sections[sectionIndex].vms[messageIndex].message
        return (message: message, indexPath: .init(row: messageIndex, section: sectionIndex))
    }

    public func indicesByMessageUniqueId(_ uniqueId: String) -> IndexPath? {
        guard
            let sectionIndex = sectionIndexByUniqueId(uniqueId),
            let messageIndex = messageIndex(uniqueId, in: sectionIndex)
        else { return nil }
        return .init(row: messageIndex, section: sectionIndex)
    }

    internal func findIncicesBy(uniqueId: String?, _ id: Int?) -> IndexPath? {
        guard
            let sectionIndex = sections.firstIndex(where: { $0.vms.contains(where: { $0.message.uniqueId == uniqueId || $0.id == id }) }),
            let messageIndex = sections[sectionIndex].vms.firstIndex(where: { $0.message.uniqueId == uniqueId || $0.id == id })
        else { return nil }
        return .init(row: messageIndex, section: sectionIndex)
    }

    public func indexPath(for viewModel: MessageRowViewModel) -> IndexPath? {
        guard
        let sectionIndex = sections.firstIndex(where: { $0.vms.contains(where: { $0.id == viewModel.id }) }),
        let messageIndex = sections[sectionIndex].vms.firstIndex(where: { $0.id == viewModel.id })
        else { return nil }
        return .init(row: messageIndex, section: sectionIndex)
    }

    @discardableResult
    public func messageViewModel(for messageId: Int) -> MessageRowViewModel? {
        return sections.flatMap{$0.vms}.first(where: { $0.message.id == messageId })
    }

    @discardableResult
    public func messageViewModel(for uniqueId: String) -> MessageRowViewModel? {
        guard let indicies = indicesByMessageUniqueId(uniqueId) else {return nil}
        return sections[indicies.section].vms[indicies.row]
    }

    /// We retrieve previous message when messages are beneath the sand bar.
    public func previous(_ message: Message) -> Message? {
        guard let indices = self.message(for: message.id) else { return nil }
        let message = inSameSection(indices) ?? inPrevSection(indices)
        return message
    }

    public func inPrevSection(_ indices: Indices) -> Message? {
        let prevSectionIndex = indices.indexPath.section - 1
        if indices.indexPath.row == 0, sections.count > 1 {
            if !sections.indices.contains(prevSectionIndex) {
                return nil
            } else if sections[prevSectionIndex].vms.isEmpty {
                return nil
            }
            let prevSection = sections[prevSectionIndex]
            return prevSection.vms.last?.message
        } else {
            return nil
        }
    }

    public func inSameSection(_ indices: Indices) -> Message? {
        let prevIndex = indices.indexPath.row - 1
        if sections[indices.indexPath.section].vms.indices.contains(prevIndex) {
            // we have preve in the same section
            return sections[indices.indexPath.section].vms[prevIndex].message
        } else {
            return nil
        }
    }

    public func isLastSeenMessageExist() -> Bool {
        let lastSeenId = thread.lastSeenMessageId
        if lastSeenIsGreaterThanLastMessage() { return true }
        guard let lastSeenId = lastSeenId else { return false }
        var isExist = false
        // we get two bottom to check if it is in today list or previous day
        for section in sections.suffix(2) {
            if section.vms.contains(where: {$0.message.id == lastSeenId }) {
                isExist = true
            }
        }
        return isExist
    }

    /// When we delete the last message, lastMessageSeenId is greater than currently lastMessageVO.id
    /// which is totally wrong and causes a lot of problems.
    private func lastSeenIsGreaterThanLastMessage() -> Bool {
        return thread.lastSeenMessageId ?? 0 > thread.lastMessageVO?.id ?? 0
    }

    // MARK: Register Notifications
    private func setupNotificationObservers() {
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
            .sink { newValue in
                if let key = newValue.object as? String {
                    Task { [weak self] in
                        await self?.onCancelTimer(key: key)
                    }
                }
            }
            .store(in: &cancelable)
        NotificationCenter.windowMode.publisher(for: .windowMode)
            .sink { [weak self] newValue in
                self?.updateAllRows()
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: Notification.Name("HIGHLIGHT"))
            .compactMap {$0.object as? Int}
            .sink { [weak self] newValue in
                self?.setHighlight(messageId: newValue)
            }
            .store(in: &cancelable)
//        viewModel?.selectedMessagesViewModel.$isInSelectMode
//            .sink { [weak self] newValue in
//                self?.setRowsIsInSelectMode(newValue: newValue)
//            }
//            .store(in: &cancelable)
        NotificationCenter.upload.publisher(for: .upload)
            .sink { [weak self] notification in
                self?.onUploadEvents(notification)
            }
            .store(in: &cancelable)
    }
}

extension ThreadHistoryViewModel: StabledVisibleMessageDelegate {
    func onStableVisibleMessages(_ messages: [Message]) {
        let invalidVisibleMessages = getInvalidVisibleMessages()
        if invalidVisibleMessages.count > 0 {
            viewModel?.reactionViewModel.fetchReactions(messages: invalidVisibleMessages)
        }
    }
}

extension ThreadHistoryViewModel {
    internal func getInvalidVisibleMessages() -> [Message] {
        var invalidMessages: [Message] =  []
        visibleTracker.visibleMessages.forEach { message in
            if let vm = messageViewModel(for: message.id ?? -1), vm.isInvalid {
                invalidMessages.append(message)
            }
        }
        return invalidMessages
    }
}
