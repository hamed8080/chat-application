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

protocol ThreadViewModelProtocol {
    var thread: Conversation { get set }
    var messages: [Message] { get set }
    var editMessage: Message? { get set }
    var textMessage: String? { get set }
    var threadId: Int { get }
    var readOnly: Bool { get }
    var canLoadNexPage: Bool { get }
    var threadsViewModel: ThreadsViewModel? { get set }
    var isTyping: Bool { get set }
    var canAddParticipant: Bool { get }
    var hasNext: Bool { get set }
    var count: Int { get }
    func delete()
    func leave()
    func togglePin()
    func pin()
    func unpin()
    func onPinChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?)
    func clearHistory()
    func toggleMute()
    func mute()
    func unmute()
    func onMuteChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?)
    func spamPV()
    func deleteMessages(_ messages: [Message])
    func loadMoreMessage()
    func getHistory(_ toTime: UInt?)
    func sendSignal(_ signalMessage: SignalMessageType)
    func sendPhotos(uiImage: UIImage?, info: [AnyHashable: Any]?, item: ImageItem)
    func sendFile(_ url: URL)
    func toggleArchive()
    func archive()
    func unarchive()
    func onArchiveChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?)
    func onLastMessageChanged(_ thread: Conversation)
    func onEditedMessage(_ editedMessage: Message?)
    func sendEditMessage(_ textMessage: String)
    func sendTextMessage(_ textMessage: String)
    func sendReplyMessage(_ replyMessageId: Int, _ textMessage: String)
    func sendNormalMessage(_ textMessage: String)
    func sendForwardMessage(_ destinationThread: Conversation)
    func sendSeenMessageIfNeeded(_ message: Message)
    func updateThread(_ thread: Conversation)
    func resendUnsetMessage(_ message: Message)
    func cancelUnsentMessage(_ uniqueId: String)
    func threadName(_ threadId: Int) -> String?
    func searchInsideThread(text: String, offset: Int)
    func isSameUser(message: Message) -> Bool
}

class ThreadViewModel: ObservableObject, ThreadViewModelProtocol, Identifiable, Hashable {
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

    var textMessage: String? = nil

    var readOnly = false

    @Published
    var searchedMessages: [Message] = []

    @Published
    var messages: [Message] = []

    @Published
    var isTyping: Bool = false

    private(set) var cancellableSet: Set<AnyCancellable> = []

    private var typingTimerStarted = false

    lazy var audioRecoderVM: AudioRecordingViewModel = .init(threadViewModel: self)

    var hasNext = true

    var count: Int { 15 }

    var threadId: Int { thread.id ?? 0 }

    weak var threadsViewModel: ThreadsViewModel?

    var canAddParticipant: Bool { thread.group ?? false && thread.admin ?? false == true }

    var signalMessageText: String?
    weak var replyMessage: Message?
    weak var forwardMessage: Message?

    @Published
    var isInEditMode: Bool = false

    @Published
    var selectedMessages: [Message] = []

    @Published
    var editMessage: Message?

    @Published
    var exportMessagesVM: ExportMessagesViewModelProtocol

    var canLoadNexPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .connected }

    init(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.readOnly = readOnly
        self.thread = thread
        self.exportMessagesVM = ExportMessagesViewModel(thread: thread)
        self.threadsViewModel = threadsViewModel
        NotificationCenter.default.publisher(for: SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME)
            .compactMap { $0.object as? SystemEventTypes }
            .sink { [weak self] systemMessageEvent in
                self?.startTypingTimer(systemMessageEvent)
            }
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: THREAD_EVENT_NOTIFICATION_NAME)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                if case .messageNew(let message) = event {
                    self?.appendMessage(message)
                }
            }
            .store(in: &cancellableSet)
    }

    func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .lastMessageDeleted(let thread), .lastMessageEdited(let thread):
            onLastMessageChanged(thread)
        default:
            break
        }
    }

    func onLastMessageChanged(_ thread: Conversation) {
        if thread.id == threadId {
            self.thread.lastMessage = thread.lastMessage
            self.thread.lastMessageVO = thread.lastMessageVO
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
                self?.appendMessages(messages: messages)
                self?.isLoading = false
            }
        } cacheResponse: { [weak self] messages, _, _ in
            if let messages = messages {
                self?.appendMessages(messages: messages)
            }
        } textMessageNotSentRequests: { [weak self] messages, _, _ in
            self?.appendMessages(messages: messages?.compactMap { SendTextMessage(from: $0) } ?? [])
        } editMessageNotSentRequests: { [weak self] editMessages, _, _ in
            self?.appendMessages(messages: editMessages?.compactMap { EditTextMessage(from: $0) } ?? [])
        } forwardMessageNotSentRequests: { [weak self] forwardMessages, _, _ in
            self?.appendMessages(messages: forwardMessages?.compactMap { ForwardMessage(from: $0, destinationThread: .init(id: $0.threadId, title: self?.threadName($0.threadId))) } ?? [])
        } fileMessageNotSentRequests: { [weak self] fileMessages, _, _ in
            self?.appendMessages(messages: fileMessages?.compactMap { UnsentUploadFileWithTextMessage(uploadFileRequest: $0.0, sendTextMessageRequest: $0.1) } ?? [])
        }
    }

    func threadName(_ threadId: Int) -> String? {
        threadsViewModel?.threadsRowVM.first { $0.threadId == threadId }?.thread.title
    }

    func setupPreview() {
        setupPreview()
    }

    func deleteMessages(_ messages: [Message]) {
        let messagedIds = messages.compactMap { $0.id }
        Chat.sharedInstance.deleteMultipleMessages(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: true), completion: onDeleteMessage)
    }

    /// It triggers when send button tapped
    func sendTextMessage(_ textMessage: String) {
        if let replyMessage = replyMessage, let replyMessageId = replyMessage.id {
            sendReplyMessage(replyMessageId, textMessage)
        } else if editMessage != nil {
            sendEditMessage(textMessage)
        } else {
            sendNormalMessage(textMessage)
        }
        setIsInEditMode(false) // close edit mode in ui
    }

    func sendReplyMessage(_ replyMessageId: Int, _ textMessage: String) {
        let req = ReplyMessageRequest(threadId: threadId,
                                      repliedTo: replyMessageId,
                                      textMessage: textMessage,
                                      messageType: .text)
        Chat.sharedInstance.replyMessage(req) { _ in

        } onSent: { _, _, _ in

        } onSeen: { _, _, _ in

        } onDeliver: { _, _, _ in
        }
    }

    func sendEditMessage(_ textMessage: String) {
        guard let editMessage = editMessage, let messageId = editMessage.id else { return }
        let req = EditMessageRequest(threadId: threadId,
                                     messageType: .text,
                                     messageId: messageId,
                                     textMessage: textMessage)
        self.editMessage = nil
        isInEditMode = false
        Chat.sharedInstance.editMessage(req) { [weak self] editedMessage, _, _ in
            self?.onEditedMessage(editedMessage)
        }
    }

    func onEditedMessage(_ editedMessage: Message?) {
        if let editedMessage = editedMessage, let index = messages.firstIndex(where: { $0.id == editedMessage.id }) {
            withAnimation(.easeInOut) {
                messages[index] = editedMessage
            }
        }
    }

    func sendNormalMessage(_ textMessage: String) {
        let req = SendTextMessageRequest(threadId: threadId,
                                         textMessage: textMessage,
                                         messageType: .text)
        Chat.sharedInstance.sendTextMessage(req) { _ in

        } onSent: { _, _, _ in

        } onSeen: { _, _, _ in

        } onDeliver: { _, _, _ in
        }
    }

    func sendForwardMessage(_ destinationThread: Conversation) {
        guard let destinationThreadId = destinationThread.id else { return }
        let messageIds = selectedMessages.compactMap { $0.id }
        let req = ForwardMessageRequest(fromThreadId: threadId, threadId: destinationThreadId, messageIds: messageIds)
        Chat.sharedInstance.forwardMessages(req) { _, _, _ in

        } onSeen: { _, _, _ in

        } onDeliver: { _, _, _ in

        } uniqueIdsResult: { _ in
        }
        setIsInEditMode(false) // close edit mode in ui
    }

    func textChanged(_ newValue: String) {
        if newValue.isEmpty == false {
            Chat.sharedInstance.snedStartTyping(threadId: threadId)
        } else {
            Chat.sharedInstance.sendStopTyping()
        }
    }

    func sendSeenMessageIfNeeded(_ message: Message) {
        guard let messageId = message.id else { return }
        if let lastMsgId = thread.lastSeenMessageId, messageId > lastMsgId {
            Chat.sharedInstance.seen(.init(messageId: messageId))
            // update cache read count
            //            CacheFactory.write(cacheType: .threads([thread]))
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    func sendPhotos(uiImage: UIImage?, info: [AnyHashable: Any]?, item: ImageItem) {
        guard let image = uiImage else { return }
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let fileName = item.phAsset.originalFilename
        let imageRequest = UploadImageRequest(data: image.jpegData(compressionQuality: 1.0) ?? Data(),
                                              hC: height,
                                              wC: width,
                                              fileName: fileName,
                                              mimeType: "image/jpg",
                                              userGroupHash: thread.userGroupHash)
        let textRequest = textMessage == nil || textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: .picture)
        appendMessages(messages: [UploadFileWithTextMessage(uploadFileRequest: imageRequest, sendTextMessageRequest: textRequest)])
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    func sendFile(_ url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        let uploadRequest = UploadFileRequest(data: data,
                                              fileExtension: ".\(url.fileExtension)",
                                              fileName: url.fileName,
                                              mimeType: url.mimeType,
                                              userGroupHash: thread.userGroupHash)
        let textRequest = textMessage == nil || textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: .file)
        appendMessages(messages: [UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest)])
    }

    func sendSignal(_ signalMessage: SignalMessageType) {
        Chat.sharedInstance.sendSignalMessage(req: .init(signalType: signalMessage, threadId: threadId))
    }

    func playAudio() {}

    func setReplyMessage(_ message: Message?) {
        replyMessage = message
    }

    func setForwardMessage(_ message: Message?) {
        isInEditMode = message != nil
        forwardMessage = message
    }

    func toggleSelectedMessage(_ message: Message, _ isSelected: Bool) {
        if isSelected {
            appendSelectedMessage(message)
        } else {
            removeSelectedMessage(message)
        }
    }

    func setIsInEditMode(_ isInEditMode: Bool) {
        self.isInEditMode = isInEditMode
    }

    func setEditMessage(_ message: Message) {
        editMessage = message
    }

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

    func togglePin() {
        if thread.pin == false {
            pin()
        } else {
            unpin()
        }
    }

    func pin() {
        Chat.sharedInstance.pinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    func unpin() {
        Chat.sharedInstance.unpinThread(.init(subjectId: threadId), completion: onPinChanged)
    }

    func onPinChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            thread.pin?.toggle()
            objectWillChange.send()
        }
    }

    func clearHistory() {
        Chat.sharedInstance.clearHistory(.init(subjectId: threadId)) { [weak self] threadId, _, _ in
            if let _ = threadId {
                self?.clear()
            }
        }
    }

    func toggleMute() {
        if thread.mute ?? false == false {
            mute()
        } else {
            unmute()
        }
    }

    func mute() {
        Chat.sharedInstance.muteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func unmute() {
        Chat.sharedInstance.unmuteThread(.init(subjectId: threadId), completion: onMuteChanged)
    }

    func onMuteChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            thread.mute?.toggle()
            objectWillChange.send()
        }
    }

    func spamPV() {
        Chat.sharedInstance.spamPvThread(.init(subjectId: threadId)) { _, _, _ in }
    }

    private var lastIsTypingTime = Date()

    private func startTypingTimer(_ event: SystemEventTypes) {
        if case .systemMessage(let message, _, let id) = event, message.smt == .isTyping, isTyping == false, thread.id == id {
            lastIsTypingTime = Date()
            isTyping = true
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                if let self = self, self.lastIsTypingTime.advanced(by: 1) < Date() {
                    timer.invalidate()
                    self.isTyping = false
                }
            }
        } else {
            lastIsTypingTime = Date()
        }
    }

    func appendMessages(messages: [Message]) {
        messages.forEach { message in
            if let oldMessage = self.messages.first(where: { $0.id == message.id }) {
                oldMessage.updateMessage(message: message)
            } else {
                self.messages.append(message)
            }
        }
        sort()
    }

    /// Delete a message with an Id is needed for when the message has persisted before.
    /// Delete a message with a uniqueId is needed for when the message is sent to a request.
    func onDeleteMessage(message: Message? = nil, uniqueId: String? = nil, error: ChatError? = nil) {
        messages.removeAll(where: { $0.uniqueId == message?.uniqueId || message?.id == $0.id })
    }

    func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    func appendMessage(_ message: Message) {
        if message.conversation?.id == threadId {
            messages.append(message)
            thread.unreadCount = message.conversation?.unreadCount ?? 1
            thread.lastMessageVO = message
            thread.lastMessage = message.message
            sort()
        }
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

    func appendSelectedMessage(_ message: Message) {
        selectedMessages.append(message)
    }

    func removeSelectedMessage(_ message: Message) {
        guard let index = selectedMessages.firstIndex(of: message) else { return }
        selectedMessages.remove(at: index)
    }

    func toggleArchive() {
        if thread.isArchive == false {
            archive()
        } else {
            unarchive()
        }
    }

    func archive() {
        Chat.sharedInstance.archiveThread(.init(subjectId: threadId), onArchiveChanged)
    }

    func unarchive() {
        Chat.sharedInstance.unarchiveThread(.init(subjectId: threadId), onArchiveChanged)
    }

    func onArchiveChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            thread.isArchive?.toggle()
            objectWillChange.send()
        }
    }

    func resendUnsetMessage(_ message: Message) {
        switch message {
        case let req as SendTextMessage:
            Chat.sharedInstance.sendTextMessage(req.sendTextMessageRequest, onSent: onUnSentResult)
        case let req as EditTextMessage:
            Chat.sharedInstance.editMessage(req.editMessageRequest, completion: onUnSentEditCompletionResult)
        case let req as ForwardMessage:
            Chat.sharedInstance.forwardMessages(req.forwardMessageRequest, onSent: onUnSentResult)
        case let req as UploadFileWithTextMessage:
            appendMessage(UploadFileWithTextMessage(uploadFileRequest: req.uploadFileRequest))
        default:
            print("Type not detected!")
        }
    }

    func onUnSentEditCompletionResult(_ message: Message?, _ uniqueId: String?, _ error: ChatError?) {
        if let message = message, threadId == message.conversation?.id {
            onDeleteMessage(uniqueId: uniqueId)
            appendMessages(messages: [message])
        }
    }

    func onUnSentResult(_ message: SentMessageResponse?, _ uniqueId: String?, _ error: ChatError?) {
        if let uniqueId = uniqueId, message != nil {
            onDeleteMessage(uniqueId: uniqueId)
        }
    }

    func cancelUnsentMessage(_ uniqueId: String) {
        CacheFactory.write(cacheType: .deleteQueue(uniqueId))
        CacheFactory.save()
        onDeleteMessage(uniqueId: uniqueId)
    }

    func isSameUser(message: Message) -> Bool {
        if let previousMessage = messages.first(where: { $0.id == message.previousId }) {
            return previousMessage.participant?.id ?? 0 == message.participant?.id ?? -1
        }
        return false
    }
}
