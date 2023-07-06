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
import SwiftUI

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
    public var messages: [Message] = []
    @Published public var selectedMessages: [Message] = []
    @Published public var editMessage: Message?
    @Published public var replyMessage: Message?
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
    private var cancelable: Set<AnyCancellable> = []
    private var typingTimerStarted = false
    public lazy var audioRecoderVM: AudioRecordingViewModel = .init(threadViewModel: self)
    public var hasNext = true
    public var count: Int { 15 }
    public var threadId: Int { thread?.id ?? 0 }
    public weak var threadsViewModel: ThreadsViewModel?
    @Published public var signalMessageText: String?
    public var canLoadNexPage: Bool { !isLoading && hasNext }
    public var searchTextTimer: Timer?
    public var isActiveThread: Bool { AppState.shared.activeThreadId == threadId }
    public var audioPlayer: AVAudioPlayerViewModel?
    var requests: [String: Any] = [:]
    public var isAtBottomOfTheList: Bool = false
    public var highliteMessageId: Int?
    @Published public var searchMessageText: String = ""
    var highlightTimer: Timer?
    var searchOffset: Int = 0
    public var scrollProxy: ScrollViewProxy?
    public var scrollingUP = false
    var lastOrigin: CGFloat = 0
    public var lastVisibleUniqueId: String?

    public weak var forwardMessage: Message? {
        didSet {
            isInEditMode = true
        }
    }

    public init() {}

    private func request<T>(_ response: ChatResponse<Any>) -> T? {
        guard let uniqueId = response.uniqueId, let request = requests[uniqueId] as? T else { return nil }
        return request
    }

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
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .chatEvents)
            .compactMap { $0.object as? ChatEventType }
            .sink(receiveValue: onChatEvent)
            .store(in: &cancelable)
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if status == .connected, isFetchedServerFirstResponse == true, isActiveThread {
            // After connecting again get latest messages
            getHistory(thread?.lastSeenMessageTime)
        }
    }

    public func onChatEvent(_ event: ChatEventType) {
        switch event {
        case .message(let messageEventTypes):
            onMessageEvent(messageEventTypes)
        case .thread(let threadEventTypes):
            onThreadEvent(threadEventTypes)
        case .participant(let participantEventTypes):
            onParticipantEvent(participantEventTypes)
        default:
            break
        }
    }

    public func onParticipantEvent(_ event: ParticipantEventTypes?) {
        switch event {
        case .participants(let response):
            onMentionParticipants(response)
        default:
            break
        }
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .lastMessageDeleted(let response), .lastMessageEdited(let response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }
        case .updatedUnreadCount(let response):
            if let unreadCountModel = response.result {
                updateUnreadCount(unreadCountModel.threadId ?? -1, unreadCountModel.unreadCount ?? -1)
            }
        default:
            break
        }
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .history(let response):
            onHistory(response)
            onMoreTopHistory(response)
            onSearch(response)
            onMoveToTime(response)
            onMoveFromTime(response)
            break
        case .queueTextMessages(let response):
            onQueueTextMessages(response)
        case .queueEditMessages(let response):
            onQueueEditMessages(response)
        case .queueForwardMessages(let response):
            onQueueForwardMessages(response)
        case .queueFileMessages(let response):
            onQueueFileMessages(response)
        case .new(let response):
            if threadId == response.subjectId, let message = response.result {
                appendMessages([message])
                scrollToLastMessageIfLastMessageIsVisible()
            }
        case .sent(let response):
            if threadId == response.result?.threadId {
                onSent(response)
                playSentAudio()
            }
        case .delivered(let response):
            if threadId == response.result?.threadId {
                onDeliver(response)
            }
        case .seen(let response):
            if threadId == response.result?.threadId {
                onSeen(response)
            }
        case .deleted(let response):
            let responseThreadId = response.subjectId ?? response.result?.threadId ?? response.result?.conversation?.id
            if threadId == responseThreadId {
                onDeleteMessage(response)
            }
        case .pin(let response):
            onPinMessage(response)
        case .unpin(let response):
            onUNPinMessage(response)
        case .edited(let response):
            onEditedMessage(response)
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
            if let lastMessage = thread.lastMessageVO, let index = messages.firstIndex(where: {$0.id == lastMessage.id}) {
                messages[index] = lastMessage
            }
            objectWillChange.send()
        }
    }

    public func loadMoreMessage() {
        if !canLoadNexPage { return }
        isLoading = true
        getHistory(messages.first?.time)
    }

    public func getHistory(_ toTime: UInt? = nil) {
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)
        requests["GET_HISTORY-\(req.uniqueId)"] = req
        ChatManager.activeInstance?.message.history(req)
    }

    private func onHistory(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId, requests["GET_HISTORY-\(uniqueId)"] != nil, let messages = response.result else { return }
        appendMessages(messages)
        if response.cache == false, isFetchedServerFirstResponse == false, let time = thread?.lastSeenMessageTime, let lastSeenMessageId = thread?.lastSeenMessageId {
            moveToTime(time, lastSeenMessageId, highlight: false)
        }
        if response.cache == false {
            isFetchedServerFirstResponse = true
            hasNext = response.hasNext
            requests.removeValue(forKey: "GET_HISTORY-\(uniqueId)")
        }
        self.objectWillChange.send()
    }

    public func getMoreTopHistory() {
        if !canLoadNexPage { return }
        isLoading = true
        let req = GetHistoryRequest(threadId: threadId, count: count, offset: 0, order: "desc", toTime: messages.first?.time, readOnly: readOnly)
        requests["MORE_TOP_HISTORY-\(req.uniqueId)"] = req
        ChatManager.activeInstance?.message.history(req)
    }

    private func onMoreTopHistory(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId, requests["MORE_TOP_HISTORY-\(uniqueId)"] != nil, let messages = response.result else { return }
        appendMessages(messages)
        if response.cache == false {
            hasNext = response.hasNext
            scrollTo(messages.first?.uniqueId ?? "", animation: nil, anchor: .top)
            withAnimation(nil) {
                isLoading = false
            }
            self.objectWillChange.send()
            requests.removeValue(forKey: "MORE_TOP_HISTORY-\(uniqueId)")
        }
    }

    private func onQueueTextMessages(_ response: ChatResponse<[SendTextMessageRequest]>) {
        appendMessages(response.result?.compactMap { SendTextMessage(from: $0, thread: thread) } ?? [])
    }

    private func onQueueEditMessages(_ response: ChatResponse<[EditMessageRequest]>) {
        appendMessages(response.result?.compactMap { EditTextMessage(from: $0, thread: thread) } ?? [])
    }

    private func onQueueForwardMessages(_ response: ChatResponse<[ForwardMessageRequest]>) {
        appendMessages(response.result?.compactMap { ForwardMessage(from: $0,
                                                                    destinationThread: .init(id: $0.threadId, title: threadName($0.threadId)),
                                                                    thread: thread) } ?? [])
    }

    private func onQueueFileMessages(_ response: ChatResponse<[(UploadFileRequest, SendTextMessageRequest)]>) {
        appendMessages(response.result?.compactMap { UnsentUploadFileWithTextMessage(uploadFileRequest: $0.0, sendTextMessageRequest: $0.1, thread: thread) } ?? [])
    }

    public func onEditedMessage(_ response: ChatResponse<Message>) {
        if let editedMessage = response.result, let oldMessage = messages.first(where: { $0.id == editedMessage.id }) {
            oldMessage.updateMessage(message: editedMessage)
        }
    }

    public func threadName(_ threadId: Int) -> String? {
        threadsViewModel?.threads.first { $0.id == threadId }?.title
    }

    public func sendStartTyping(_ newValue: String) {
        if newValue.isEmpty == false {
            ChatManager.activeInstance?.system.snedStartTyping(threadId: threadId)
        } else {
            ChatManager.activeInstance?.system.sendStopTyping()
        }
    }

    public func sendSeenMessageIfNeeded(_ message: Message) {
        let isMe = message.isMe(currentUserId: AppState.shared.user?.id)
        if let messageId = message.id, let lastMsgId = thread?.lastSeenMessageId, messageId > lastMsgId, !isMe {
            thread?.lastSeenMessageId = messageId
            print("send seen for message:\(message.messageTitle) with id:\(messageId)")
            ChatManager.activeInstance?.message.seen(.init(threadId: threadId, messageId: messageId))
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
        ChatManager.activeInstance?.system.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
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
            self?.doSearch(text: text, offset: offset)
        }
    }

    public func doSearch(text: String, offset: Int = 0) {
        guard text.count >= 2 else { return }
        let req = GetHistoryRequest(threadId: threadId, count: 50, offset: searchOffset, query: "\(text)")
        requests["SEARCH-\(req.uniqueId)"] = req
        ChatManager.activeInstance?.message.history(req)
    }

    private func onSearch(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId, requests["SEARCH-\(uniqueId)"] != nil else { return }
        searchedMessages.removeAll()
        response.result?.forEach { message in
            if !(searchedMessages.contains(where: { $0.id == message.id })) {
                searchedMessages.append(message)
            }
        }
        objectWillChange.send()
        requests.removeValue(forKey: "SEARCH-\(uniqueId)")
    }

    public func appendMessages(_ messages: [Message]) {
        messages.forEach { message in
            if let oldUploadFileIndex = self.messages.firstIndex(where: { $0.isUploadMessage && $0.uniqueId == message.uniqueId }) {
                self.messages.remove(at: oldUploadFileIndex)
            }
            if let oldMessage = self.messages.first(where: { $0.uniqueId == message.uniqueId || $0.id == message.id }) {
                oldMessage.updateMessage(message: message)
            } else if message.threadId == threadId || message.conversation?.id == threadId {
                self.messages.append(message)
            }
        }
        sort()
    }

    public func deleteMessages(_ messages: [Message]) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: true))
        selectedMessages = []
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    public func onDeleteMessage(_ response: ChatResponse<Message>) {
        messages.removeAll(where: { $0.uniqueId == response.uniqueId || response.result?.id == $0.id })
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

    public func searchForParticipantInMentioning(_ text: String) {
        if text.matches(char: "@")?.last != nil, text.split(separator: " ").last?.first == "@", text.last != " " {
            let rangeText = text.split(separator: " ").last?.replacingOccurrences(of: "@", with: "")
            let req = ThreadParticipantsRequest(threadId: threadId, name: rangeText)
            requests[req.uniqueId] = req
            ChatManager.activeInstance?.participant.get(req)
        } else {
            mentionList = []
        }
    }

    private func onMentionParticipants(_ response: ChatResponse<[Participant]>) {
        if let mentionList = response.result, let uniqueId = response.uniqueId, requests[uniqueId] != nil {
            self.mentionList = mentionList
            requests.removeValue(forKey: uniqueId)
        }
    }

    public func togglePinMessage(_ message: Message) {
        guard let messageId = message.id else { return }
        if message.pinned == false || message.pinned == nil {
            pinMessage(messageId)
        } else {
            unpinMessage(messageId)
        }
    }

    public func firstMessageIndex(_ messageId: Int?) -> Array<Message>.Index? {
        messages.firstIndex(where: { $0.id == messageId })
    }

    public func pinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.pin(.init(messageId: messageId))
    }

    private func onPinMessage(_ response: ChatResponse<PinMessage>) {
        if let message = response.result, let messageId = message.id {
            if let index = firstMessageIndex(messageId) {
                messages[index].pinned = true
            }
            thread?.pinMessage = message
            animatableObjectWillChange()
        }
    }

    func animatableObjectWillChange() {
        withAnimation {
            objectWillChange.send()
        }
    }

    public func unpinMessage(_ messageId: Int) {
        ChatManager.activeInstance?.message.unpin(.init(messageId: messageId))
    }

    private func onUNPinMessage(_ response: ChatResponse<PinMessage>) {
        if let messageId = response.result?.id {
            if let index = firstMessageIndex(messageId) {
                messages[index].pinned = false
            }
            thread?.pinMessage = nil
            animatableObjectWillChange()
        }
    }

    public func clearCacheFile(message: Message) {
        if let metadata = message.metadata?.data(using: .utf8), let fileHashCode = try? JSONDecoder().decode(FileMetaData.self, from: metadata).fileHash {
            let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(Routes.files.rawValue)/\(fileHashCode)"
            ChatManager.activeInstance?.file.deleteCacheFile(URL(string: url)!)
            NotificationCenter.default.post(.init(name: .message, object: message))
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
        ChatManager.activeInstance?.message.send(req)
    }
}

