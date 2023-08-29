//
//  ThreadViewswift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation
import Photos

protocol ThreadViewModelProtocol: AnyObject {
    var thread: Conversation? { get set }
    var messages: [Message] { get set }
    var threadId: Int { get }
}

protocol ThreadViewModelProtocols: ThreadViewModelProtocol {
    var isInEditMode: Bool { get set }
    var readOnly: Bool { get }
    var canLoadNexPage: Bool { get }
    var threadsViewModel: ThreadsViewModel? { get set }
    var hasNext: Bool { get set }
    var count: Int { get }
    var searchTextTimer: Timer? { get set }
    var mentionList: [Participant] { get set }
    func deleteMessages(_ messages: [Message])
    func loadMoreMessage()
    func getHistory(_ toTime: UInt?)
    func sendSignal(_ signalMessage: SignalMessageType)
    func onLastMessageChanged(_ thread: Conversation)
    func threadName(_ threadId: Int) -> String?
    func searchInsideThread(text: String, offset: Int)
    func isSameUser(message: Message) -> Bool
    func appendMessages(_ messages: [Message])
    func onDeleteMessage(_ response: ChatResponse<Message>)
    func updateThread(_ thread: Conversation)
    func sendSeenMessageIfNeeded(_ message: Message)
    func onMessageEvent(_ event: MessageEventTypes?)
    func updateUnreadCount(_ threadId: Int, _ unreadCount: Int)
}

class ThreadViewModel: ObservableObject, ThreadViewModelProtocols, Identifiable, Hashable {
    static func == (lhs: ThreadViewModel, rhs: ThreadViewModel) -> Bool {
        rhs.threadId == lhs.threadId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    @Published var thread: Conversation?
    @Published var isLoading = false
    @Published var messages: [Message] = []
    @Published var selectedMessages: [Message] = []
    @Published var editMessage: Message?
    @Published var replyMessage: Message?
    @Published var scrollToUniqueId: String?
    @Published var isInEditMode: Bool = false
    @Published var exportMessagesVM: ExportMessagesViewModelProtocol = ExportMessagesViewModel()
    @Published var mentionList: [Participant] = []
    var searchedMessages: [Message] = []
    var readOnly = false
    var textMessage: String?
    var canScrollToBottomOfTheList: Bool = false
    private(set) var cancellableSet: Set<AnyCancellable> = []
    private var typingTimerStarted = false
    lazy var audioRecoderVM: AudioRecordingViewModel = .init(threadViewModel: self)
    var hasNext = true
    var count: Int { 15 }
    var threadId: Int { thread?.id ?? 0 }
    weak var threadsViewModel: ThreadsViewModel?
    @Published var signalMessageText: String?
    var canLoadNexPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .connected }
    var searchTextTimer: Timer?

    weak var forwardMessage: Message? {
        didSet {
            isInEditMode = true
        }
    }

    init() {}

    func setup(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.readOnly = readOnly
        self.thread = thread
        self.threadsViewModel = threadsViewModel
        setupNotificationObservers()
        exportMessagesVM.setup(thread)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .threadEventNotificationName)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: .messageNotificationName)
            .compactMap { $0.object as? MessageEventTypes }
            .sink(receiveValue: onMessageEvent)
            .store(in: &cancellableSet)
    }

    func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case let .lastMessageDeleted(response), let .lastMessageEdited(response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }
        case let .threadUnreadCountUpdated(response):
            if let unreadCountModel = response.result {
                updateUnreadCount(unreadCountModel.threadId ?? -1, unreadCountModel.unreadCount ?? -1)
            }
        default:
            break
        }
    }

    func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case let .messageNew(response):
            if threadId == response.subjectId, let message = response.result {
                appendMessages([message])
                scrollToLastMessageIfLastMessageIsVisible()
            }
        case let .messageSent(response):
            if threadId == response.result?.threadId {
                onSent(response)
            }
        case let .messageDelivery(response):
            if threadId == response.result?.threadId {
                onDeliver(response)
            }
        case let .messageSeen(response):
            if threadId == response.result?.threadId {
                onSeen(response)
            }
        default:
            break
        }
    }

    func updateUnreadCount(_ threadId: Int, _ unreadCount: Int) {
        if threadId == self.threadId {
            thread?.unreadCount = unreadCount
            objectWillChange.send()
        }
    }

    func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread?.lastMessage = thread.lastMessage
            self.thread?.lastMessageVO = thread.lastMessageVO
            self.thread?.unreadCount = thread.unreadCount
            objectWillChange.send()
        }
    }

    func loadMoreMessage() {
        if !canLoadNexPage { return }
        isLoading = true
        getHistory(messages.first?.time)
    }

    func getHistory(_ toTime: UInt? = nil) {
        ChatManager.activeInstance?.getHistory(.init(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)) { [weak self] response in
            if let messages = response.result {
                self?.setHasNext(response.pagination?.hasNext ?? false)
                self?.appendMessages(messages)
                self?.isLoading = false
            }
        } cacheResponse: { [weak self] response in
            if let messages = response.result {
                self?.appendMessages(messages)
            }
        } textMessageNotSentRequests: { [weak self] response in
            self?.appendMessages(response.result?.compactMap { SendTextMessage(from: $0, thread: self?.thread) } ?? [])
        } editMessageNotSentRequests: { [weak self] response in
            self?.appendMessages(response.result?.compactMap { EditTextMessage(from: $0, thread: self?.thread) } ?? [])
        } forwardMessageNotSentRequests: { [weak self] response in
            self?.appendMessages(response.result?.compactMap {
                ForwardMessage(from: $0, destinationThread: .init(id: $0.threadId, title: self?.threadName($0.threadId)), thread: self?.thread)
            } ?? []
            )
        } fileMessageNotSentRequests: { [weak self] response in
            self?.appendMessages(response.result?.compactMap { UnsentUploadFileWithTextMessage(uploadFileRequest: $0.0, sendTextMessageRequest: $0.1, thread: self?.thread) } ?? [])
        }
    }

    func threadName(_ threadId: Int) -> String? {
        threadsViewModel?.threads.first { $0.id == threadId }?.title
    }

    func sendStartTyping(_ newValue: String) {
        if newValue.isEmpty == false {
            ChatManager.activeInstance?.snedStartTyping(threadId: threadId)
        } else {
            ChatManager.activeInstance?.sendStopTyping()
        }
    }

    func sendSeenMessageIfNeeded(_ message: Message) {
        if let messageId = message.id, let lastMsgId = thread?.lastSeenMessageId, messageId > lastMsgId, message.isMe == false {
            thread?.lastSeenMessageId = messageId
            print("send seen for message:\(message.messageTitle) with id:\(messageId)")
            ChatManager.activeInstance?.seen(.init(threadId: threadId, messageId: messageId))
            if let unreadCount = thread?.unreadCount, unreadCount > 0 {
                thread?.unreadCount = unreadCount - 1
                objectWillChange.send()
            }
        } else if thread?.unreadCount ?? 0 > 0 {
            print("messageId \(message.id ?? 0) was bigger than threadLastSeesn\(thread?.lastSeenMessageId ?? 0)")
            thread?.unreadCount = 0
            objectWillChange.send()
        }
    }

    func sendSignal(_ signalMessage: SignalMessageType) {
        ChatManager.activeInstance?.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
    }

    func playAudio() {}

    func setMessageEdited(_ message: Message) {
        messages.first(where: { $0.id == message.id })?.message = message.message
    }

    /// Prevent reconstructing the thread in updates like from a cached version to a server version.
    func updateThread(_ thread: Conversation) {
        self.thread?.updateValues(thread)
        objectWillChange.send()
    }

    func searchInsideThread(text: String, offset: Int = 0) {
        searchTextTimer?.invalidate()
        searchTextTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            if offset == 0 {
                self?.searchedMessages.removeAll()
                self?.objectWillChange.send()
            }
            self?.doSearch(text: text, offset: offset)
        }
    }

    func doSearch(text: String, offset: Int = 0) {
        guard text.count >= 2 else { return }
        let req = GetHistoryRequest(threadId: threadId, count: 50, offset: offset, query: "\(text)")
        ChatManager.activeInstance?.getHistory(req) { [weak self] response in
            response.result?.forEach { message in
                if !(self?.searchedMessages.contains(where: { $0.id == message.id }) ?? false) {
                    self?.searchedMessages.append(message)
                    self?.objectWillChange.send()
                }
            }
        }
    }

    func appendMessages(_ messages: [Message]) {
        messages.forEach { message in
            if let oldUploadFileIndex = self.messages.firstIndex(where: { $0.isUploadMessage && $0.uniqueId == message.uniqueId }) {
                self.messages.remove(at: oldUploadFileIndex)
            }
            if let oldMessage = self.messages.first(where: { $0.uniqueId == message.uniqueId }) {
                oldMessage.updateMessage(message: message)
            } else if message.conversation?.id == threadId {
                self.messages.append(message)
                thread?.unreadCount = message.conversation?.unreadCount ?? 1
                thread?.lastMessageVO = message
                thread?.lastMessage = message.message
            }
        }
        sort()
        updateScrollToLastSeenUniqueId()
    }

    func deleteMessages(_ messages: [Message]) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.deleteMultipleMessages(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: true), completion: onDeleteMessage)
        selectedMessages = []
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    func onDeleteMessage(_ response: ChatResponse<Message>) {
        messages.removeAll(where: { $0.uniqueId == response.uniqueId || response.result?.id == $0.id })
    }

    func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    func clear() {
        messages = []
    }

    func sort() {
        messages = messages.sorted { m1, m2 in
            if let t1 = m1.time, let t2 = m2.time {
                return t1 < t2
            } else {
                return false
            }
        }
    }

    func isSameUser(message: Message) -> Bool {
        if let previousMessage = messages.first(where: { $0.id == message.previousId }) {
            return previousMessage.participant?.id ?? 0 == message.participant?.id ?? -1
        }
        return false
    }

    func searchForMention(_ text: String) {
        if text.matches(char: "@")?.last != nil, text.split(separator: " ").last?.first == "@", text.last != " " {
            let rangeText = text.split(separator: " ").last?.replacingOccurrences(of: "@", with: "")
            ChatManager.activeInstance?.getThreadParticipants(.init(threadId: threadId, name: rangeText)) { response in
                self.mentionList = response.result ?? []
            }
        } else {
            mentionList = []
        }
    }

    func togglePinMessage(_ message: Message) {
        guard let messageId = message.id else { return }
        if message.pinned == false {
            pin(messageId)
        } else {
            unpin(messageId)
        }
    }

    func firstMessageIndex(_ messageId: Int?) -> Array<Message>.Index? {
        messages.firstIndex(where: { $0.id == messageId })
    }

    func pin(_ messageId: Int) {
        ChatManager.activeInstance?.pinMessage(.init(messageId: messageId)) { [weak self] _ in
            if let index = self?.firstMessageIndex(messageId) {
                self?.messages[index].pinned = true
            }
        }
    }

    func unpin(_ messageId: Int) {
        ChatManager.activeInstance?.unpinMessage(.init(messageId: messageId)) { [weak self] _ in
            if let index = self?.firstMessageIndex(messageId) {
                self?.messages[index].pinned = false
            }
        }
    }

    func clearCacheFile(message: Message) {
        NotificationCenter.default.post(.init(name: .fileDeletedFromCacheName, object: message))
    }
}
