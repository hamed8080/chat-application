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
import SwiftUI

protocol ThreadViewModelProtocol: AnyObject {
    var thread: Conversation { get set }
    var messages: [Message] { get set }
    var threadId: Int { get }
}

protocol ThreadViewModelProtocols: ThreadViewModelProtocol {
    var isInEditMode: Bool { get set }
    var readOnly: Bool { get }
    var canLoadNexPage: Bool { get }
    var threadsViewModel: ThreadsViewModel? { get set }
    var canAddParticipant: Bool { get }
    var hasNext: Bool { get set }
    var count: Int { get }
    var groupCallIdToJoin: Int? { get set }
    func delete()
    func leave()
    func clearHistory()
    func spamPV()
    func deleteMessages(_ messages: [Message])
    func loadMoreMessage()
    func getHistory(_ toTime: UInt?)
    func sendSignal(_ signalMessage: SignalMessageType)
    func onLastMessageChanged(_ thread: Conversation)
    func threadName(_ threadId: Int) -> String?
    func searchInsideThread(text: String, offset: Int)
    func isSameUser(message: Message) -> Bool
    func appendMessages(_ messages: [Message])
    func onDeleteMessage(message: Message?, uniqueId: String?, error: ChatError?)
    func updateThread(_ thread: Conversation)
    func sendSeenMessageIfNeeded(_ message: Message)
    func onMessageEvent(_ event: MessageEventTypes?)
    func updateUnreadCount(_ threadId: Int, _ unreadCount: Int)
    func onCallEvent(_ event: CallEventTypes)
}

class ThreadViewModel: ObservableObject, ThreadViewModelProtocols, Identifiable, Hashable {
    static func == (lhs: ThreadViewModel, rhs: ThreadViewModel) -> Bool {
        rhs.threadId == lhs.threadId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    @Published
    var thread: Conversation

    @Published
    var isLoading = false

    var readOnly = false

    @Published
    var searchedMessages: [Message] = []

    @Published
    var messages: [Message] = []

    var textMessage: String?

    @Published
    var selectedMessages: [Message] = []

    @Published
    var editMessage: Message?

    @Published
    var replyMessage: Message?

    var groupCallIdToJoin: Int? {
        didSet {
            objectWillChange.send()
        }
    }

    weak var forwardMessage: Message? {
        didSet {
            isInEditMode = true
        }
    }

    @Published
    var scrollToUniqueId: String?
    var canScrollToBottomOfTheList: Bool = false

    private(set) var cancellableSet: Set<AnyCancellable> = []

    private var typingTimerStarted = false

    lazy var audioRecoderVM: AudioRecordingViewModel = .init(threadViewModel: self)

    var hasNext = true

    var count: Int { 15 }

    var threadId: Int { thread.id ?? 0 }

    weak var threadsViewModel: ThreadsViewModel?

    var canAddParticipant: Bool { thread.group ?? false && thread.admin ?? false == true }

    var signalMessageText: String?

    @Published
    var isInEditMode: Bool = false

    @Published
    var exportMessagesVM: ExportMessagesViewModelProtocol

    var canLoadNexPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .connected }

    init(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.readOnly = readOnly
        self.thread = thread
        self.exportMessagesVM = ExportMessagesViewModel(thread: thread)
        self.threadsViewModel = threadsViewModel
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: THREAD_EVENT_NOTIFICATION_NAME)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap { $0.object as? MessageEventTypes }
            .sink(receiveValue: onMessageEvent)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: CALL_EVENT_NAME)
            .compactMap { $0.object as? CallEventTypes }
            .sink(receiveValue: onCallEvent)
            .store(in: &cancellableSet)
    }

    func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .lastMessageDeleted(let thread), .lastMessageEdited(let thread):
            onLastMessageChanged(thread)
        case .threadUnreadCountUpdated(let threadId, let unreadCount):
            updateUnreadCount(threadId, unreadCount)
        default:
            break
        }
    }

    func onCallEvent(_ event: CallEventTypes) {
        switch event {
        case .callEnded(let callId):
            if callId == groupCallIdToJoin {
                groupCallIdToJoin = nil
                objectWillChange.send()
            }
        case .groupCallCanceled(let call):
            if call.callId == groupCallIdToJoin {
                groupCallIdToJoin = call.callId
                objectWillChange.send()
            }
        case .callReceived(let call):
            if call.conversation?.id == threadId {
                groupCallIdToJoin = call.callId
                objectWillChange.send()
            }
        default:
            break
        }
    }

    func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .messageNew(let message):
            if threadId == message.conversation?.id {
                appendMessages([message])
                scrollToLastMessageIfLastMessageIsVisible()
            }
        case .messageSent(let sentResponse):
            if threadId == sentResponse.threadId {
                onSent(sentResponse, nil, nil)
            }
        case .messageDelivery(let deliverResponse):
            if threadId == deliverResponse.threadId {
                onDeliver(deliverResponse, nil, nil)
            }
        case .messageSeen(let seenResponse):
            if threadId == seenResponse.threadId {
                onSeen(seenResponse, nil, nil)
            }
        default:
            break
        }
    }

    func updateUnreadCount(_ threadId: Int, _ unreadCount: Int) {
        if threadId == self.threadId {
            thread.unreadCount = unreadCount
            objectWillChange.send()
        }
    }

    func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
            self.thread.unreadCount = thread.unreadCount
        }
    }

    func loadMoreMessage() {
        if !canLoadNexPage { return }
        isLoading = true
        getHistory(messages.first?.time)
    }

    func getHistory(_ toTime: UInt? = nil) {
        Chat.sharedInstance.getHistory(.init(threadId: threadId, count: count, offset: 0, order: "desc", toTime: toTime, readOnly: readOnly)) { [weak self] messages, _, pagination, _ in
            if let messages = messages {
                self?.setHasNext(pagination?.hasNext ?? false)
                self?.appendMessages(messages)
                self?.isLoading = false
            }
        } cacheResponse: { [weak self] messages, _, _ in
            if let messages = messages {
                self?.appendMessages(messages)
            }
        } textMessageNotSentRequests: { [weak self] messages, _, _ in
            self?.appendMessages(messages?.compactMap { SendTextMessage(from: $0, thread: self?.thread) } ?? [])
        } editMessageNotSentRequests: { [weak self] editMessages, _, _ in
            self?.appendMessages(editMessages?.compactMap { EditTextMessage(from: $0, thread: self?.thread) } ?? [])
        } forwardMessageNotSentRequests: { [weak self] forwardMessages, _, _ in
            self?.appendMessages(forwardMessages?.compactMap {
                ForwardMessage(from: $0, destinationThread: .init(id: $0.threadId, title: self?.threadName($0.threadId)), thread: self?.thread) } ?? []
            )
        } fileMessageNotSentRequests: { [weak self] fileMessages, _, _ in
            self?.appendMessages(fileMessages?.compactMap { UnsentUploadFileWithTextMessage(uploadFileRequest: $0.0, sendTextMessageRequest: $0.1, thread: self?.thread) } ?? [])
        }
    }

    func threadName(_ threadId: Int) -> String? {
        threadsViewModel?.threadsRowVM.first { $0.threadId == threadId }?.thread.title
    }

    func sendStartTyping(_ newValue: String) {
        if newValue.isEmpty == false {
            Chat.sharedInstance.snedStartTyping(threadId: threadId)
        } else {
            Chat.sharedInstance.sendStopTyping()
        }
    }

    func sendSeenMessageIfNeeded(_ message: Message) {
        if let messageId = message.id, let lastMsgId = thread.lastSeenMessageId, messageId > lastMsgId, message.isMe == false {
            thread.lastSeenMessageId = messageId
            print("send seen for message:\(message.messageTitle) with id:\(messageId)")
            Chat.sharedInstance.seen(.init(threadId: threadId, messageId: messageId))
            if let unreadCount = thread.unreadCount, unreadCount > 0 {
                thread.unreadCount = unreadCount - 1
                objectWillChange.send()
            }
        } else if thread.unreadCount ?? 0 > 0 {
            print("messageId \(message.id ?? 0) was bigger than threadLastSeesn\(thread.lastSeenMessageId ?? 0)")
            thread.unreadCount = 0
            objectWillChange.send()
        }
    }

    func sendSignal(_ signalMessage: SignalMessageType) {
        Chat.sharedInstance.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
    }

    func playAudio() {}

    func setMessageEdited(_ message: Message) {
        messages.first(where: { $0.id == message.id })?.message = message.message
    }

    /// Prevent reconstructing the thread in updates like from a cached version to a server version.
    func updateThread(_ thread: Conversation) {
        thread.updateValues(thread)
    }

    func updateThreadInfo(_ title: String, _ description: String, image: UIImage?, assetResources: [PHAssetResource]?) {
        var imageRequest: UploadImageRequest?
        if let image = image {
            let width = Int(image.size.width)
            let height = Int(image.size.height)
            imageRequest = UploadImageRequest(data: image.pngData() ?? Data(),
                                              hC: height,
                                              wC: width,
                                              fileExtension: "png",
                                              fileName: assetResources?.first?.originalFilename,
                                              mimeType: "image/png",
                                              originalName: assetResources?.first?.originalFilename,
                                              isPublic: true)
        }

        let req = UpdateThreadInfoRequest(description: description, threadId: threadId, threadImage: imageRequest, title: title)
        Chat.sharedInstance.updateThreadInfo(req) { _ in

        } uploadProgress: { _, _ in

        } completion: { _, _, _ in
        }
    }

    func searchInsideThread(text: String, offset: Int = 0) {
//        searchedMessages.removeAll()
        guard text.count >= 2 else { return }
        let req = GetHistoryRequest(threadId: threadId, count: 50, offset: offset, query: "\(text)")
        Chat.sharedInstance.getHistory(req) { [weak self] messages, _, _, _ in
            if let messages = messages {
                self?.searchedMessages.append(contentsOf: messages)
            }
        }
    }

    func delete() {
        Chat.sharedInstance.deleteThread(.init(subjectId: threadId)) { [weak self] threadId, _, error in
            if let self = self, threadId != nil, error == nil {
                self.threadsViewModel?.removeThreadVM(self)
            }
        }
    }

    func leave() {
        Chat.sharedInstance.leaveThread(.init(threadId: threadId, clearHistory: true)) { [weak self] user, _, error in
            if let self = self, user != nil, error == nil {
                self.threadsViewModel?.removeThreadVM(self)
            }
        }
    }

    func clearHistory() {
        Chat.sharedInstance.clearHistory(.init(subjectId: threadId)) { [weak self] threadId, _, _ in
            if let _ = threadId {
                self?.clear()
            }
        }
    }

    func spamPV() {
        Chat.sharedInstance.spamPvThread(.init(subjectId: threadId)) { _, _, _ in }
    }

    func appendMessages(_ messages: [Message]) {
        messages.forEach { message in
            if let oldMessage = self.messages.first(where: { $0.uniqueId == message.uniqueId }) {
                oldMessage.updateMessage(message: message)
            } else if message.conversation?.id == threadId {
                self.messages.append(message)
                thread.unreadCount = message.conversation?.unreadCount ?? 1
                thread.lastMessageVO = message
                thread.lastMessage = message.message
            }
        }
        sort()
        updateScrollToLastSeenUniqueId()
    }

    func deleteMessages(_ messages: [Message]) {
        let messagedIds = messages.compactMap { $0.id }
        Chat.sharedInstance.deleteMultipleMessages(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: true), completion: onDeleteMessage)
        selectedMessages = []
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    func onDeleteMessage(message: Message? = nil, uniqueId: String? = nil, error: ChatError? = nil) {
        messages.removeAll(where: { $0.uniqueId == message?.uniqueId || message?.id == $0.id })
    }

    func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    func clear() {
        messages = []
    }

    func pinMessage(_ message: Message) {
        messages.first(where: { $0.id == message.id })?.pinned = true
    }

    func unpinMessage(_ message: Message) {
        messages.first(where: { $0.id == message.id })?.pinned = false
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
}
