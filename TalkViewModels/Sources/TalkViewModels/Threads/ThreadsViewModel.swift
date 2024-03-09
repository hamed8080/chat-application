//
//  ThreadsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import SwiftUI
import ChatModels
import TalkModels
import ChatCore
import ChatDTO
import TalkExtensions
import OSLog

/// It needs to be ObservableObject because when a message is seen deleted... the object needs to update not the whole Thread ViewModel.
extension Conversation: ObservableObject {}
public final class ThreadsViewModel: ObservableObject {
    public var isLoading = false
    public var threads: ContiguousArray<Conversation> = []
    @Published private(set) var tagViewModel = TagsViewModel()
    @Published public var activeCallThreads: [CallToJoin] = []
    @Published public var sheetType: ThreadsSheetType?
    public var cancelable: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    public private(set) var count = 15
    public private(set) var offset = 0
    private(set) var hasNext: Bool = true
    public var selectedThraed: Conversation?
    private var canLoadMore: Bool { hasNext && !isLoading }
    private var avatarsVM: [String :ImageLoaderViewModel] = [:]
    public var serverSortedPins: [Int] = []
    public var shimmerViewModel = ShimmerViewModel(delayToHide: 0, repeatInterval: 0.5)
    @Published public var showUnreadConversations: Bool? = nil
    public var threadEventModels: [ThreadEventViewModel] = []

    public init() {
        AppState.shared.$connectionStatus
            .sink{ [weak self] event in
                self?.onConnectionStatusChanged(event)
            }
            .store(in: &cancelable)
        registerNotifications()
    }

    func onCreate(_ response: ChatResponse<Conversation>) {
        isLoading = false
        if let thread = response.result {
            Task { [weak self] in
                guard let self = self else { return }
                await appendThreads(threads: [thread])
                await asyncAnimateObjectWillChange()
            }
        }
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if let message = response.result, let index = firstIndex(message.conversation?.id) {
            threads[index].time = response.result?.conversation?.time
            let isMe = response.result?.participant?.id == AppState.shared.user?.id
            if !isMe {
                threads[index].unreadCount = (threads[index].unreadCount ?? 0) + 1
            }
            threads[index].lastMessageVO = response.result
            threads[index].lastSeenMessageId = response.result?.conversation?.lastSeenMessageId
            threads[index].lastSeenMessageTime = response.result?.conversation?.lastSeenMessageTime
            threads[index].lastSeenMessageNanos = response.result?.conversation?.lastSeenMessageNanos
            threads[index].lastMessage = response.result?.message
            /// We only set the mentioned true because if the user sends multiple messages inside a thread but one message has been mention, the list will set it to false which is wrong.
            if response.result?.mentioned == true {
                threads[index].mentioned = true
            }
            if threads[index].pin == false {
                sort()
            }
            threads[index].animateObjectWillChange()
            animateObjectWillChange()
        }
        getNotActiveThreads(response.result?.conversation)
    }

    func onChangedType(_ response: ChatResponse<Conversation>) {
        if let index = firstIndex(response.result?.id)  {
            threads[index].type = .publicGroup
            animateObjectWillChange()
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            offset = 0
            getThreads()
        } else if status == .connected, firstSuccessResponse == true {
            // After connecting again
            threads.removeAll()
            offset = 0
            getThreads()
//            refreshThreadsUnreadCount()
        }
    }

    public func getThreads() {
        if !firstSuccessResponse {
            shimmerViewModel.show()
        }
        isLoading = true
        animateObjectWillChange()
        let req = ThreadsRequest(count: count, offset: offset)
        RequestsManager.shared.append(prepend: "GET-THREADS", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func loadMore() {
        if !canLoadMore { return }
        preparePaginiation()
        if showUnreadConversations == true {
            getUnreadThreads()
        } else {
            getThreads()
        }
    }

    public func onThreads(_ response: ChatResponse<[Conversation]>) {
        if response.pop(prepend: "GET-THREADS") == nil { return }
        let threads = response.result?.filter({$0.isArchive == false || $0.isArchive == nil})
        let pinThreads = response.result?.filter({$0.pin == true})
        let hasAnyResults = response.result?.count ?? 0 > 0
        Task { [weak self] in
            guard let self = self else { return }
            /// It only sets sorted pins once because if we have 5 pins, they are in the first response. So when the user scrolls down the list will not be destroyed every time.
            if let serverSortedPinIds = pinThreads?.compactMap({$0.id}), serverSortedPins.isEmpty {
                serverSortedPins.removeAll()
                serverSortedPins.append(contentsOf: serverSortedPinIds)
            }
            await appendThreads(threads: threads ?? [])
            await asyncAnimateObjectWillChange()
        }

        if hasAnyResults {
            hasNext = response.hasNext
            firstSuccessResponse = true
        }
        isLoading = false

        if firstSuccessResponse {
            shimmerViewModel.hide()
        }
    }

    public func onNotActiveThreads(_ response: ChatResponse<[Conversation]>) {
        if response.pop(prepend: "GET-NOT-ACTIVE-THREADS") == nil { return }
        if let threads = response.result?.filter({$0.isArchive == false || $0.isArchive == nil}) {
            Task { [weak self] in
                guard let self = self else { return }
                await appendThreads(threads: threads)
                await asyncAnimateObjectWillChange()
            }
        }
    }

    public func refresh() {
        clear()
        getThreads()
    }

    /// Create a thread and send a message without adding a contact.
    public func fastMessage(_ invitee: Invitee, _ message: String) {
        isLoading = true
        let messageREQ = CreateThreadMessage(text: message, messageType: .text)
        let req = CreateThreadWithMessage(invitees: [invitee], title: "", type: .normal, message: messageREQ)
        ChatManager.activeInstance?.conversation.create(req)
        animateObjectWillChange()
    }

    public func searchInsideAllThreads(text _: String) {
        // not implemented yet
        //        ChatManager.activeInstance?.
    }

    public func makeThreadPublic(_ thread: Conversation) {
        guard let threadId = thread.id, let type = thread.type else { return }
        let req = ChangeThreadTypeRequest(threadId: threadId, type: type.publicType, uniqueName: UUID().uuidString)
        RequestsManager.shared.append(prepend: "CHANGE-TO-PUBLIC", value: req)
        ChatManager.activeInstance?.conversation.changeType(req)
    }

    public func makeThreadPrivate(_ thread: Conversation) {
        guard let threadId = thread.id, let type = thread.type else { return }
        ChatManager.activeInstance?.conversation.changeType(.init(threadId: threadId, type: type.privateType))
    }

    public func showAddParticipants(_ thread: Conversation) {
        selectedThraed = thread
        sheetType = .addParticipant
    }

    public func addParticipantsToThread(_ contacts: ContiguousArray<Contact>) {
        isLoading = true
        guard let threadId = selectedThraed?.id else { return }
        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)        
        ChatManager.activeInstance?.conversation.participant.add(req)
        animateObjectWillChange()
    }

    func onAddPrticipant(_ response: ChatResponse<Conversation>) {
        Task { [weak self] in
            guard let self = self else { return }
            if response.result?.participants?.first(where: {$0.id == AppState.shared.user?.id}) != nil, let newConversation = response.result {
                /// It means an admin added a user to the conversation, and if the added user is in the app at the moment, should see this new conversation in its conversation list.
                await appendThreads(threads: [newConversation])
            }
            isLoading = false
            await asyncAnimateObjectWillChange()
        }
    }

    func onDeletePrticipant(_ response: ChatResponse<[Participant]>) {
        if let index = firstIndex(response.subjectId) {
            threads[index].participantCount = max(0, (threads[index].participantCount ?? 0) - 1)
            animateObjectWillChange()
        }
        isLoading = false
        animateObjectWillChange()
    }

    public func showAddThreadToTag(_ thread: Conversation) {
        selectedThraed = thread
        sheetType = .tagManagement
    }

    public func preparePaginiation() {
        offset = count + offset
    }

    public func appendThreads(threads: [Conversation]) async {
        threads.forEach { thread in
            if let oldThread = self.threads.first(where: { $0.id == thread.id }) {
                oldThread.updateValues(thread)
                oldThread.animateObjectWillChange() // To update properties such as unread count when we get threads again after disconnect.
            } else {
                self.threads.append(thread)
            }
            if !threadEventModels.contains(where: {$0.threadId == thread.id}) {
                let eventVM = ThreadEventViewModel(threadId: thread.id ?? 0)
                threadEventModels.append(eventVM)
            }
        }
        sort()
    }

    public func sort() {
        threads.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        threads.sort(by: { $0.pin == true && ($1.pin == false || $1.pin == nil) })
        threads.sort(by: { (firstItem, secondItem) in
            guard let firstIndex = serverSortedPins.firstIndex(where: {$0 == firstItem.id}),
                  let secondIndex = serverSortedPins.firstIndex(where: {$0 == secondItem.id}) else {
                return false // Handle the case when an element is not found in the server-sorted array
            }
            return firstIndex < secondIndex
        })
    }

    public func clear() {
        hasNext = false
        offset = 0
        count = 15
        threads = []
        firstSuccessResponse = false
        animateObjectWillChange()
    }

    public func muteUnMuteThread(_ threadId: Int?, isMute: Bool) {
        if let threadId = threadId, let index = firstIndex(threadId) {
            threads[index].mute = isMute
            animateObjectWillChange()
        }
    }

    public func removeThread(_ thread: Conversation) {
        guard let index = firstIndex(thread.id) else { return }
        _ = threads.remove(at: index)
        animateObjectWillChange()
    }

    public func delete(_ threadId: Int?) {
        guard let threadId = threadId else { return }
        let conversation = threads.first(where: { $0.id == threadId})
        let isGroup = conversation?.group == true
        if isGroup {
            ChatManager.activeInstance?.conversation.delete(.init(subjectId: threadId))
        } else {
            ChatManager.activeInstance?.conversation.leave(.init(threadId: threadId, clearHistory: true))
        }
        sheetType = nil
    }

    func onDeleteThread(_ response: ChatResponse<Participant>) {
        if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func leave(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        let req = LeaveThreadRequest(threadId: threadId, clearHistory: true)
        RequestsManager.shared.append(prepend: "Leave", value: req)
        ChatManager.activeInstance?.conversation.leave(req)
    }

    public func clearHistory(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.message.clear(.init(subjectId: threadId))
    }

    func onClear(_ response: ChatResponse<Int>) {
        if let threadId = response.result, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func spamPV(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.conversation.spam(.init(subjectId: threadId))
    }

    func onSpam(_ response: ChatResponse<Contact>) {
        if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func firstIndex(_ threadId: Int?) -> Array<Conversation>.Index? {
        threads.firstIndex(where: { $0.id == threadId ?? -1 })
    }

    public func refreshThreadsUnreadCount() {
        let threadsIds = threads.compactMap(\.id)
        ChatManager.activeInstance?.conversation.unreadCount(.init(threadIds: threadsIds))
    }

    func onUnreadCounts(_ response: ChatResponse<[String : Int]>) {
        response.result?.forEach { key, value in
            if let index = firstIndex(Int(key)) {
                threads[index].unreadCount = value
            }
        }
        isLoading = false
        animateObjectWillChange()
    }

    public func updateThreadInfo(_ thread: Conversation) {
        if let index = firstIndex(thread.id) {
            threads[index].updateValues(thread)
            threads[index].animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if let index = firstIndex(thread.id) {
            threads[index].lastMessage = thread.lastMessage
            threads[index].lastMessageVO = thread.lastMessageVO
            animateObjectWillChange()
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = self.firstIndex(id) {
            threads.remove(at: index)
            animateObjectWillChange()
        }
    }

    /// This method will be called whenver we send seen for an unseen message by ourself.
    public func onLastSeenMessageUpdated(_ response: ChatResponse<LastSeenMessageResponse>) {
        if let index = firstIndex(response.subjectId) {
            threads[index].lastSeenMessageTime = response.result?.lastSeenMessageTime
            threads[index].lastSeenMessageId = response.result?.lastSeenMessageId
            threads[index].lastSeenMessageNanos = response.result?.lastSeenMessageNanos
            setUnreadCount(response.result?.unreadCount ?? response.contentCount, threadId: response.subjectId)
            threads[index].animateObjectWillChange()
            animateObjectWillChange()
        }
    }

    func onCancelTimer(key: String) {
        if isLoading {
            isLoading = false
            animateObjectWillChange()
        }
    }

    public func avatars(for imageURL: String, metaData: String?, userName: String?) -> ImageLoaderViewModel {
        if let avatarVM = avatarsVM[imageURL] {
            return avatarVM
        } else {
            let config = ImageLoaderConfig(url: imageURL, metaData: metaData, userName: userName)
            let newAvatarVM = ImageLoaderViewModel(config: config)
            avatarsVM[imageURL] = newAvatarVM
            return newAvatarVM
        }
    }

    public func clearAvatarsOnSelectAnotherThread() {
        var keysToRemove: [String] = []
        let allThreadImages = threads.compactMap({$0.computedImageURL})
        avatarsVM.forEach { (key: String, value: ImageLoaderViewModel) in
            if !allThreadImages.contains(where: {$0 == key }) {
                keysToRemove.append(key)
            }
        }
        keysToRemove.forEach { key in
            avatarsVM.removeValue(forKey: key)
        }
    }

    public func onJoinedToPublicConversatin(_ response: ChatResponse<Conversation>) {
        if let conversation = response.result {
            threads.append(conversation)
            sort()
            if conversation.participants?.first?.id == AppState.shared.user?.id {
                AppState.shared.showThread(thread: conversation)
            }
            animateObjectWillChange()
        }
    }

    /// This method prevents to update unread count if the local unread count is smaller than server unread count.
    public func setUnreadCount(_ newCount: Int?, threadId: Int?) {
        if newCount ?? 0 <= threads.first(where: {$0.id == threadId})?.unreadCount ?? 0 {
            threads.first(where: {$0.id == threadId})?.unreadCount = newCount
            animateObjectWillChange()
        }
    }

    func onLeftThread(_ response: ChatResponse<User>) {
        if response.result?.id == AppState.shared.user?.id, let conversationId = response.subjectId {
            removeThread(.init(id: conversationId))
        }
    }

    public func joinPublicGroup(_ publicName: String) {
        ChatManager.activeInstance?.conversation.join(.init(threadName: publicName))
    }

    public func onSeen(_ response: ChatResponse<MessageResponse>) {
        /// Update the status bar in ThreadRow when a receiver seen a message, and in the sender side we have to update the UI.
        let isMe = AppState.shared.user?.id == response.result?.participantId
        if !isMe, let index = threads.firstIndex(where: {$0.lastMessageVO?.id == response.result?.messageId}) {
            threads[index].lastMessageVO?.delivered = true
            threads[index].lastMessageVO?.seen = true
            threads[index].partnerLastSeenMessageId = response.result?.messageId
            threads[index].animateObjectWillChange()
        }
    }

    /// This method only reduce the unread count if the deleted message has sent after lastSeenMessageTime.
    public func onMessageDeleted(_ response: ChatResponse<Message>) {
        let thread = threads.first{ $0.id == response.subjectId }
        if response.result?.time ?? 0 > thread?.lastSeenMessageTime ?? 0, thread?.unreadCount ?? 0 >= 1 {
            thread?.unreadCount = (thread?.unreadCount ?? 0) - 1
            thread?.animateObjectWillChange()
        }
    }

    public func getNotActiveThreads(_ conversation: Conversation?) {
        if let conversationId = conversation?.id, !threads.contains(where: {$0.id == conversationId }) {
            let req = ThreadsRequest(threadIds: [conversationId])
            RequestsManager.shared.append(prepend: "GET-NOT-ACTIVE-THREADS", value: req)
            ChatManager.activeInstance?.conversation.get(req)
        }
    }

    public func getUnreadThreads() {
        if !firstSuccessResponse {
            shimmerViewModel.show()
        }
        isLoading = true
        animateObjectWillChange()
        let req = ThreadsRequest(count: count, offset: offset, new: true)
        RequestsManager.shared.append(prepend: "GET-UNREAD-THREADS", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func onUnreadThreads(_ response: ChatResponse<[Conversation]>) {
        if response.pop(prepend: "GET-UNREAD-THREADS") == nil { return }
        let threads = response.result?.filter({$0.isArchive == false || $0.isArchive == nil})
        let pinThreads = response.result?.filter({$0.pin == true})
        let hasAnyResults = response.result?.count ?? 0 > 0
        Task { [weak self] in
            guard let self = self else { return }
            /// It only sets sorted pins once because if we have 5 pins, they are in the first response. So when the user scrolls down the list will not be destroyed every time.
            if let serverSortedPinIds = pinThreads?.compactMap({$0.id}), serverSortedPins.isEmpty {
                serverSortedPins.removeAll()
                serverSortedPins.append(contentsOf: serverSortedPinIds)
            }
            await appendThreads(threads: threads ?? [])
            await asyncAnimateObjectWillChange()
        }

        if hasAnyResults {
            hasNext = response.hasNext
            firstSuccessResponse = true
        }
        isLoading = false

        if firstSuccessResponse {
            shimmerViewModel.hide()
        }
    }

    public func getUnreadConversations() {
        threads.removeAll()
        offset = 0
        getUnreadThreads()
    }

    public func resetUnreadConversations() {
        threads.removeAll()
        offset = 0
        getThreads()
    }
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
