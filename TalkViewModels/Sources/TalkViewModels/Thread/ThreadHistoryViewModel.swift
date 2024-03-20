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

public final class ThreadHistoryViewModel: ObservableObject {
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
    private weak var threadViewModel: ThreadViewModel?
    private var hasSentHistoryRequest = false
    public var shimmerViewModel: ShimmerViewModel = .init(delayToHide: 0)
    internal var seenVM: HistorySeenViewModel
    public var created: Bool = false

    // MARK: Computed Properties
    public var isEmptyThread: Bool {
        let noMessage = isFetchedServerFirstResponse == true && sections.count == 0
        let emptyThread = threadViewModel?.isSimulatedThared == true
        return emptyThread || noMessage
    }
    private var thread: Conversation { threadViewModel?.thread ?? .init(id: -1) }
    private var threadId: Int { thread.id ?? -1 }
    public var canLoadMoreTop: Bool { hasNextTop && !topLoading }
    public var canLoadMoreBottom: Bool { !bottomLoading && sections.last?.vms.last?.id != thread.lastMessageVO?.id && hasNextBottom }
    private var isSimulated: Bool { threadViewModel?.isSimulatedThared == true }
    public typealias Indices = (message: Message, indexPath: IndexPath)

    // MARK: Initializer
    public init(threadViewModel: ThreadViewModel) {
        self.threadViewModel = threadViewModel
        seenVM = HistorySeenViewModel(threadViewModel: threadViewModel)
        setupNotificationObservers()
    }

    // MARK: Scenarios Common Functions
    public func start() {
        /// After deleting a thread it will again tries to call histroy,
        /// we should prevent it from calling it to not get any error.
        if isFetchedServerFirstResponse == false {
            startFetchingHistory()
            threadViewModel?.threadsViewModel?.clearAvatarsOnSelectAnotherThread()
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
        let isSimulatedThread = threadViewModel?.isSimulatedThared == true
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
        await appendMessagesAndSort(messages)
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

    private func insertSortIndicesAtBottom(_ messages: [Message]) async -> (insertedSections: IndexSet, insertedRowsInOldLastSection: [IndexPath]) {
        let beforeRowsCountLastSection = sections
            .last?.vms
            .filter{($0.message as? UnreadMessage) == nil } // Filter out banner
            .count ?? 0
        let beforeSectionCount = sections.count
        await appendMessagesAndSort(messages)
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
                        row: beforeRowsCountLastSection + i + 1, // plus one for banner
                        section: beforeLastSectionindex
                    )
                )
            }
        }
        return (insertedSections, insertedRowsInOldLastSection)
    }

    private func moreTop(prepend: String = "MORE-TOP", delay: TimeInterval = 0.5, _ toTime: UInt?) {
        if !canLoadMoreTop { return }
        topLoading = true
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: threadViewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: prepend, value: req)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            if self != nil {
                self?.logHistoryRequest(req: req)
                ChatManager.activeInstance?.message.history(req)
            }
        }
    }

    private func onMoreTop(_ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
        /// 3- Append and sort the array but not call to update the view.
        let tuple = await insertSortIndicesAtTop(messages)
        /// 4- Disable excessive loading on the top part.
        threadViewModel?.scrollVM.disableExcessiveLoading()
        delegate?.inserted(tuple.insertedSections, tuple.insertedRowsInOldSectionZero)
        await setHasMoreTop(response)
        isFetchedServerFirstResponse = true
    }

    private func moreBottom(prepend: String = "MORE-BOTTOM", _ fromTime: UInt?) {
        if !hasNextBottom || bottomLoading { return }
        bottomLoading = true
        animateObjectWillChange()
        let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: threadViewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: prepend, value: req)
        logHistoryRequest(req: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func onMoreBottom(_ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
        /// 3- Append and sort the array but not call to update the view.
        let tuple = await insertSortIndicesAtBottom(messages)
        /// 4- Disable excessive loading on the top part.
        threadViewModel?.scrollVM.disableExcessiveLoading()
        delegate?.inserted(tuple.insertedSections, tuple.insertedRowsInOldLastSection)
        /// 7- Set whether it has more messages at the bottom or not.
        await setHasMoreBottom(response)
        isFetchedServerFirstResponse = true
    }

    // MARK: Scenarios utilities
    private func setHasMoreTop(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            topLoading = false
        }
    }

    private func setHasMoreBottom(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextBottom = response.hasNext
            isFetchedServerFirstResponse = true
            bottomLoading = false
        }
    }

    @discardableResult
    private func appenedUnreadMessagesBannerIfNeeed() async -> IndexPath? {
        guard
            let tuples = message(for: thread.lastSeenMessageId),
            let threadViewModel = threadViewModel
        else { return nil }
        let time = (tuples.message.time ?? 0) + 1
        let unreadMessage = UnreadMessage(id: LocalId.unreadMessageBanner.rawValue, time: time, uniqueId: "\(LocalId.unreadMessageBanner.rawValue)")
        let indexPath = tuples.indexPath
        sections[indexPath.section].vms.append(.init(message: unreadMessage, viewModel: threadViewModel))
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
            moreTop(prepend: "MORE-TOP-FIRST-SCENARIO", delay: TimeInterval(0), toTime.advanced(by: 1))
        }
    }

    private func onMoreTopFirstScenario(_ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
        /// 2- Append and sort  and calculate the array but not call to update the view.
        await appendMessagesAndSort(messages)
        let uniqueId = message(for: thread.lastSeenMessageId)?.message.uniqueId
        delegate?.reload()
        delegate?.scrollTo(uniqueId: uniqueId ?? "", position: .bottom)
        /// 3- Get the last Seen message time.
        let lastSeenMessageTime = thread.lastSeenMessageTime
        /// 4- Fetch from time messages to get to the bottom part and new messages to stay there if the user scrolls down.
        if let fromTime = lastSeenMessageTime {
            moreBottom(prepend: "MORE-BOTTOM-FIRST-SCENARIO", fromTime.advanced(by: 1))
        }
        /// 5- Set whether it has more messages at the top or not.
        await setHasMoreTop(response)
    }

    private func onMoreBottomFirstScenario(_ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
        /// 6- Append the unread message banner and after sorting it will sit below the last message seen. and it will be added into the secion of lastseen message no the new ones.
        let sorted = messages.sortedByTime()
        let bannerIndexPath = await appenedUnreadMessagesBannerIfNeeed()
        let tuple = await insertSortIndicesAtBottom(sorted)
        var insertedRowsInOldLastSection = tuple.insertedRowsInOldLastSection
        if let bannerIndexPath = bannerIndexPath {
            insertedRowsInOldLastSection.append(bannerIndexPath)
        }
        delegate?.inserted(tuple.insertedSections, insertedRowsInOldLastSection)
        /// 8-  Set whether it has more messages at the bottom or not.
        await setHasMoreBottom(response)
    }

    // MARK: Scenario 2
    private func trySecondScenario() {
        /// 1- Get the top part to time messages
        if thread.lastMessageVO?.id ?? 0 == thread.lastSeenMessageId ?? 0, let toTime = thread.lastSeenMessageTime {
            moreTop(prepend: "MORE-TOP-SECOND-SCENARIO", toTime.advanced(by: 1))
        }
    }

    private func onMoreTopSecondScenario(_ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
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
            delegate?.reload()
            delegate?.scrollTo(uniqueId: uniqueId, position: .bottom)
            await threadViewModel?.scrollVM.showHighlightedAsync(uniqueId, messageId, highlight: false)
        }
        /// 6- Set whether it has more messages at the top or not.
        await setHasMoreTop(response)
        shimmerViewModel.hide()
    }

    // MARK: Scenario 3 or 4 more top/bottom.

    // MARK: Scenario 5
    private func tryFifthScenario(status: ConnectionStatus) {
        /// 1- Get the bottom part of the list of what is inside the memory.
        if status == .connected,
           isFetchedServerFirstResponse == true,
           threadViewModel?.isActiveThread == true,
           let lastMessageInListTime = sections.last?.vms.last?.message.time {
            bottomLoading = true
            animateObjectWillChange()
            let fromTime = lastMessageInListTime.advanced(by: 1)
            let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: threadViewModel?.readOnly == true)
            RequestsManager.shared.append(prepend: "MORE-BOTTOM-FIFTH-SCENARIO", value: req)
            logHistoryRequest(req: req)
            ChatManager.activeInstance?.message.history(req)
        }
    }

    private func onMoreBottomFifthScenario(_ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
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

    // MARK: Scenario 6
    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true) {
        Task { [weak self] in
            guard let self = self else { return }
            /// 1- Move to a message locally if it exists.
            if await moveToMessageLocally(messageId, highlight: highlight) { return }
            sections.removeAll()
            /// 2- Fetch the top part of the message with the message itself.
            let toTimeReq = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: time.advanced(by: 1), readOnly: threadViewModel?.readOnly == true)
            let timeReqManager = OnMoveTime(messageId: messageId, request: toTimeReq, highlight: highlight)
            RequestsManager.shared.append(prepend: "TO-TIME", value: timeReqManager)
            logHistoryRequest(req: toTimeReq)
            ChatManager.activeInstance?.message.history(toTimeReq)
        }
    }

    private func onMoveToTime(_ request: OnMoveTime, _ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
        /// 3- Append and sort the array but not call to update the view.
        await appendMessagesAndSort(messages)
        /// We set this property to true because in the seven scenario there is no way to set this property to true.
        /// 4- Disable excessive loading on the top part.
        threadViewModel?.scrollVM.disableExcessiveLoading()
        isFetchedServerFirstResponse = true
        /// 5- Update all the views to draw for the top part.
        /// 7- Fetch the From to time (bottom part) to have a little bit of messages from the bottom.
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: request.request.toTime?.advanced(by: -1), offset: 0, order: "asc", readOnly: threadViewModel?.readOnly == true)
        let fromReqManager = OnMoveTime(messageId: request.messageId, request: fromTimeReq, highlight: request.highlight)
        RequestsManager.shared.append(prepend: "FROM-TIME", value: fromReqManager)
        logHistoryRequest(req: fromTimeReq)
        ChatManager.activeInstance?.message.history(fromTimeReq)
    }

    private func onMoveFromTime(_ request: OnMoveTime, _ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
        /// 8- Append and sort the array but not call to update the view.
        await appendMessagesAndSort(messages)
        await setHasMoreBottom(response)
        /// 6- Scroll to the message with its uniqueId.
        guard let uniqueId = message(for: request.messageId)?.message.uniqueId else { return }
        await threadViewModel?.scrollVM.showHighlightedAsync(uniqueId, request.messageId, highlight: request.highlight)
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    private func moveToMessageLocally(_ messageId: Int, highlight: Bool) async -> Bool {
        if let uniqueId = message(for: messageId)?.message.uniqueId {
            await threadViewModel?.scrollVM.showHighlightedAsync(uniqueId, messageId, highlight: highlight)
            return true
        }
        return false
    }

    // MARK: Scenario 7
    /// When lastMessgeSeenId is bigger than thread.lastMessageVO.id as a result of server chat bug.
    private func trySeventhScenario() {
        if thread.lastMessageVO?.id ?? 0 < thread.lastSeenMessageId ?? 0 {
            requestBottomPartByCountAndOffset()
        }
    }

    private func requestBottomPartByCountAndOffset() {
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, readOnly: threadViewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: "FETCH-BY-OFFSET", value: req)
        logHistoryRequest(req: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func onFetchByOffset(_ response: ChatResponse<[Message]>) async {
        let messages = response.result ?? []
        let sortedMessages = messages.sortedByTime()
        await appendMessagesAndSort(sortedMessages)
        isFetchedServerFirstResponse = true
        await asyncAnimateObjectWillChange()
        await threadViewModel?.scrollVM.showHighlightedAsync(sortedMessages.last?.uniqueId ?? "", sortedMessages.last?.id ?? -1, highlight: false)
        shimmerViewModel.hide()
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

    // MARK: Delete Message
    internal func removeByUniqueId(_ uniqueId: String?) {
        guard let uniqueId = uniqueId, let indices = indicesByMessageUniqueId(uniqueId) else { return }
        sections[indices.section].vms.remove(at: indices.row)
    }

    public func deleteMessages(_ messages: [Message], forAll: Bool = false) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: forAll))
        threadViewModel?.selectedMessagesViewModel.clearSelection()
    }

    // MARK: Appending and Sorting
    internal func appendMessagesAndSort(_ messages: [Message], isToTime: Bool = false) async {
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
        logger.debug("End of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
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
        return vm
    }

    private func insertIntoSection(_ message: Message) -> MessageRowViewModel? {
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

    private func insertOrUpdate(_ message: Message) -> MessageRowViewModel? {
        let indices = findIncicesBy(uniqueId: message.uniqueId ?? "", message.id ?? -1)
        if let vm = updateMessage(message, indices) {
            return vm
        }
        return insertIntoSection(message)
    }

    private func sort() {
        let logger = Logger.viewModels
        logger.debug("Start of the Sort function: \(Date().millisecondsSince1970)")
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
        logger.debug("End of the Sort function: \(Date().millisecondsSince1970)")
    }

    internal func appendToNeedUpdate(_ vm: MessageRowViewModel) {
        needUpdates.append(vm)
    }

    private func fetchReactions(messages: [Message]) {
        if threadViewModel?.searchedMessagesViewModel.isInSearchMode == false {
            let messageIds = messages.filter({$0.reactionableType}).compactMap({$0.id})
            ReactionViewModel.shared.getReactionSummary(messageIds, conversationId: threadId)
        }
    }

    // MARK: Appear & Disappear    
    public func onMessageAppear(_ message: Message) {
        log("Message appear\(message.id ?? 0) uniqueId: \(message.uniqueId ?? "")")
        guard let threadVM = threadViewModel else { return }
        Task { [weak self] in
            guard let self = self else { return }
            if message.id == thread.lastMessageVO?.id, threadVM.scrollVM.isAtBottomOfTheList == false {
                threadVM.scrollVM.isAtBottomOfTheList = true
            }
            seenVM.onAppear(message)
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
            moreTop(time)
        }
    }

    public func loadMoreBottom(message: Message) {
        if let time = message.time {
            moreBottom(time)
        }
    }

    public func onMessegeDisappear(_ message: Message) {
        log("Message disappear\(message.id ?? 0) uniqueId: \(message.uniqueId ?? "")")
        if message.id == thread.lastMessageVO?.id, threadViewModel?.scrollVM.isAtBottomOfTheList == true {
            threadViewModel?.scrollVM.isAtBottomOfTheList = false            
        }
    }

    public func didScrollTo(_ contentOffset: CGPoint, _ contentSize: CGSize) {
        guard let scrollVM = threadViewModel?.scrollVM else { return }
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

    private func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            let logger = Logger.viewModels
            if !response.cache, response.subjectId == threadId {
                Task {
                    logger.debug("Start on history:\(Date().millisecondsSince1970)")
                    /// For the first scenario.
                    if response.pop(prepend: "MORE-TOP-FIRST-SCENARIO") != nil {
                        await onMoreTopFirstScenario(response)
                    }

                    if response.pop(prepend: "MORE-BOTTOM-FIRST-SCENARIO") != nil {
                        await onMoreBottomFirstScenario(response)
                    }

                    if response.pop(prepend: "MORE-TOP-SECOND-SCENARIO") != nil {
                        /// For the second scenario.
                        await onMoreTopSecondScenario(response)
                    }

                    /// For the scenario three and four.
                    if response.pop(prepend: "MORE-TOP") != nil {
                        await onMoreTop(response)
                    }

                    /// For the scenario three and four.
                    if response.pop(prepend: "MORE-BOTTOM") != nil {
                        await onMoreBottom(response)
                    }

                    /// For the fifth scenario.
                    if response.pop(prepend: "MORE-BOTTOM-FIFTH-SCENARIO") != nil {
                        await onMoreBottomFifthScenario(response)
                    }

                    /// For the seventh scenario.
                    if response.pop(prepend: "FETCH-BY-OFFSET") != nil {
                        await onFetchByOffset(response)
                    }

                    /// For the sixth scenario.
                    if let request = response.pop(prepend: "TO-TIME") as? OnMoveTime {
                        await onMoveToTime(request, response)
                    }

                    if let request = response.pop(prepend: "FROM-TIME") as? OnMoveTime {
                        await onMoveFromTime(request, response)
                    }
                    logger.debug("End on history:\(Date().millisecondsSince1970)")
                }
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

    private func onNewMessage(_ response: ChatResponse<Message>) {
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
        animateObjectWillChange()
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
        let date = Date().millisecondsSince1970
        Logger.viewModels.debug("Start of sending history request: \(date) milliseconds")
#endif
    }

    private func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }

    // MARK: Cancel Observers
    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }

    // MARK: Cleanup
    private func onCancelTimer(key: String) {
        if topLoading || bottomLoading {
            topLoading = false
            bottomLoading = false
            animateObjectWillChange()
        }
    }

    // MARK: On Notifications actions
    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if !isSimulated, status == .connected, isFetchedServerFirstResponse == true, threadViewModel?.isActiveThread == true {
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
                if newValue != vm.isInSelectMode {
                    vm.isInSelectMode = newValue
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
            await vm.asyncAnimateObjectWillChange()
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
                vm.animateObjectWillChange()
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
                    vm.animateObjectWillChange()
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

}
