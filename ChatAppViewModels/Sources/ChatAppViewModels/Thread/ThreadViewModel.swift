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

public final class ThreadViewModel: ObservableObject, Identifiable, Hashable {
    public static func == (lhs: ThreadViewModel, rhs: ThreadViewModel) -> Bool {
        rhs.threadId == lhs.threadId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    public var thread: Conversation
    public var centerLoading = false
    @Published public var topLoading = false
    @Published public var bottomLoading = false
    public var canLoadMoreTop: Bool { hasNextTop && !topLoading }
    public var canLoadMoreBottom: Bool { !bottomLoading && messages.last?.id != thread.lastMessageVO?.id }
    public var messages: [Message] = []
    @Published public var selectedMessages: [Message] = []
    @Published public var editMessage: Message?
    public var replyMessage: Message?
    @Published public var isInEditMode: Bool = false
    public var exportMessagesVM: ExportMessagesViewModelProtocol = ExportMessagesViewModel()
    public var mentionList: [Participant] = []
    public var dropItems: [DropItem] = []
    public var sheetType: ThreadSheetType?
    public var selectedLocation: MKCoordinateRegion = .init()
    public var isFetchedServerFirstResponse: Bool = false
    public var searchedMessages: [Message] = []
    public var isInSearchMode: Bool = false
    public var readOnly = false
    public var textMessage: String?
    public var canScrollToBottomOfTheList: Bool = false
    private var cancelable: Set<AnyCancellable> = []
    private var typingTimerStarted = false
    public lazy var audioRecoderVM: AudioRecordingViewModel = .init(threadViewModel: self)
    public var hasNextTop = true
    public var hasNextBottom = true
    public var count: Int { 15 }
    public var threadId: Int { thread.id ?? 0 }
    public weak var threadsViewModel: ThreadsViewModel?
    public var signalMessageText: String?
    public var searchTextTimer: Timer?
    public var isActiveThread: Bool { AppState.shared.activeThreadId == threadId }
    public var audioPlayer: AVAudioPlayerViewModel?
    var requests: [String: Any] = [:]
    public var isAtBottomOfTheList: Bool = false
    public var highliteMessageId: Int?
    var highlightTimer: Timer?
    var searchOffset: Int = 0
    public var scrollProxy: ScrollViewProxy?
    public var scrollingUP = false
    var lastOrigin: CGFloat = 0
    public var lastVisibleUniqueId: String?
    public weak var forwardMessage: Message?

    public init(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
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
            getHistory()
        }
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if threadId == response.subjectId, let message = response.result {
            appendMessages([message])
            animatableObjectWillChange()
            scrollToLastMessageIfLastMessageIsVisible()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
            self.thread.unreadCount = thread.unreadCount
            if let lastMessage = thread.lastMessageVO, let index = messageIndex(lastMessage.id) {
                messages[index] = lastMessage
            }
            animatableObjectWillChange()
        }
    }

    public func onMessageAppear(_ message: Message) {
        /// We get next item in the list because when we scrolling up the message is beneth NavigationView so we should get the next item to ensure we are in right position
        if scrollingUP, let index = messageIndex(message.id), messages.indices.contains(index + 1) {
            let message = messages[index + 1]
            print("Scrolling up lastVisibleUniqueId :\(message.uniqueId ?? "") and message is: \(message.message ?? "")")
            lastVisibleUniqueId = message.uniqueId
            isAtBottomOfTheList = false
            animatableObjectWillChange()
        } else if !scrollingUP, let index = messageIndex(message.id), messages.indices.contains(index - 1), messages.last?.id != message.id {
            let message = messages[index - 1]
            print("Scroling Down lastVisibleUniqueId :\(message.uniqueId ?? "") and message is: \(message.message ?? "")")
            lastVisibleUniqueId = message.uniqueId
            sendSeenMessageIfNeeded(message)
            isAtBottomOfTheList = false
            animatableObjectWillChange()
        } else {
            // Last Item
            print("Last Item lastVisibleUniqueId :\(message.uniqueId ?? "") and message is: \(message.message ?? "")")
            lastVisibleUniqueId = message.uniqueId
            sendSeenMessageIfNeeded(message)
            isAtBottomOfTheList = true
            animatableObjectWillChange()
        }

        if scrollingUP, let lastIndex = messages.firstIndex(where: { lastVisibleUniqueId == $0.uniqueId }), lastIndex < 3 {
            moreTop(messages.first?.time?.advanced(by: 100))
        }

        if !scrollingUP, message.id == messages.last?.id {
            moreBottom(messages.last?.time?.advanced(by: -100))
        }
    }

    func onQueueTextMessages(_ response: ChatResponse<[SendTextMessageRequest]>) {
        appendMessages(response.result?.compactMap { SendTextMessage(from: $0, thread: thread) } ?? [])
    }

    func onQueueEditMessages(_ response: ChatResponse<[EditMessageRequest]>) {
        appendMessages(response.result?.compactMap { EditTextMessage(from: $0, thread: thread) } ?? [])
    }

    func onQueueForwardMessages(_ response: ChatResponse<[ForwardMessageRequest]>) {
        appendMessages(response.result?.compactMap { ForwardMessage(from: $0,
                                                                    destinationThread: .init(id: $0.threadId, title: threadName($0.threadId)),
                                                                    thread: thread) } ?? [])
    }

    func onQueueFileMessages(_ response: ChatResponse<[(UploadFileRequest, SendTextMessageRequest)]>) {
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
        if let messageId = message.id, let lastMsgId = thread.lastSeenMessageId, messageId > lastMsgId, !isMe {
            thread.lastSeenMessageId = messageId
            print("send seen for message:\(message.messageTitle) with id:\(messageId)")
            ChatManager.activeInstance?.message.seen(.init(threadId: threadId, messageId: messageId))
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

    public func sendSignal(_ signalMessage: SignalMessageType) {
        ChatManager.activeInstance?.system.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
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
        appenedUnreadMessagesRowsIfNeeed()
        sort()
    }

    func appenedUnreadMessagesRowsIfNeeed() {
        guard let lastMessageId = thread.lastSeenMessageId,
              thread.unreadCount ?? 0 > 1,
              let lastSeenIndex = self.messages.firstIndex(where: { $0.id == lastMessageId })
        else { return }
        messages.removeAll(where: { $0 is UnreadMessageProtocol })
        messages.append(UnreadMessage(time: (messages[lastSeenIndex].time ?? 0) + 1))
    }

    public func deleteMessages(_ messages: [Message]) {
        let messagedIds = messages.compactMap(\.id)
        ChatManager.activeInstance?.message.delete(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: true))
        selectedMessages = []
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    public func onDeleteMessage(_ response: ChatResponse<Message>) {
        guard let responseThreadId = response.subjectId ?? response.result?.threadId ?? response.result?.conversation?.id,
              threadId == responseThreadId
        else { return }
        messages.removeAll(where: { $0.uniqueId == response.uniqueId || response.result?.id == $0.id })
        animatableObjectWillChange()
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
            let req = ThreadParticipantRequest(threadId: threadId, name: rangeText)
            requests[req.uniqueId] = req
            ChatManager.activeInstance?.conversation.participant.get(req)
        } else {
            let mentionListWasFill = mentionList.count > 0
            mentionList = []
            if mentionListWasFill {
                animatableObjectWillChange()
            }
        }
    }

    func onMentionParticipants(_ response: ChatResponse<[Participant]>) {
        if let mentionList = response.result, let uniqueId = response.uniqueId, requests[uniqueId] != nil {
            self.mentionList = mentionList
            requests.removeValue(forKey: uniqueId)
            animatableObjectWillChange()
        }
    }

    public func messageIndex(_ messageId: Int?) -> Array<Message>.Index? {
        messages.firstIndex(where: { $0.id == messageId })
    }

    public func animatableObjectWillChange() {
        withAnimation {
            objectWillChange.send()
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
                DispatchQueue.main.async {  [weak self] in
                    self?.dropItems.append(
                        .init(data: data,
                              name: name,
                              iconName: iconName,
                              ext: ext)
                    )
                    self?.animatableObjectWillChange()
                }
            }
        }
    }

    public func onUnreadCount(_ response: ChatResponse<UnreadCount>) {
        if threadId == response.result?.threadId {
            thread.unreadCount = response.result?.unreadCount
            objectWillChange.send()
        }
    }

    /// This method will be called whenver we send seen for an unseen message by ourself.
    public func onLastSeenMessageUpdated(_ response: ChatResponse<LastSeenMessageResponse>) {
        if threadId == response.subjectId {
            thread.lastSeenMessageTime = response.result?.lastSeenMessageTime
            thread.lastSeenMessageId = response.result?.lastSeenMessageId
            thread.lastSeenMessageNanos = response.result?.lastSeenMessageNanos
            thread.unreadCount = response.contentCount
            objectWillChange.send()
        }
    }
}
