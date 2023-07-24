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
import OrderedCollections
import OSLog

public struct MessageSection: Identifiable, Hashable, Equatable {
    public var id: Date { date }
    public let date: Date
    public var messages: [Message]
}

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
    public var canLoadMoreTop: Bool { hasNextTop && !topLoading && !disableScrolling }
    public var canLoadMoreBottom: Bool { !bottomLoading && sections.last?.messages.last?.id != thread.lastMessageVO?.id && hasNextBottom && !disableScrolling }
    public var sections: [MessageSection] = []
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
    public var audioRecoderVM: AudioRecordingViewModel = .init()
    public var hasNextTop = true
    public var hasNextBottom = true
    public var count: Int { 15 }
    public var threadId: Int { thread.id ?? 0 }
    public weak var threadsViewModel: ThreadsViewModel?
    public var signalMessageText: String?
    public var searchTextTimer: Timer?
    public var isActiveThread: Bool { AppState.shared.activeThreadId == threadId }
    var requests: [String: Any] = [:]
    public var isAtBottomOfTheList: Bool = false    
    var searchOffset: Int = 0
    public var scrollProxy: ScrollViewProxy?
    public var scrollingUP = false
    var lastOrigin: CGFloat = 0
    public var lastVisibleUniqueId: String?
    public weak var forwardMessage: Message?
    /// The property `DisableScrolling` works as a mechanism to prevent sending a new request to the server every time SwiftUI tries to calculate and layout our views rows, because SwiftUI starts rendering at the top when we load more top.
    public var disableScrolling: Bool = false
    public lazy var sheetViewModel: ActionSheetViewModel = {
        let sheetViewModel = ActionSheetViewModel()
        sheetViewModel.threadViewModel  = self
        return sheetViewModel
    }()

    public init(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.readOnly = readOnly
        self.thread = thread
        self.threadsViewModel = threadsViewModel
        self.audioRecoderVM.threadViewModel = self
        setupNotificationObservers()
        exportMessagesVM.setup(thread)
    }

    private func setupNotificationObservers() {
        AppState.shared.$connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .chatEvents)
            .compactMap { $0.object as? ChatEventType }
            .sink { [weak self] event in
                self?.onChatEvent(event)
            }
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
            if let lastMessage = thread.lastMessageVO,
               let messageId = lastMessage.id,
               let sectionIndex = sectionIndexByMessageId(messageId),
               let index = messageIndex(messageId, in: sectionIndex) {
                sections[sectionIndex].messages[index] = lastMessage
            }
            animatableObjectWillChange()
        }
    }

    public func onMessageAppear(_ message: Message) {
        /// We get next item in the list because when we are scrolling up the message is beneth NavigationView so we should get the next item to ensure we are in right position
        guard
            let sectionIndex = sectionIndexByMessageId(message),
            let messageIndex = messageIndex(message.id ?? -1, in: sectionIndex)
        else { return }
        let section = sections[sectionIndex]
        if scrollingUP, section.messages.indices.contains(messageIndex + 1) == true {
            let message = section.messages[messageIndex + 1]
            Logger.viewModels.info("Scrolling up lastVisibleUniqueId :\(message.uniqueId ?? "") and message is: \(message.message ?? "", privacy: .sensitive)")
            lastVisibleUniqueId = message.uniqueId
            isAtBottomOfTheList = false
            animatableObjectWillChange()
        } else if !scrollingUP, section.messages.indices.contains(messageIndex - 1), section.messages.last?.id != message.id {
            let message = section.messages[messageIndex - 1]
            Logger.viewModels.info("Scroling Down lastVisibleUniqueId :\(message.uniqueId ?? "") and message is: \(message.message ?? "", privacy: .sensitive)")
            lastVisibleUniqueId = message.uniqueId
            sendSeenMessageIfNeeded(message)
            isAtBottomOfTheList = false
            animatableObjectWillChange()
        } else {
            // Last Item
            Logger.viewModels.info("Last Item lastVisibleUniqueId :\(message.uniqueId ?? "") and message is: \(message.message ?? "", privacy: .sensitive)")
            lastVisibleUniqueId = message.uniqueId
            sendSeenMessageIfNeeded(message)
            isAtBottomOfTheList = true
            animatableObjectWillChange()
        }

        if scrollingUP, let lastIndex = sections.first?.messages.firstIndex(where: { lastVisibleUniqueId == $0.uniqueId }), lastIndex < 3 {
            moreTop(sections.first?.messages.first?.time?.advanced(by: 100))
        }

        if !scrollingUP, message.id == sections.last?.messages.last?.id {
            moreBottom(sections.last?.messages.last?.time?.advanced(by: 1))
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
        guard
            let indices = indicesByMessageId(response.result?.id ?? -1),
            let editedMessage = response.result,
            sections.indices.contains(indices.sectionIndex),
            sections[indices.sectionIndex].messages.indices.contains(indices.messageIndex)
        else { return }
        let oldMessage = sections[indices.sectionIndex].messages[indices.messageIndex]
        oldMessage.updateMessage(message: editedMessage)
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
            Logger.viewModels.info("send seen for message:\(message.messageTitle, privacy: .sensitive) with id:\(messageId)")
            ChatManager.activeInstance?.message.seen(.init(threadId: threadId, messageId: messageId))
            if let unreadCount = thread.unreadCount, unreadCount > 0 {
                thread.unreadCount = unreadCount - 1
                objectWillChange.send()
            }
        } else if thread.unreadCount ?? 0 > 0 {
            Logger.viewModels.info("messageId \(message.id ?? 0) was bigger than threadLastSeesn\(self.thread.lastSeenMessageId ?? 0)")
            thread.unreadCount = 0
            objectWillChange.send()
        }
    }

    public func sendSignal(_ signalMessage: SignalMessageType) {
        ChatManager.activeInstance?.system.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
    }

    public func appendMessages(_ messages: [Message], isToTime: Bool = false) {
        guard messages.count > 0 else { return }
        messages.forEach { message in
            insertOrUpdate(message)
        }
        appenedUnreadMessagesBannerIfNeeed(isToTime)
        sort()
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
    }

    func indicesByMessageId(_ id: Int) -> (sectionIndex: Array<MessageSection>.Index, messageIndex: Array<Message>.Index)? {
        guard
            let sectionIndex = sectionIndexByMessageId(id),
            let messageIndex = messageIndex(id, in: sectionIndex)
        else { return nil }
        return (sectionIndex: sectionIndex, messageIndex: messageIndex)
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

    func sectionIndexByUniqueId(_ message: Message) -> Array<MessageSection>.Index? {
        sectionIndexByUniqueId(message.uniqueId ?? "")
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

    public func removeById(_ id: Int?) {
        guard let id = id, let indices = indicesByMessageId(id) else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
    }

    public func removeByUniqueId(_ uniqueId: String?) {
        guard let uniqueId = uniqueId, let indices = indicesByMessageUniqueId(uniqueId) else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
    }

    func appenedUnreadMessagesBannerIfNeeed(_ isToTime: Bool) {
        if thread.lastMessageVO?.ownerId == AppState.shared.user?.id {
            removeAllUnreadSeen()
            return
        }
        guard isToTime,
              let lastSeenMessageId = thread.lastSeenMessageId,
              let indices = indicesByMessageId(lastSeenMessageId)
        else { return }
        removeAllUnreadSeen()
        sections[indices.sectionIndex].messages.append(UnreadMessage(id: -2, time: (sections[indices.sectionIndex].messages[indices.messageIndex].time ?? 0) + 1))
    }

    func removeAllUnreadSeen() {
        sections.indices.forEach { sectionIndex in
            sections[sectionIndex].messages.removeAll(where: {$0 is UnreadMessageProtocol})
        }
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
              threadId == responseThreadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId, response.result?.id)
        else { return }
        sections[indices.sectionIndex].messages.remove(at: indices.messageIndex)
        if sections[indices.sectionIndex].messages.count == 0 {
            sections.remove(at: indices.sectionIndex)
        }
        animatableObjectWillChange()
    }

    public func sort() {
        sections.indices.forEach { sectionIndex in
            sections[sectionIndex].messages.sort { m1, m2 in
                if let t1 = m1.time, let t2 = m2.time {
                    return t1 < t2
                } else {
                    return false
                }
            }
        }
        sections.sort(by: {$0.date < $1.date})
    }

    public func isSameUser(message: Message) -> Bool {
        if let indices = indicesByMessageId(message.previousId ?? -1) {
            return sections[indices.sectionIndex].messages[indices.messageIndex].participant?.id ?? 0 == message.participant?.id ?? -1
        }
        return false
    }

    public func searchForParticipantInMentioning(_ text: String) {
        if text.matches(char: "@")?.last != nil, text.split(separator: " ").last?.first == "@", text.last != " " {
            let rangeText = text.split(separator: " ").last?.replacingOccurrences(of: "@", with: "")
            let req = ThreadParticipantRequest(threadId: threadId, name: rangeText)
            let key = req.uniqueId
            requests[key] = req
            ChatManager.activeInstance?.conversation.participant.get(req)
            addCancelTimer(key: key)
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

    /// Automatically cancel a request if there is no response come back from the chat server after 5 seconds.
    func addCancelTimer(key: String) {
        Logger.viewModels.info("Send request with key:\(key)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if ((self?.requests.keys.contains(where: { $0 == key})) != nil) {
                withAnimation {
                    self?.requests.removeValue(forKey: key)
                    self?.topLoading = false
                    self?.bottomLoading = false
                }
            }
        }
    }
}
