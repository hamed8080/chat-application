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
    var editMessage: Message? {get set}
    var threadId: Int { get }
    var readOnly: Bool { get }
    var canLoadNexPage: Bool { get }
    var threadsViewModel: ThreadsViewModel? { get set }
    var showManageFolder: Bool { get set }
    var showAddPaticipantToThread: Bool { get set }
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
    func sendFile(_ url: URL, textMessage: String?)
    func toggleArchive()
    func archive()
    func unarchive()
    func onArchiveChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?)
}

class ThreadViewModel: ObservableObject, ThreadViewModelProtocol {
    @Published
    var thread: Conversation

    @Published
    var isLoading = false

    @Published
    var textMessage: String = ""

    var readOnly = false

    @Published
    var searchedMessages: [Message] = []

    @Published
    var seachableText = ""

    @Published
    var messages: [Message] = []

    @Published
    var isTyping: Bool = false

    private(set) var cancellableSet: Set<AnyCancellable> = []

    private var typingTimerStarted = false

    lazy var audioRecoderVM: AudioRecordingViewModel = {
        return AudioRecordingViewModel(threadViewModel: self)
    }()

    var hasNext = true

    var count: Int { 15 }

    var threadId: Int { thread.id ?? 0 }

    var threadsViewModel: ThreadsViewModel?

    var showManageFolder: Bool = false

    var showAddPaticipantToThread: Bool = false

    var canAddParticipant: Bool {
        let type = thread.type
        return type == .channelGroup || type == .publicGroup
    }

    var signalMessageText: String?
    var replyMessage: Message?
    var forwardMessage: Message?
    var isInEditMode: Bool = false
    var selectedMessages: [Message] = []

    @Published
    var editMessage: Message?
    
    @Published
    var exportMessagesVM: ExportMessagesViewModelProtocol

    var canLoadNexPage: Bool { !isLoading && hasNext && AppState.shared.connectionStatus == .CONNECTED }

    init(thread: Conversation, readOnly: Bool = false, threadsViewModel: ThreadsViewModel? = nil) {
        self.readOnly = readOnly
        self.thread = thread
        self.exportMessagesVM = ExportMessagesViewModel(thread: thread)
        self.threadsViewModel = threadsViewModel
        NotificationCenter.default.publisher(for: SYSTEM_MESSAGE_EVENT_NOTIFICATION_NAME)
            .compactMap { $0.object as? SystemEventTypes }
            .sink { systemMessageEvent in
                self.startTypingTimer(systemMessageEvent)
            }
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: MESSAGE_NOTIFICATION_NAME)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { event in
                if case .messageNew(let message) = event {
                    self.appendMessage(message)
                }
            }
            .store(in: &cancellableSet)
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
        }
    }

    func setupPreview() {
        setupPreview()
    }

    func deleteMessages(_ messages: [Message]) {
        let messagedIds = messages.compactMap { $0.id }
        Chat.sharedInstance.deleteMultipleMessages(.init(threadId: threadId, messageIds: messagedIds, deleteForAll: true)) { message, _, _ in
            self.messages.removeAll(where: { $0.id == message?.id })
        }
    }

    func clearCacheFile(message: Message) {
        if let metadata = message.metadata?.data(using: .utf8), let fileHashCode = try? JSONDecoder().decode(FileMetaData.self, from: metadata).fileHash {
            CacheFileManager.sharedInstance.deleteImageFromCache(fileHashCode: fileHashCode)
        }
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
        Chat.sharedInstance.editMessage(req) { editedMessage, _, _ in
            if let editedMessage = editedMessage {
                self.setEditMessage(editedMessage)
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
        let req = ForwardMessageRequest(threadId: destinationThreadId, messageIds: messageIds)
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

    func searchInsideThreadMessages(_ text: String) {
        // -FIXME: add when merger with serach branch
        //        Chat.sharedInstance.searchThread
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
    func sendPhotos(uiImage: UIImage?, info: [AnyHashable: Any]?, item: ImageItem, textMessage: String = "") {
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

        appendMessage(UploadFileMessage(uploadFileRequest: imageRequest, textMessage: textMessage))
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    func sendFile(_ url: URL, textMessage: String? = nil) {
        guard let data = try? Data(contentsOf: url) else { return }
        let uploadRequest = UploadFileRequest(data: data,
                                              fileExtension: ".\(url.fileExtension)",
                                              fileName: url.fileName,
                                              mimeType: url.mimeType,
                                              userGroupHash: thread.userGroupHash)
        appendMessage(UploadFileMessage(uploadFileRequest: uploadRequest, textMessage: textMessage ?? ""))
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
        if isInEditMode == false {
            textMessage = ""
        }
    }

    func setEditMessage(_ message: Message) {
        editMessage = message
    }

    func setMessageEdited(_ message: Message) {
        messages.first(where: { $0.id == message.id })?.message = message.message
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

    func searchInsideThread(offset: Int = 0) {
        guard seachableText.count >= 2 else { return }
        let req = GetHistoryRequest(threadId: threadId, count: 50, offset: offset, query: "\(seachableText)")
        Chat.sharedInstance.getHistory(req) { messages, _, _, _ in
            if let messages = messages {
                self.searchedMessages.append(contentsOf: messages)
            }
        }
    }

    func delete() {
        Chat.sharedInstance.deleteThread(.init(threadId: threadId)) { threadId, _, error in
            if threadId != nil, error == nil {
                self.threadsViewModel?.removeThread(self.thread)
            }
        }
    }

    func leave() {
        Chat.sharedInstance.leaveThread(.init(threadId: threadId, clearHistory: true)) { user, _, error in
            if user != nil, error == nil {
                self.threadsViewModel?.removeThread(self.thread)
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
        Chat.sharedInstance.pinThread(.init(threadId: threadId), completion: onPinChanged)
    }

    func unpin() {
        Chat.sharedInstance.unpinThread(.init(threadId: threadId), completion: onPinChanged)
    }

    func onPinChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            thread.pin?.toggle()
            objectWillChange.send()
        }
    }

    func clearHistory() {
        Chat.sharedInstance.clearHistory(.init(threadId: threadId)) { _, _, _ in }
        objectWillChange.send()
    }

    func toggleMute() {
        if thread.mute ?? false == false {
            mute()
        } else {
            unmute()
        }
    }

    func mute() {
        Chat.sharedInstance.muteThread(.init(threadId: threadId), completion: onMuteChanged)
    }

    func unmute() {
        Chat.sharedInstance.unmuteThread(.init(threadId: threadId), completion: onMuteChanged)
    }

    func onMuteChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            thread.mute?.toggle()
            objectWillChange.send()
        }
    }

    func spamPV() {
        Chat.sharedInstance.spamPvThread(SpamThreadRequest(threadId: threadId)) { _, _, _ in }
    }

    private var lastIsTypingTime = Date()

    private func startTypingTimer(_ event: SystemEventTypes) {
        if case .systemMessage(let message, _, let id) = event, message.smt == .isTyping, isTyping == false, thread.id == id {
            lastIsTypingTime = Date()
            isTyping = true
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if self.lastIsTypingTime.advanced(by: 1) < Date() {
                    timer.invalidate()
                    self.isTyping = false
                }
            }
        } else {
            lastIsTypingTime = Date()
        }
    }

    func appendMessages(messages: [Message]) {
        if messages.count == 0 {
            return
        }
        self.messages.insert(contentsOf: filterNewMessagesToAppend(serverMessages: messages), at: 0)
        sort()
    }

    func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    /// Filter only new messages prevent conflict with cache messages
    func filterNewMessagesToAppend(serverMessages: [Message]) -> [Message] {
        let ids = messages.map { $0.id }
        let newMessages = serverMessages.filter { message in
            !ids.contains { id in
                id == message.id
            }
        }
        return newMessages
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
        Chat.sharedInstance.archiveThread(.init(threadId: threadId), onArchiveChanged)
    }

    func unarchive() {
        Chat.sharedInstance.unarchiveThread(.init(threadId: threadId), onArchiveChanged)
    }

    func onArchiveChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            thread.isArchive?.toggle()
            objectWillChange.send()
        }
    }
}
