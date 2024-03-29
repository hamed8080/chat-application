//
//  ThreadViewswift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import MapKit
import Photos
import ChatModels
import ChatAppModels
import ChatCore
import ChatDTO
import ChatExtensions


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
    var isFetchedServerFirstResponse: Bool { get set }
    var isActiveThread: Bool { get }
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
    func sendLoaction(_ location: LocationItem)
}

public final class ThreadViewModel: ObservableObject, ThreadViewModelProtocols, Identifiable, Hashable {
    public static func == (lhs: ThreadViewModel, rhs: ThreadViewModel) -> Bool {
        rhs.threadId == lhs.threadId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    @Published public var thread: Conversation?
    @Published public var isLoading = false
    @Published public var messages: [Message] = []
    @Published public var selectedMessages: [Message] = []
    @Published public var editMessage: Message?
    @Published public var replyMessage: Message?
    @Published public var scrollToUniqueId: String?
    @Published public var isInEditMode: Bool = false
    @Published public var exportMessagesVM: ExportMessagesViewModelProtocol = ExportMessagesViewModel()
    @Published public var mentionList: [Participant] = []
    @Published public var dropItems: [DropItem] = []
    @Published public var sheetType: ThreadSheetType?
    @Published public var selectedLocation: MKCoordinateRegion = .init()
    public var isFetchedServerFirstResponse: Bool = false
    public var searchedMessages: [Message] = []
    public var readOnly = false
    public var textMessage: String?
    public var canScrollToBottomOfTheList: Bool = false
    public private(set) var cancellableSet: Set<AnyCancellable> = []
    private var typingTimerStarted = false
    public lazy var audioRecoderVM: AudioRecordingViewModel = .init(threadViewModel: self)
    public var hasNext = true
    public var count: Int { 15 }
    public var threadId: Int { thread?.id ?? 0 }
    public weak var threadsViewModel: ThreadsViewModel?
    @Published public var signalMessageText: String?
    public var canLoadNexPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .connected }
    public var searchTextTimer: Timer?
    public var isActiveThread: Bool { AppState.shared.activeThreadId == threadId }

    public weak var forwardMessage: Message? {
        didSet {
            isInEditMode = true
        }
    }

    public init() {}

    public func setup(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.readOnly = readOnly
        self.thread = thread
        self.threadsViewModel = threadsViewModel
        setupNotificationObservers()
        exportMessagesVM.setup(thread)
    }

    private func setupNotificationObservers() {
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: .threadEventNotificationName)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: .messageNotificationName)
            .compactMap { $0.object as? MessageEventTypes }
            .sink(receiveValue: onMessageEvent)
            .store(in: &cancellableSet)
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if status == .connected, isFetchedServerFirstResponse == true, isActiveThread {
            // After connecting again get latest messages
            getHistory()
        }
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {
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

    public func onMessageEvent(_ event: MessageEventTypes?) {
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

    public func updateUnreadCount(_ threadId: Int, _ unreadCount: Int) {
        if threadId == self.threadId {
            thread?.unreadCount = unreadCount
            objectWillChange.send()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread?.lastMessage = thread.lastMessage
            self.thread?.lastMessageVO = thread.lastMessageVO
            self.thread?.unreadCount = thread.unreadCount
            objectWillChange.send()
        }
    }

    public func loadMoreMessage() {
        if !canLoadNexPage { return }
        isLoading = true
        getHistory(messages.first?.time)
    }

    public func getHistory(_ toTime: UInt? = nil) {
        ChatManager.activeInstance?.getHistory(.init(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)) { [weak self] response in
            if let messages = response.result {
                self?.setHasNext(response.pagination?.hasNext ?? false)
                self?.appendMessages(messages)
                self?.isLoading = false
                self?.isFetchedServerFirstResponse = true
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

    public func threadName(_ threadId: Int) -> String? {
        threadsViewModel?.threads.first { $0.id == threadId }?.title
    }

    public func sendStartTyping(_ newValue: String) {
        if newValue.isEmpty == false {
            ChatManager.activeInstance?.snedStartTyping(threadId: threadId)
        } else {
            ChatManager.activeInstance?.sendStopTyping()
        }
    }

    public func sendSeenMessageIfNeeded(_ message: Message) {
        let isMe = message.isMe(currentUserId: AppState.shared.user?.id)
        if let messageId = message.id, let lastMsgId = thread?.lastSeenMessageId, messageId > lastMsgId, !isMe {
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

    public func sendSignal(_ signalMessage: SignalMessageType) {
        ChatManager.activeInstance?.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
    }

    public func playAudio() {}

    public func setMessageEdited(_ message: Message) {
        messages.first(where: { $0.id == message.id })?.message = message.message
    }

    /// Prevent reconstructing the thread in updates like from a cached version to a server version.
    public func updateThread(_ thread: Conversation) {
        self.thread?.updateValues(thread)
        objectWillChange.send()
    }

    public func searchInsideThread(text: String, offset: Int = 0) {
        searchTextTimer?.invalidate()
        searchTextTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            if offset == 0 {
                self?.searchedMessages.removeAll()
                self?.objectWillChange.send()
            }
            self?.doSearch(text: text, offset: offset)
        }
    }

    public func doSearch(text: String, offset: Int = 0) {
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

    public func appendMessages(_ messages: [Message]) {
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

    public func deleteMessages(_ messages: [Message]) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.deleteMultipleMessages(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: true), completion: onDeleteMessage)
        selectedMessages = []
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    public func onDeleteMessage(_ response: ChatResponse<Message>) {
        messages.removeAll(where: { $0.uniqueId == response.uniqueId || response.result?.id == $0.id })
    }

    public func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    public func clear() {
        messages = []
    }

    public func sort() {
        messages = messages.sorted { m1, m2 in
            if let t1 = m1.time, let t2 = m2.time {
                return t1 < t2
            } else {
                return false
            }
        }
    }

    public func isSameUser(message: Message) -> Bool {
        if let previousMessage = messages.first(where: { $0.id == message.previousId }) {
            return previousMessage.participant?.id ?? 0 == message.participant?.id ?? -1
        }
        return false
    }

    public func searchForMention(_ text: String) {
        if text.matches(char: "@")?.last != nil, text.split(separator: " ").last?.first == "@", text.last != " " {
            let rangeText = text.split(separator: " ").last?.replacingOccurrences(of: "@", with: "")
            ChatManager.activeInstance?.getThreadParticipants(.init(threadId: threadId, name: rangeText)) { response in
                self.mentionList = response.result ?? []
            }
        } else {
            mentionList = []
        }
    }

    public func togglePinMessage(_ message: Message) {
        guard let messageId = message.id else { return }
        if message.pinned == false {
            pin(messageId)
        } else {
            unpin(messageId)
        }
    }

    public func firstMessageIndex(_ messageId: Int?) -> Array<Message>.Index? {
        messages.firstIndex(where: { $0.id == messageId })
    }

    public func pin(_ messageId: Int) {
        ChatManager.activeInstance?.pinMessage(.init(messageId: messageId)) { [weak self] _ in
            if let index = self?.firstMessageIndex(messageId) {
                self?.messages[index].pinned = true
            }
        }
    }

    public func unpin(_ messageId: Int) {
        ChatManager.activeInstance?.unpinMessage(.init(messageId: messageId)) { [weak self] _ in
            if let index = self?.firstMessageIndex(messageId) {
                self?.messages[index].pinned = false
            }
        }
    }

    public func clearCacheFile(message: Message) {
        if let metadata = message.metadata?.data(using: .utf8), let fileHashCode = try? JSONDecoder().decode(FileMetaData.self, from: metadata).fileHash {
            let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(Routes.files.rawValue)/\(fileHashCode)"
            AppState.shared.cacheFileManager?.deleteFile(at: URL(string: url)!)
            NotificationCenter.default.post(.init(name: .fileDeletedFromCacheName, object: message))
        }
    }

    public func storeDropItems(_ items: [NSItemProvider]) {
        items.forEach { item in
            let name = item.suggestedName ?? ""
            let ext = item.registeredContentTypes.first?.preferredFilenameExtension ?? ""
            let iconName = ext.systemImageNameForFileExtension
            _ = item.loadDataRepresentation(for: .item) { data, _ in
                DispatchQueue.main.async {
                    self.dropItems.append(
                        .init(data: data,
                              name: name,
                              iconName: iconName,
                              ext: ext)
                    )
                }
            }
        }
    }

    public func sendLoaction(_ location: LocationItem) {
        let coordinate = Coordinate(lat: location.location.latitude, lng: location.location.longitude)
        let req = LocationMessageRequest(mapCenter: coordinate,
                                         threadId: threadId,
                                         userGroupHash: thread?.userGroupHash ?? "",
                                         textMessage: textMessage)
        ChatManager.activeInstance?.sendLocationMessage(req) { uploadProgress, error in
            print(uploadProgress ?? 0)
            print(error ?? 0)
        } downloadProgress: { downloadProgress in
            print(downloadProgress)
        } onSent: { response in
            print(response)
        } onSeen: { response in
            print(response)
        } onDeliver: { response in
            print(response)
        }
    }
}

