//
//  ThreadsViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import OrderedCollections
import SwiftUI
import ChatModels
import TalkModels
import ChatCore
import ChatDTO
import TalkExtensions
import OSLog

public final class ThreadsViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var toggle = false
    @AppStorage("Threads", store: UserDefaults.group) public var threadsData: Data?
    @Published public var threads: OrderedSet<Conversation> = []
    @Published public var archives: OrderedSet<Conversation> = []
    @Published public var searchedConversations: OrderedSet<Conversation> = []
    @Published private(set) var tagViewModel = TagsViewModel()
    @Published public var activeCallThreads: [CallToJoin] = []
    @Published public var sheetType: ThreadsSheetType?
    public private(set) var cancelable: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false
    public private(set) var count = 15
    public private(set) var offset = 0
    @Published public var searchText: String = ""
    private(set) var hasNext: Bool = true
    public var archivedOffset: Int = 0
    public var selectedThraed: Conversation?
    public var folder: Tag?
    public var title: String = ""
    @Published public var selectedFilterThreadType: ThreadTypes?
    private var canLoadMore: Bool { hasNext && !isLoading }
    private var avatarsVM: [String :ImageLoaderViewModel] = [:]

    public init() {
        AppState.shared.$connectionStatus
            .sink{ [weak self] event in
                self?.onConnectionStatusChanged(event)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .chatEvents)
            .compactMap { $0.object as? ChatEventType }
            .sink{ [weak self] event in
                self?.onChatEvent(event)
            }
            .store(in: &cancelable)
        getThreads()
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .sink { [weak self] newValue in
                if newValue.first == "@", newValue.count > 2 {
                    let startIndex = newValue.index(newValue.startIndex, offsetBy: 1)
                    let newString = newValue[startIndex..<newValue.endIndex]
                    self?.searchPublicThreads(String(newString))
                } else if newValue.first != "@" {
                    self?.searchThreads(newValue)
                } else if newValue.count == 0, self?.hasNext == false {
                    self?.hasNext = true
                }
            }
            .store(in: &cancelable)

        RequestsManager.shared.$cancelRequest
            .sink { [weak self] newValue in
                if let newValue {
                    self?.onCancelTimer(key: newValue)
                }
            }
            .store(in: &cancelable)
    }

    func onCreate(_ response: ChatResponse<Conversation>) {
        if let thread = response.result {
            AppState.shared.showThread(thread: thread)
            appendThreads(threads: [thread])
        }
        isLoading = false
    }

    public func onNewMessage(_ response: ChatResponse<Message>) {
        if let message = response.result, let index = firstIndex(message.conversation?.id) {
            threads[index].time = response.result?.conversation?.time
            threads[index].unreadCount = (threads[index].unreadCount ?? 0) + 1
            threads[index].lastMessageVO = response.result
            threads[index].lastMessage = response.result?.message
            if threads[index].pin == false {
                sort()
            }
        } else if let threadId = response.result?.conversation?.id {
            getThreadsWith([threadId])
        }
    }

    func onChangedType(_ response: ChatResponse<Conversation>) {
        if let index = firstIndex(response.result?.id)  {
            threads[index].type = .publicGroup
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            offset = 0
            getThreads()
        } else if status == .connected, firstSuccessResponse == true {
            // After connecting again
            refreshThreadsUnreadCount()
        }
    }

    public func getThreads() {
        isLoading = true
        let req = ThreadsRequest(count: count, offset: offset, type: selectedFilterThreadType)
        RequestsManager.shared.append(prepend: "GET-THREADS", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func getArchivedThreads() {
        isLoading = true
        let req = ThreadsRequest(count: count, offset: archivedOffset, archived: true)
        RequestsManager.shared.append(prepend: "GET-ARCHIVES", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func resetArchiveSettings() {
        archivedOffset = 0
        hasNext = true
        animateObjectWillChange()
    }

    public func resetFolderSettings() {
        folder = nil
        hasNext = true
        animateObjectWillChange()
    }

    public func getThreadsInsideFolder(_ folder: Tag) {
        self.folder = folder
        let threadIds = folder.tagParticipants?.compactMap(\.conversation?.id) ?? []
        getThreadsWith(threadIds)
    }

    public func getThreadsWith(_ threadIds: [Int]) {
        if threadIds.count == 0 { return }
        isLoading = true
        let req = ThreadsRequest(threadIds: threadIds)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func searchThreads(_ text: String) {
        searchedConversations.removeAll()
        let req = ThreadsRequest(searchText: text)
        RequestsManager.shared.append(prepend: "SEARCH", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    public func searchPublicThreads(_ text: String) {
        searchedConversations.removeAll()
        let req = ThreadsRequest(name: text, type: .publicGroup)
        RequestsManager.shared.append(prepend: "SEARCH-PUBLIC-THREAD", value: req)
        ChatManager.activeInstance?.conversation.get(req)
    }

    func onSearch(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, let threads = response.result, response.value(prepend: "SEARCH") != nil {
            searchedConversations.append(contentsOf: threads)
        }
    }

    func onPublicThreadSearch(_ response: ChatResponse<[Conversation]>) {
        if !response.cache, let threads = response.result, response.value(prepend: "SEARCH-PUBLIC-THREAD") != nil {
            searchedConversations.append(contentsOf: threads)
        }
    }

    public func loadMore() {
        if !canLoadMore { return }
        preparePaginiation()
        getThreads()
    }

    public func onThreads(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result?.filter({$0.isArchive == false || $0.isArchive == nil}) {
            appendThreads(threads: threads)
            updateWidgetPreferenceThreads(threads)
        }

        if !response.cache, response.result?.count ?? 0 > 0 {
            hasNext = response.hasNext
            firstSuccessResponse = true
        }
        isLoading = false
    }

    public func onArchives(_ response: ChatResponse<[Conversation]>) {
        if let archives = response.result, response.value(prepend: "GET-ARCHIVES") != nil {
            self.archives.append(contentsOf: archives.filter({$0.isArchive == true}))
        }
        isLoading = false
    }

    public func updateWidgetPreferenceThreads(_ threads: [Conversation]) {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            var storageThreads = (try? JSONDecoder().decode([Conversation].self, from: threadsData ?? Data())) ?? []
            storageThreads.append(contentsOf: threads)
            let data = try? JSONEncoder().encode(Array(Set(storageThreads)))
            await MainActor.run { [weak self] in
                self?.threadsData = data
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
    }

    /// Join to a public thread by it's unqiue name.
    public func joinToPublicThread(_ publicThreadName: String) {
        isLoading = true
        let req = JoinPublicThreadRequest(threadName: publicThreadName)
        ChatManager.activeInstance?.conversation.join(req)
    }

    public func searchInsideAllThreads(text _: String) {
        // not implemented yet
        //        ChatManager.activeInstance?.
    }

    public func makeThreadPublic(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.conversation.changeType(.init(threadId: threadId, type: .publicGroup))
    }

    public func showAddParticipants(_ thread: Conversation) {
        selectedThraed = thread
        sheetType = .addParticipant
    }

    public func addParticipantsToThread(_ contacts: [Contact]) {
        isLoading = true
        guard let threadId = selectedThraed?.id else { return }
        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)        
        ChatManager.activeInstance?.conversation.participant.add(req)
    }

    func onAddPrticipant(_ response: ChatResponse<Conversation>) {
        if let thread = response.result {
            /// To navigate to the thread immediately after adding participants
            AppState.shared.showThread(thread: thread)
        }
        isLoading = false
    }

    func onDeletePrticipant(_ response: ChatResponse<[Participant]>) {
        if let index = firstIndex(response.subjectId) {
            threads[index].participantCount = min(0, threads[index].participantCount ?? 0 - 1)
        }
        isLoading = false
    }

    public func showAddThreadToTag(_ thread: Conversation) {
        selectedThraed = thread
        sheetType = .tagManagement
    }

    public func preparePaginiation() {
        offset = count + offset
    }

    public func appendThreads(threads: [Conversation]) {
        threads.forEach { thread in
            if let oldThread = self.threads.first(where: { $0.id == thread.id }) {
                oldThread.updateValues(thread)
            } else {
                self.threads.append(thread)
            }
        }
        sort()
    }

    public func sort() {
        threads.sort(by: { $0.time ?? 0 > $1.time ?? 0 })
        threads.sort(by: { $0.pin == true && $1.pin == false })
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
        }
    }

    public func removeThread(_ thread: Conversation) {
        guard let index = firstIndex(thread.id) else { return }
        withAnimation {
            _ = threads.remove(at: index)
        }
    }

    public func delete() {
        guard let threadId = selectedThraed?.id else { return }
        ChatManager.activeInstance?.conversation.delete(.init(subjectId: threadId))
        sheetType = nil
    }

    func onDeleteThread(_ response: ChatResponse<Participant>) {
        if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
            removeThread(thread)
        }
    }

    public func leave(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.conversation.leave(.init(threadId: threadId, clearHistory: true))
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
        withAnimation {
            response.result?.forEach { key, value in
                if let index = firstIndex(Int(key)) {
                    threads[index].unreadCount = value
                }
            }
            isLoading = false
        }
    }

    public func updateThreadInfo(_ thread: Conversation) {
        if let index = firstIndex(thread.id) {
            threads[index].updateValues(thread)
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

    public func onMuteThreadChanged(mute: Bool, threadId: Int?) {
        if let index = firstIndex(threadId) {
            threads[index].mute = mute
            sort()
            animateObjectWillChange()
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = self.firstIndex(id) {
            threads.remove(at: index)
        }
    }

    /// This method will be called whenver we send seen for an unseen message by ourself.
    public func onLastSeenMessageUpdated(_ response: ChatResponse<LastSeenMessageResponse>) {
        if let index = firstIndex(response.subjectId) {
            threads[index].lastSeenMessageTime = response.result?.lastSeenMessageTime
            threads[index].lastSeenMessageId = response.result?.lastSeenMessageId
            threads[index].lastSeenMessageNanos = response.result?.lastSeenMessageNanos
            setUnreadCount(response.result?.unreadCount ?? response.contentCount, threadId: response.subjectId)
            animateObjectWillChange()
        }
    }

    func onCancelTimer(key: String) {
        withAnimation {
            isLoading = false
        }
    }

    public func avatars(for imageURL: String) -> ImageLoaderViewModel {
        if let avatarVM = avatarsVM[imageURL] {
            return avatarVM
        } else {
            let newAvatarVM = ImageLoaderViewModel()
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
            threads.insert(conversation, at: 0)
            AppState.shared.showThread(thread: conversation)
            selectedThraed = conversation
            sheetType = nil
        }
    }

    /// This method prevents to update unread count if the local unread count is smaller than server unread count.
    public func setUnreadCount(_ newCount: Int?, threadId: Int?) {
        if newCount ?? 0 < threads.first(where: {$0.id == threadId})?.unreadCount ?? 0 {
            threads.first(where: {$0.id == threadId})?.unreadCount = newCount
            animateObjectWillChange()
        }
    }
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
