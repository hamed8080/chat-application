//
//  ThreadHistoryViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Foundation
import Chat
import OSLog
import TalkModels
import Combine
import UIKit

public typealias MessageType = any HistoryMessageProtocol
public typealias MessageIndex = Array<MessageType>.Index
public typealias SectionIndex = Array<MessageSection>.Index
public typealias HistoryResponse = ChatResponse<[Message]>

//@HistoryActor
public final class ThreadHistoryViewModel {
    // MARK: Stored Properties
    private weak var viewModel: ThreadViewModel?
    public weak var delegate: HistoryScrollDelegate?
    public var sections: ContiguousArray<MessageSection> = .init()

    @HistoryActor private var threshold: CGFloat = 800
    private var created: Bool = false
    private var isInInsertionTop = false
    private var isInInsertionBottom = false
    private var topLoading = false
    private var bottomLoading = false
    private var hasNextTop = true
    private var hasNextBottom = true
    private let count: Int = 25
    private var oldFirstMessageInFirstSection: (any HistoryMessageProtocol)?
    private var isFetchedServerFirstResponse: Bool = false
    private var cancelable: Set<AnyCancellable> = []
    private var hasSentHistoryRequest = false
    internal var seenVM: HistorySeenViewModel? { viewModel?.seenVM }
    private var isJumpedToLastMessage = false
    private var tasks: [Task<Void, Error>] = []
    private var visibleTracker = VisibleMessagesTracker()
    private var isEmptyThread = false
    private var lastItemIdInSections = 0
    private let keys = RequestKeys()
    private var highlightTask: Task<Void, Never>?

    // MARK: Computed Properties
    private var thread: Conversation { viewModel?.thread ?? .init(id: -1) }
    private var threadId: Int { thread.id ?? -1 }
    private var isSimulated: Bool { viewModel?.isSimulatedThared == true }

    // MARK: Initializer
    nonisolated public init() {}
}

extension ThreadHistoryViewModel: StabledVisibleMessageDelegate {
    func onStableVisibleMessages(_ messages: [MessageType]) {
        Task { @HistoryActor [weak self] in
            guard let self = self else { return }
            let invalidVisibleMessages = await getInvalidVisibleMessages().compactMap({$0 as? Message})
            if invalidVisibleMessages.count > 0 {
                viewModel?.reactionViewModel.fetchReactions(messages: invalidVisibleMessages)
            }
        }
    }
}

extension ThreadHistoryViewModel {
    internal func getInvalidVisibleMessages() async -> [MessageType] {
        var invalidMessages: [Message] =  []
        let list = await visibleTracker.visibleMessages.compactMap({$0 as? Message})
        for message in list {
            if let vm = sections.messageViewModel(for: message.id ?? -1), vm.isInvalid {
                invalidMessages.append(message)
            }
        }
        return invalidMessages
    }
}

extension Message: HistoryMessageProtocol {}

// MARK: Setup/Start
extension ThreadHistoryViewModel {
    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        visibleTracker.delegate = self
        setupNotificationObservers()
    }

    // MARK: Scenarios Common Functions
    public func start() {
        Task { @HistoryActor in
            /// After deleting a thread it will again tries to call histroy,
            /// we should prevent it from calling it to not get any error.
            if isFetchedServerFirstResponse == false {
                await startFetchingHistory()
                await viewModel?.threadsViewModel?.clearAvatarsOnSelectAnotherThread()
            } else if isFetchedServerFirstResponse == true {
                /// try to open reply privately if user has tried to click on  reply privately and back button multiple times
                /// iOS has a bug where it tries to keep the object in the memory, so multiple back and forward doesn't lead to destroy the object.
                await moveToMessageTimeOnOpenConversation()
            }
        }
    }

    /// On Thread view, it will start calculating to fetch what part of [top, bottom, both top and bottom] receive.
    private func startFetchingHistory() async {
        /// We check this to prevent recalling these methods when the view reappears again.
        /// If centerLoading is true it is mean theat the array has gotten clear for Scenario 6 to move to a time.
        let isSimulatedThread = viewModel?.isSimulatedThared == true
        let hasAnythingToLoadOnOpen = AppState.shared.appStateNavigationModel.moveToMessageId != nil
        await moveToMessageTimeOnOpenConversation()
        await setIsEmptyThread()
        if sections.count > 0 || hasAnythingToLoadOnOpen || isSimulatedThread { return }
        hasSentHistoryRequest = true
        tryFirstScenario()
        trySecondScenario()
        trySeventhScenario()
        await tryEightScenario()
        tryNinthScenario()
    }
}

// MARK: Scenarios
extension ThreadHistoryViewModel {
    // MARK: Scenario 1
    private func tryFirstScenario() {
        /// 1- Get the top part to time messages
        if thread.lastMessageVO?.id ?? 0 > thread.lastSeenMessageId ?? 0, let toTime = thread.lastSeenMessageTime {
            Task {
                await moreTop(prepend: keys.MORE_TOP_FIRST_SCENARIO_KEY, toTime.advanced(by: 1))
            }
        }
    }

    private func onMoreTopFirstScenario(_ messages: [Message], _ response: HistoryResponse) async {
        await onMoreTop(messages, response)

        let uniqueId = sections.message(for: thread.lastSeenMessageId)?.message.uniqueId
        delegate?.scrollTo(uniqueId: uniqueId ?? "", position: .bottom, animate: false)

        /// 4- Fetch from time messages to get to the bottom part and new messages to stay there if the user scrolls down.
        if let fromTime = thread.lastSeenMessageTime {
            viewModel?.scrollVM.isProgramaticallyScroll = false
            if let bannerIndexPath = await appenedUnreadMessagesBannerIfNeeed() {
                delegate?.inserted(at: bannerIndexPath)
            }
            await moreBottom(prepend: keys.MORE_BOTTOM_FIRST_SCENARIO_KEY, fromTime.advanced(by: 1))
        }
        viewModel?.delegate?.startCenterAnimation(false)
    }

    private func onMoreBottomFirstScenario(_ messages: [Message], _ response: HistoryResponse) async {
        await onMoreBottom(messages, response)
    }

    // MARK: Scenario 2
    private func trySecondScenario() {
        /// 1- Get the top part to time messages
        if thread.lastMessageVO?.id ?? 0 == thread.lastSeenMessageId ?? 0, let toTime = thread.lastSeenMessageTime {
            Task {
                hasNextBottom = false
                await moreTop(prepend: keys.MORE_TOP_SECOND_SCENARIO_KEY, toTime.advanced(by: 1))
            }
        }
    }

    private func onMoreTopSecondScenario(_ messages: [Message], _ response: HistoryResponse) async {
        await onMoreTop(messages, response)
        if let uniqueId = thread.lastMessageVO?.uniqueId, let messageId = thread.lastMessageVO?.id {
            delegate?.reload()
            delegate?.scrollTo(uniqueId: uniqueId, position: .bottom, animate: false)
            await viewModel?.scrollVM.showHighlightedAsync(uniqueId, messageId, highlight: false)
        }
        viewModel?.delegate?.startCenterAnimation(false)
        await fetchReactions(messages: messages)
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
            RequestsManager.shared.append(prepend: keys.MORE_BOTTOM_FIFTH_SCENARIO_KEY, value: req)
            logHistoryRequest(req: req)
            ChatManager.activeInstance?.message.history(req)
        }
    }

    private func onMoreBottomFifthScenario(_ messages: [Message], _ response: HistoryResponse) async {
        isInInsertionBottom = true
        /// 2- Append the unread message banner at the end of the array. It does not need to be sorted because it has been sorted by the above function.
        if response.result?.count ?? 0 > 0 {
            removeOldBanner()
            await appenedUnreadMessagesBannerIfNeeed()
            /// 3- Append and sort and calculate the array but not call to update the view.
            let sortedMessages = messages.sortedByTime()
            let viewModels = await createCalculateAppendSort(sortedMessages)
            for vm in viewModels {
                await vm.register()
            }
        }
        /// 4- Set whether it has more messages at the bottom or not.
        await setHasMoreBottom(response)
        isInInsertionBottom = false
        bottomLoading = false
        viewModel?.delegate?.startBottomAnimation(false)
        viewModel?.delegate?.startCenterAnimation(false)
        await fetchReactions(messages: messages)
    }

    // MARK: Scenario 6
    public func moveToTime(_ time: UInt, _ messageId: Int, highlight: Bool = true, moveToBottom: Bool = false) async {
        /// 1- Move to a message locally if it exists.
        if moveToBottom, !sections.isLastSeenMessageExist(thread: thread) {
            sections.removeAll()
        } else if await moveToMessageLocally(messageId, highlight: highlight, animate: true) {
            return
        } else {
            log("The message id to move to is not exist in the list")
        }
        viewModel?.delegate?.startCenterAnimation(true)
        sections.removeAll()
        delegate?.reload()
        /// 2- Fetch the top part of the message with the message itself.
        let toTimeReq = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: time.advanced(by: 1), readOnly: viewModel?.readOnly == true)
        let timeReqManager = OnMoveTime(messageId: messageId, request: toTimeReq, highlight: highlight)
        RequestsManager.shared.append(prepend: keys.TO_TIME_KEY, value: timeReqManager)
        logHistoryRequest(req: toTimeReq)
        ChatManager.activeInstance?.message.history(toTimeReq)
        viewModel?.delegate?.startTopAnimation(true)
    }

    private func onMoveToTime(_ messages: [Message], _ response: HistoryResponse, request: OnMoveTime) async {

        await onMoreTop(messages, response)

        let uniqueId = messages.first(where: {$0.id == request.messageId})?.uniqueId ?? ""
        await viewModel?.scrollVM.showHighlightedAsync(uniqueId, request.messageId, highlight: request.highlight)

        /// 5- Update all the views to draw for the top part.
        /// 7- Fetch the From to time (bottom part) to have a little bit of messages from the bottom.
        let fromTimeReq = GetHistoryRequest(threadId: threadId, count: count, fromTime: request.request.toTime, offset: 0, order: "asc", readOnly: viewModel?.readOnly == true)
        let fromReqManager = OnMoveTime(messageId: request.messageId, request: fromTimeReq, highlight: request.highlight)
        RequestsManager.shared.append(prepend: keys.FROM_TIME_KEY, value: fromReqManager)
        logHistoryRequest(req: fromTimeReq)
        ChatManager.activeInstance?.message.history(fromTimeReq)
        viewModel?.delegate?.startBottomAnimation(true)
        viewModel?.delegate?.startCenterAnimation(false)
        await fetchReactions(messages: messages)
    }

    private func onMoveFromTime(_ messages: [Message], request: OnMoveTime, _ response: HistoryResponse) async {
        isInInsertionBottom = true
        let beforeSectionCount = sections.count
        /// 8- Append and sort the array but not call to update the view.
        let sortedMessages = messages.sortedByTime()
        let viewModels = await createCalculateAppendSort(sortedMessages)
        let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, viewModels)
        delegate?.inserted(tuple.sections, tuple.rows, nil)
        for vm in viewModels {
            await vm.register()
        }
        await setHasMoreBottom(response)
        isInInsertionBottom = false
        viewModel?.delegate?.startCenterAnimation(false)
        await fetchReactions(messages: messages)
    }

    /// Search for a message with an id in the messages array, and if it can find the message, it will redirect to that message locally, and there is no request sent to the server.
    /// - Returns: Indicate that it moved loclally or not.
    private func moveToMessageLocally(_ messageId: Int, highlight: Bool, animate: Bool = false) async -> Bool {
        if let uniqueId = sections.message(for: messageId)?.message.uniqueId {
            await viewModel?.scrollVM.showHighlightedAsync(uniqueId, messageId, highlight: highlight, position: .top, animate: animate)
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
        RequestsManager.shared.append(prepend: keys.FETCH_BY_OFFSET_KEY, value: req)
        logHistoryRequest(req: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func onFetchByOffset(_ messages: [Message]) async {
        isInInsertionTop = true
        let sortedMessages = messages.sortedByTime()
        let viewModels = await createCalculateAppendSort(sortedMessages)
        isFetchedServerFirstResponse = true
        delegate?.reload()
        await viewModel?.scrollVM.showHighlightedAsync(sortedMessages.last?.uniqueId ?? "", sortedMessages.last?.id ?? -1, highlight: false)
        isInInsertionTop = false
        for vm in viewModels {
            await vm.register()
        }
        viewModel?.delegate?.startCenterAnimation(false)
        await fetchReactions(messages: messages)
    }

    // MARK: Scenario 8
    /// When a new thread has been built and me is added by another person and this is our first time to visit the thread.
    private func tryEightScenario() async {
        if thread.lastSeenMessageId == 0, thread.lastSeenMessageTime == nil, let lastMSGId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            await moveToTime(time, lastMSGId, highlight: false)
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
    private func moveToMessageTimeOnOpenConversation() async {
        let model = AppState.shared.appStateNavigationModel
        if let id = model.moveToMessageId, let time = model.moveToMessageTime {
            await moveToTime(time, id, highlight: true)
            AppState.shared.appStateNavigationModel = .init()
        }
    }

    // MARK: On Cache History Response
    private func onHistoryCacheRsponse(_ response: HistoryResponse) async {
        let messages = response.result ?? []
        let sortedMessages = messages.sortedByTime()

        var viewModels: [MessageRowViewModel] = []
        if let viewModel = viewModel {
            for message in sortedMessages {
                let vm = MessageRowViewModel(message: message, viewModel: viewModel)
                await vm.performaCalculation(appendMessages: sortedMessages)
                viewModels.append(vm)
            }
        }
        while(await viewModel?.scrollVM.isEndedDecelerating == false) {
            print("Waiting for the deceleration to be completed.")
        }
        print("Deceleration has been completed.")
        appendSort(viewModels)
        viewModel?.scrollVM.disableExcessiveLoading()
        isFetchedServerFirstResponse = false
        if response.containsPartial(prependedKey: keys.MORE_TOP_KEY) {
            hasNextTop = messages.count >= count // We just need the top part when the user open the thread while it's not connected.
        }
        topLoading = false
        bottomLoading = false
        delegate?.reload()
        if !isJumpedToLastMessage {
            await viewModel?.scrollVM.showHighlightedAsync(sortedMessages.last?.uniqueId ?? "", sortedMessages.last?.id ?? -1, highlight: false)
            isJumpedToLastMessage = true
        }
        isInInsertionTop = false
        for vm in viewModels {
            await vm.register()
        }
        viewModel?.delegate?.startCenterAnimation(false)
    }

    private func moreTop(prepend: String, _ toTime: UInt?) async {
        if !canLoadMoreTop() { return }
        topLoading = true
        viewModel?.delegate?.startTopAnimation(true)
        oldFirstMessageInFirstSection = sections.first?.vms.first?.message
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: viewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: prepend, value: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func onMoreTop(_ messages: [Message], _ response: HistoryResponse) async {
        let lastTopMessageVM = sections.first?.vms.first
        let beforeSectionCount = sections.count
        isInInsertionTop = true
        /// 3- Append and sort the array but not call to update the view.

        var viewModels: [MessageRowViewModel] = []
        if let viewModel = viewModel {
            let sorted = messages.sortedByTime()
            for message in sorted {
                let vm = MessageRowViewModel(message: message, viewModel: viewModel)
                await vm.performaCalculation(appendMessages: sorted)
                viewModels.append(vm)
            }
        }

        while(await viewModel?.scrollVM.isEndedDecelerating == false) {
            print("Waiting for the deceleration to be completed.")
        }
        print("Deceleration has been completed.")
        appendSort(viewModels)
        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        await setHasMoreTop(response)
        let tuple = sections.insertedIndices(insertTop: true, beforeSectionCount: beforeSectionCount, viewModels)

        let moveToMessage = await viewModel?.scrollVM.lastContentOffsetY ?? 0 < 48
        var indexPathToScroll: IndexPath?
        if moveToMessage, let lastTopMessageVM = lastTopMessageVM {
            indexPathToScroll = sections.indexPath(for: lastTopMessageVM)
        }
        delegate?.inserted(tuple.sections, tuple.rows, indexPathToScroll)

        // Register for downloading thumbnails or read a cached version
        for vm in viewModels {
            await vm.register()
        }
        topLoading = false
        isInInsertionTop = false
        await fetchReactions(messages: viewModels.compactMap({$0.message}))
        prepareAvatars(viewModels)
    }

    private func moreBottom(prepend: String, _ fromTime: UInt?) async {
        if !canLoadMoreBottom() { return }
        bottomLoading = true
        viewModel?.delegate?.startBottomAnimation(true)
        let req = GetHistoryRequest(threadId: threadId, count: count, fromTime: fromTime, offset: 0, order: "asc", readOnly: viewModel?.readOnly == true)
        RequestsManager.shared.append(prepend: prepend, value: req)
        logHistoryRequest(req: req)
        ChatManager.activeInstance?.message.history(req)
    }

    private func onMoreBottom(_ messages: [Message], _ response: HistoryResponse) async {
        let beforeSectionCount = sections.count
        isInInsertionBottom = true

        /// 3- Append and sort the array but not call to update the view.

        var viewModels: [MessageRowViewModel] = []
        if let viewModel = viewModel {
            let sorted = messages.sortedByTime()
            for message in sorted {
                let vm = MessageRowViewModel(message: message, viewModel: viewModel)
                await vm.performaCalculation(appendMessages: sorted)
                viewModels.append(vm)
            }
        }
        while(await viewModel?.scrollVM.isEndedDecelerating == false) {
            print("Waiting for the deceleration to be completed.")
        }
        print("Deceleration has been completed.")
        appendSort(viewModels)
        /// 4- Disable excessive loading on the top part.
        viewModel?.scrollVM.disableExcessiveLoading()
        await setHasMoreBottom(response)
        let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, viewModels)
        delegate?.inserted(tuple.sections, tuple.rows, nil)

        for vm in viewModels {
            await vm.register()
        }

        isFetchedServerFirstResponse = true
        isInInsertionBottom = false
        bottomLoading = false

        await fetchReactions(messages: viewModels.compactMap({$0.message}))
        prepareAvatars(viewModels)
    }

    public func loadMoreTop(message: MessageType) async {
        if let time = message.time {
            await moreTop(prepend: keys.MORE_TOP_KEY, time)
        }
    }

    public func loadMoreBottom(message: MessageType) async {
        if let time = message.time {
            // We add 1 milliseceond to prevent duplication and fetch the message itself.
            await moreBottom(prepend: keys.MORE_BOTTOM_KEY, time.advanced(by: 1))
        }
    }
}

// MARK: Event Handlers
extension ThreadHistoryViewModel {
    private func onUploadEvents(_ notification: Notification) {
        guard let event = notification.object as? UploadEventTypes else { return }
        switch event {
        case .canceled(let uniqueId):
            onUploadCanceled(uniqueId)
        default:
            break
        }
    }

    private func onUploadCanceled(_ uniqueId: String?) {
        if let uniqueId = uniqueId {
            removeByUniqueId(uniqueId)
            //            animateObjectWillChange()
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes?) async {
        switch event {
        case .history(let response):
            if !response.cache, response.subjectId == threadId {
                log("Start on history:\(Date().millisecondsSince1970)")
                /// For the first scenario.
                if response.pop(prepend: keys.MORE_TOP_FIRST_SCENARIO_KEY) != nil, let messages = response.result {
                    await onMoreTopFirstScenario(messages, response)
                }
                if response.pop(prepend: keys.MORE_BOTTOM_FIRST_SCENARIO_KEY) != nil, let messages = response.result {
                    await onMoreBottomFirstScenario(messages, response)
                }

                /// For the second scenario.
                if response.pop(prepend: keys.MORE_TOP_SECOND_SCENARIO_KEY) != nil, let messages = response.result {
                    await onMoreTopSecondScenario(messages, response)
                }

                /// For the scenario three and four.
                if response.pop(prepend: keys.MORE_TOP_KEY) != nil, let messages = response.result {
                    await onMoreTop(messages, response)
                }

                /// For the scenario three and four.
                if response.pop(prepend: keys.MORE_BOTTOM_KEY) != nil, let messages = response.result {
                    await onMoreBottom(messages, response)
                }

                /// For the fifth scenario.
                if response.pop(prepend: keys.MORE_BOTTOM_FIFTH_SCENARIO_KEY) != nil, let messages = response.result {
                    await onMoreBottomFifthScenario(messages, response)
                }

                /// For the seventh scenario.
                if response.pop(prepend: keys.FETCH_BY_OFFSET_KEY) != nil, let messages = response.result {
                    await onFetchByOffset(messages)
                }

                /// For the sixth scenario.
                if let request = response.pop(prepend: keys.TO_TIME_KEY) as? OnMoveTime, let messages = response.result {
                    await onMoveToTime(messages, response, request: request)
                }

                if let request = response.pop(prepend: keys.FROM_TIME_KEY) as? OnMoveTime, let messages = response.result {
                    await onMoveFromTime(messages, request: request, response)
                }

                await setIsEmptyThread()

                log("End on history:\(Date().millisecondsSince1970)")
            } else if response.cache && AppState.shared.connectionStatus != .connected {
                await onHistoryCacheRsponse(response)
            }
            break
        case .new(let response):
            await onNewMessage(response)
        case .delivered(let response):
            await onDeliver(response)
        case .seen(let response):
            await onSeen(response)
        case .sent(let response):
            await onSent(response)
        case .deleted(let response):
            await onDeleteMessage(response)
        case .pin(let response):
            await onPinMessage(response)
        case .unpin(let response):
            await onUNPinMessage(response)
        case .edited(let response):
            await onEdited(response)
        default:
            break
        }
    }

    private func onNewMessage(_ response: ChatResponse<Message>) async {
        if threadId == response.subjectId, let message = response.result, let viewModel = viewModel {
            isInInsertionTop = true
            let isMe = (response.result?.participant?.id ?? -1) == AppState.shared.user?.id
            // MARK: Update thread properites
            /*
             We have to set it, because in server chat response when we send a message Message.Conversation.lastSeenMessageId / Message.Conversation.lastSeenMessageTime / Message.Conversation.lastSeenMessageNanos are wrong.
             Although in message object Message.id / Message.time / Message.timeNanos are right.
             We only do this for ourselves, because the only person who can change these values is ourselves.
             We do this in ThreadsViewModel too, because there is a chance of reconnect so objects are distinict
             or if we are in forward mode the objects are different than what exist in ThreadsViewModel.
             */
            var updatedThread = thread
            if isMe {
                updatedThread.lastSeenMessageId = message.id
                updatedThread.lastSeenMessageTime = message.time
                updatedThread.lastSeenMessageNanos = message.timeNanos
            }
            updatedThread.time = message.time
            updatedThread.lastMessageVO = message.toLastMessageVO
            updatedThread.lastMessage = response.result?.message
            if response.result?.mentioned == true {
                updatedThread.mentioned = true
            }
            // MARK: End Update thread properites

            await MainActor.run { [updatedThread] in
                self.viewModel?.thread = updatedThread
            }
            print("before: section count \(sections.count) rowsCount:\(sections.last?.vms.count ?? 0)")

            let beforeSectionCount = sections.count
            let vm: MessageRowViewModel
            if let indexPath = sections.indicesByMessageUniqueId(message.uniqueId ?? "") {
                 // Update a message sent by Me
                vm = sections[indexPath.section].vms[indexPath.row]
                vm.swapUploadMessageWith(message)
                await vm.performaCalculation(appendMessages: [])
            } else {
                // A new message comes from server
                vm = MessageRowViewModel(message: message, viewModel: viewModel)
                await vm.performaCalculation(appendMessages: [message])
                appendSort([vm])
                let tuple = sections.insertedIndices(insertTop: false, beforeSectionCount: beforeSectionCount, [vm])
                delegate?.inserted(tuple.sections, tuple.rows, nil)
            }
            print("after: section count \(sections.count) rowsCount:\(sections.last?.vms.count ?? 0)")

            setSeenForAllOlderMessages(newMessage: message)
            isInInsertionTop = false
            await viewModel.scrollVM.scrollToLastMessageIfLastMessageIsVisible(message)
            await setIsEmptyThread()
        }
    }

    private func onEdited(_ response: ChatResponse<Message>) async {
        if let message = response.result, let vm = sections.messageViewModel(for: message.id ?? -1) {
            vm.message.message = message.message
            vm.message.time = message.time
            vm.message.edited = true
            await vm.performaCalculation()
            guard let indexPath = sections.indexPath(for: vm) else { return }
            await MainActor.run {
                delegate?.edited(indexPath)
            }
        }
    }

    private func onPinMessage(_ response: ChatResponse<PinMessage>) async {
        if let messageId = response.result?.messageId, let vm = sections.messageViewModel(for: messageId) {
            vm.pinMessage(time: response.result?.time)
            guard let indexPath = sections.indexPath(for: vm) else { return }
            await MainActor.run {
                delegate?.pinChanged(indexPath)
            }
        }
    }

    private func onUNPinMessage(_ response: ChatResponse<PinMessage>) async {
        if let messageId = response.result?.messageId, let vm = sections.messageViewModel(for: messageId) {
            vm.unpinMessage()
            guard let indexPath = sections.indexPath(for: vm) else { return }
            await MainActor.run {
                delegate?.pinChanged(indexPath)
            }
        }
    }

    private func onDeliver(_ response: ChatResponse<MessageResponse>) async {
        guard let vm = sections.viewModel(thread, response),
              let indexPath = sections.indexPath(for: vm)
        else { return }
        vm.message.delivered = true
        await vm.performaCalculation()
        await vm.performaCalculation()
        await MainActor.run {
            delegate?.delivered(indexPath)
        }
    }

    private func onSeen(_ response: ChatResponse<MessageResponse>) async {
        guard let vm = sections.viewModel(thread, response),
              let indexPath = sections.indexPath(for: vm)
        else { return }
        vm.message.delivered = true
        vm.message.seen = true
        await vm.performaCalculation()
        await MainActor.run {
            delegate?.seen(indexPath)
        }
        setSeenForOlderMessages(messageId: response.result?.messageId)
    }

    /*
     We have to set id because sent will be called first then onNewMessage will be called,
     and in queries id is essential to update properly the new message
     */
    private func onSent(_ response: ChatResponse<MessageResponse>) async {
        guard let vm = sections.viewModel(thread, response),
              let indexPath = sections.indexPath(for: vm)
        else { return }
        let result = response.result
        vm.message.id = result?.messageId
        vm.message.time = result?.messageTime
        await vm.performaCalculation()
        await MainActor.run {
            delegate?.sent(indexPath)
        }
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    internal func onDeleteMessage(_ response: ChatResponse<Message>) async {
        guard let responseThreadId = response.subjectId ?? response.result?.threadId ?? response.result?.conversation?.id,
              threadId == responseThreadId,
              let indices = sections.findIncicesBy(uniqueId: response.uniqueId, response.result?.id)
        else { return }
        sections[indices.section].vms.remove(at: indices.row)
        if sections[indices.section].vms.count == 0 {
            sections.remove(at: indices.section)
        }
        delegate?.removed(at: indices)
        await setIsEmptyThread()
    }
}

// MARK: Append/Sort/Delete
extension ThreadHistoryViewModel {
    
    private func createCalculateAppendSort(_ messages: [MessageType]) async -> [MessageRowViewModel] {
        guard let viewModel = viewModel else { return [] }
        var viewModels: [MessageRowViewModel] = []
        for message in messages {
            let vm = MessageRowViewModel(message: message, viewModel: viewModel)
            viewModels.append(vm)
            await vm.performaCalculation()
        }
        appendSort(viewModels)
        return viewModels
    }

    private func appendSort(_ viewModels: [MessageRowViewModel]) {
        log("Start of the appendMessagesAndSort: \(Date().millisecondsSince1970)")
        guard viewModels.count > 0 else { return }
        for vm in viewModels {
            insertIntoProperSection(vm)
        }
        sort()
        log("End of the appendMes sagesAndSort: \(Date().millisecondsSince1970)")
        lastItemIdInSections = sections.last?.vms.last?.id ?? 0
        return
    }

    fileprivate func updateMessage(_ message: MessageType, _ indexPath: IndexPath?) -> MessageRowViewModel? {
        guard let indexPath = indexPath else { return nil }
        let vm = sections[indexPath.section].vms[indexPath.row]
        let isUploading = vm.message is UploadProtocol || vm.fileState.isUploading
        if isUploading {
            /// We have to update animateObjectWillChange because after onNewMessage we will not call it, so upload file not work properly.
            vm.swapUploadMessageWith(message)
        } else {
            vm.message.updateMessage(message: message)
        }
        return vm
    }

    public func injectMessagesAndSort(_ requests: [any HistoryMessageProtocol]) async {
        let viewModels = await createCalculateAppendSort(requests)
        for vm in viewModels {
            await vm.register()
        }
    }

    private func insertIntoSection(_ message: MessageType) -> MessageRowViewModel? {
        if message.threadId == threadId || message.conversation?.id == threadId, let viewModel = viewModel {
            let viewModel = MessageRowViewModel(message: message, viewModel: viewModel)
            if let sectionIndex = sections.sectionIndexByDate(message.time?.date ?? Date()) {
                sections[sectionIndex].vms.append(viewModel)
                return viewModel
            } else {
                sections.append(.init(date: message.time?.date ?? Date(), vms: [viewModel]))
                return viewModel
            }
        }
        return nil
    }

    private func insertOrUpdate(_ message: MessageType) -> MessageRowViewModel? {
        guard let uniqueId = message.uniqueId else { return nil }
        let indices = sections.findIncicesBy(uniqueId: uniqueId, message.id ?? -1)
        if let vm = updateMessage(message, indices) {
            return vm
        }
        return insertIntoSection(message)
    }

    private func insertIntoProperSection(_ viewModel: MessageRowViewModel) {
        let message = viewModel.message
        if let sectionIndex = sections.sectionIndexByDate(message.time?.date ?? Date()) {
            sections[sectionIndex].vms.append(viewModel)
        } else {
            sections.append(.init(date: message.time?.date ?? Date(), vms: [viewModel]))
        }
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

    internal func removeByUniqueId(_ uniqueId: String?) {
        guard let uniqueId = uniqueId, let indices = sections.indicesByMessageUniqueId(uniqueId) else { return }
        sections[indices.section].vms.remove(at: indices.row)
    }

    public func deleteMessages(_ messages: [MessageType], forAll: Bool = false) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: forAll))
        viewModel?.selectedMessagesViewModel.clearSelection()
    }
    
    @discardableResult
    private func appenedUnreadMessagesBannerIfNeeed() async -> IndexPath? {
        guard
            let tuples = sections.message(for: thread.lastSeenMessageId),
            let viewModel = viewModel
        else { return nil }
        let time = (tuples.message.time ?? 0) + 1
        let unreadMessage = UnreadMessage(id: LocalId.unreadMessageBanner.rawValue, time: time, uniqueId: "\(LocalId.unreadMessageBanner.rawValue)")
        let indexPath = tuples.indexPath
        let vm = MessageRowViewModel(message: unreadMessage, viewModel: viewModel)
        await vm.performaCalculation()
        sections[indexPath.section].vms.append(vm)
        return .init(row: sections[indexPath.section].vms.indices.last!, section: indexPath.section)
    }
}

// MARK: Appear/Disappear/Display/End Display
extension ThreadHistoryViewModel {
    public func willDisplay(_ indexPath: IndexPath) async {
        guard let message = sections.viewModelWith(indexPath)?.message else { return }
        visibleTracker.append(message: message)
        log("Message appear id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") text: \(message.message ?? "")")
        guard let threadVM = viewModel else { return }
        let lastThreadMessageId = thread.lastMessageVO?.id
        if message.id == lastThreadMessageId {
            threadVM.scrollVM.isAtBottomOfTheList = true
            viewModel?.delegate?.lastMessageAppeared(true)
        }
        await seenVM?.onAppear(message)
    }

    public func didEndDisplay(_ indexPath: IndexPath) async {
        guard let message = sections.viewModelWith(indexPath)?.message else { return }
        log("Message disappeared id: \(message.id ?? 0) uniqueId: \(message.uniqueId ?? "") text: \(message.message ?? "")")
        visibleTracker.remove(message: message)
        if message.id == thread.lastMessageVO?.id {
            await MainActor.run { [viewModel] in
                viewModel?.scrollVM.isAtBottomOfTheList = false
                viewModel?.delegate?.lastMessageAppeared(false)
            }
        }
    }

    public func didScrollTo(_ contentOffset: CGPoint, _ contentSize: CGSize) {
        Task { @HistoryActor in
            guard let scrollVM = viewModel?.scrollVM else { return }
            if contentOffset.y > scrollVM.lastContentOffsetY {
                // scroll down
                scrollVM.scrollingUP = false
                if contentOffset.y > contentSize.height - threshold, let message = sections.last?.vms.last?.message {
                    await loadMoreBottom(message: message)
                }
            } else {
                // scroll up
                print("scrollViewDidScroll \(contentOffset.y)")
                scrollVM.scrollingUP = true
                if contentOffset.y < threshold, let message = sections.first?.vms.first?.message {
                    await loadMoreTop(message: message)
                }
            }
            scrollVM.lastContentOffsetY = contentOffset.y
        }
    }
}

// MARK: Observers
extension ThreadHistoryViewModel {
    private func setupNotificationObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                Task { [weak self] in
                    await self?.onConnectionStatusChanged(status)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { @HistoryActor [weak self] in
                    await self?.onMessageEvent(event)
                }
            }
            .store(in: &cancelable)
        NotificationCenter.onRequestTimer.publisher(for: .onRequestTimer)
            .sink { [weak self] newValue in
                if let key = newValue.object as? String {
                    Task { @HistoryActor [weak self] in
                        self?.onCancelTimer(key: key)
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
        NotificationCenter.upload.publisher(for: .upload)
            .sink { [weak self] notification in
                self?.onUploadEvents(notification)
            }
            .store(in: &cancelable)
    }

    internal func cancel() {
        cancelAllObservers()
    }

    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}

// MARK: Logging
extension ThreadHistoryViewModel {
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
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}

// MARK: Reactions
extension ThreadHistoryViewModel {
    @HistoryActor
    private func fetchReactions(messages: [MessageType]) async {
        if viewModel?.searchedMessagesViewModel.isInSearchMode == false {
            viewModel?.reactionViewModel.fetchReactions(messages: messages.compactMap({$0 as? Message}))
        }
    }
}

// MARK: Scenarios utilities
extension ThreadHistoryViewModel {
    private func setHasMoreTop(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextTop = response.hasNext
            isFetchedServerFirstResponse = true
            viewModel?.delegate?.startTopAnimation(false)
        }
    }

    private func setHasMoreBottom(_ response: ChatResponse<[Message]>) async {
        if !response.cache {
            hasNextBottom = response.hasNext
            isFetchedServerFirstResponse = true
            viewModel?.delegate?.startBottomAnimation(false)
        }
    }

    private func removeOldBanner() {
        if let indices = sections.indicesByMessageUniqueId("\(LocalId.unreadMessageBanner.rawValue)") {
            sections[indices.section].vms.remove(at: indices.row)
        }
    }

    private func canLoadMoreTop() -> Bool {
        return hasNextTop && !topLoading && viewModel?.scrollVM.isProgramaticallyScroll == false
    }

    private func canLoadMoreBottom() -> Bool {
        return hasNextBottom && !bottomLoading && viewModel?.scrollVM.isProgramaticallyScroll == false
    }

    public func setIsEmptyThread() async {
        let noMessage = isFetchedServerFirstResponse == true && sections.count == 0
        let emptyThread = viewModel?.isSimulatedThared == true
        isEmptyThread = emptyThread || noMessage
        delegate?.emptyStateChanged(isEmpty: isEmptyThread)
        if isEmptyThread {
            viewModel?.delegate?.startCenterAnimation(false)
        }
    }

    internal func setCreated(_ created: Bool) {
        self.created = created
    }

    public func setThreashold(_ threshold: CGFloat) {
        Task { @HistoryActor in
            self.threshold = threshold
        }
    }
}

// MARK: Seen messages
extension ThreadHistoryViewModel {
    /// When you have sent messages for example 5 messages and your partner didn't read messages and send a message directly it will send you only one seen.
    /// So you have to set seen to true for older unread messages you have sent, because the partner has read all messages and after you back to the list of thread the server will respond with seen == true for those messages.
    private func setSeenForAllOlderMessages(newMessage: MessageType) {
        let unseenMessages = sections.last?.vms.filter({($0.message.seen == false || $0.message.seen == nil) && $0.message.isMe(currentUserId: AppState.shared.user?.id)})
        let isNotMe = !newMessage.isMe(currentUserId: AppState.shared.user?.id)
        if isNotMe, unseenMessages?.count ?? 0 > 0 {
            unseenMessages?.forEach { vm in
                Task {
                    if let indexPath = sections.indexPath(for: vm) {
                        vm.message.delivered = true
                        vm.message.seen = true
                        await vm.performaCalculation()
                        await MainActor.run {
                            delegate?.seen(indexPath)
                        }
                    }
                }
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
                    Task {
                        if let indexPath = sections.indexPath(for: vm) {
                            vm.message.delivered = true
                            vm.message.seen = true
                            await vm.performaCalculation()
                            await MainActor.run {
                                delegate?.seen(indexPath)
                            }
                        }
                    }
                }
        }
    }
}

// MARK: On Notifications actions
extension ThreadHistoryViewModel {
    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) async {
        if !isSimulated, status == .connected, isFetchedServerFirstResponse == true, viewModel?.isActiveThread == true {
            // After connecting again get latest messages.
            tryFifthScenario(status: status)
        }

        /// Fetch the history for the first time if the internet connection is not available.
        if !isSimulated, status == .connected, hasSentHistoryRequest == true, sections.isEmpty {
            await startFetchingHistory()
        }
    }

    private func setHighlight(messageId: Int) {
        guard let vm = sections.messageViewModel(for: messageId), let indexPath = sections.indexPath(for: vm) else { return }
        Task { @HistoryActor in
            vm.calMessage.state.isHighlited = true
            await MainActor.run {
                delegate?.setHighlightRowAt(indexPath, highlight: true)
            }
        }
        highlightTask?.cancel()
        highlightTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            if !Task.isCancelled {
                await unHighlightTimer(vm: vm, indexPath: indexPath)
            }
        }
    }

    private func unHighlightTimer(vm: MessageRowViewModel, indexPath: IndexPath) async {
        vm.calMessage.state.isHighlited = false
        await MainActor.run { [weak self] in
            self?.delegate?.setHighlightRowAt(indexPath, highlight: false)
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
}

// MARK: Avatars
extension ThreadHistoryViewModel {
    func prepareAvatars(_ viewModels: [MessageRowViewModel]) {
        Task { [weak self] in
            guard let self = self else { return }
            // A delay to scroll to position and layout all rows properply
            try? await Task.sleep(for: .seconds(0.2))
            let filtered = viewModels.filter({$0.calMessage.isLastMessageOfTheUser})
            for vm in filtered {
                viewModel?.avatarManager.addToQueue(vm)
            }
        }
    }
}

// MARK: Cleanup
extension ThreadHistoryViewModel {
    private func onCancelTimer(key: String) {
        if topLoading || bottomLoading {
            topLoading = false
            bottomLoading = false
            viewModel?.delegate?.startTopAnimation(false)
            viewModel?.delegate?.startBottomAnimation(false)
        }
    }
}


public extension ThreadHistoryViewModel {
    @MainActor
    func getSections() async -> ContiguousArray<MessageSection> {
        return sections
    }
}
