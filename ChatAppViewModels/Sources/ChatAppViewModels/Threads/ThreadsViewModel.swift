//
//  ThreadsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import OrderedCollections
import SwiftUI
import ChatModels
import ChatAppModels
import ChatCore
import ChatDTO
import ChatAppExtensions
import OSLog

public final class ThreadsViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var toggle = false
    @AppStorage("Threads", store: UserDefaults.group) public var threadsData: Data?
    @Published public var threads: OrderedSet<Conversation> = []
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
    public var archived: Bool = false
    public var folder: Tag?
    public var title: String = ""
    @Published public var selectedFilterThreadType: ThreadTypes?
    private var requests: [String: Any] = [:]
    private var searchRequests: [String: Any] = [:]
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
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.searchThreads(newValue)
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
        if let message = response.result, let index = threads.firstIndex(where: { $0.id == message.conversation?.id }) {
            threads[index].time = response.result?.conversation?.time
            threads[index].unreadCount = (threads[index].unreadCount ?? 0) + 1
            threads[index].lastMessageVO = response.result
            threads[index].lastMessage = response.result?.message
            if threads[index].pin == false {
                sort()
            }
        }
    }

    func onChangedType(_ response: ChatResponse<Conversation>) {
        if let index = threads.firstIndex(where: {$0.id == response.result?.id })  {
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
        let key = req.uniqueId
        ChatManager.activeInstance?.conversation.get(req)
        addCancelTimer(key: key)
    }

    public func getArchivedThreads() {
        archived = true
        isLoading = true
        let req = ThreadsRequest(count: count, offset: archivedOffset, archived: true)
        let key = req.uniqueId
        ChatManager.activeInstance?.conversation.get(req)
        addCancelTimer(key: key)
    }

    public func resetArchiveSettings() {
        archived = false
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
        let key = req.uniqueId
        ChatManager.activeInstance?.conversation.get(req)
        addCancelTimer(key: key)
    }

    public func searchThreads(_ text: String) {
        let req = ThreadsRequest(name: text, type: .publicGroup)
        requests[req.uniqueId] = req
        let key = req.uniqueId
        ChatManager.activeInstance?.conversation.get(req)
        addCancelTimer(key: key)
    }

    func onSearch(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result, let uniqueId = response.uniqueId, searchRequests[uniqueId] != nil {
            appendThreads(threads: threads)
            searchRequests.removeValue(forKey: uniqueId)
        }
    }

    public var filtered: [Conversation] {
        if let folder = folder {
            return folder.tagParticipants?
                .compactMap(\.conversation?.id)
                .compactMap { id in threads.first { $0.id == id } }
                ?? []
        } else if searchText.isEmpty {
            return threads.filter { ($0.isArchive ?? false) == archived }
        } else {
            return threads.filter { $0.title?.lowercased().contains(searchText.lowercased()) ?? false && $0.isArchive == archived }
        }
    }

    public func loadMore() {
        if !canLoadMore { return }
        preparePaginiation()
        getThreads()
    }

    public func onThreads(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            appendThreads(threads: threads)
            updateWidgetPreferenceThreads(threads)
        }

        if !response.cache, response.result?.count ?? 0 > 0 {
            hasNext = response.hasNext
            firstSuccessResponse = true
        }
        isLoading = false
    }

    public func updateWidgetPreferenceThreads(_ threads: [Conversation]) {
        var storageThreads = (try? JSONDecoder().decode([Conversation].self, from: threadsData ?? Data())) ?? []
        storageThreads.append(contentsOf: threads)
        let data = try? JSONEncoder().encode(Array(Set(storageThreads)))
        threadsData = data
    }

    public func refresh() {
        clear()
        getThreads()
    }

    public func createThread(_ model: StartThreadResultModel) {
        isLoading = true
        let invitees = model.selectedContacts.map { contact in
            Invitee(id: "\(contact.id ?? 0)", idType: .contactId)
        }
        let req = CreateThreadRequest(invitees: invitees, title: model.title, type: model.type, uniqueName: model.isPublic ? model.title : nil)
        let key = req.uniqueId
        ChatManager.activeInstance?.conversation.create(req)
        addCancelTimer(key: key)
    }

    /// Create a thread and send a message without adding a contact.
    public func fastMessage(_ invitee: Invitee, _ message: String) {
        isLoading = true
        let messageREQ = CreateThreadMessage(text: message, messageType: .text)
        let req = CreateThreadWithMessage(invitees: [invitee], title: "", type: .normal, message: messageREQ)
        let key = req.uniqueId
        ChatManager.activeInstance?.conversation.create(req)
        addCancelTimer(key: key)
    }

    /// Join to a public thread by it's unqiue name.
    public func joinToPublicThread(_ publicThreadName: String) {
        isLoading = true
        let req = JoinPublicThreadRequest(threadName: publicThreadName)
        let key = req.uniqueId
        ChatManager.activeInstance?.conversation.join(req)
        addCancelTimer(key: key)
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
        requests[req.uniqueId] = req
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
        count = 0
        threads = []
        firstSuccessResponse = false
    }

    public func muteUnMuteThread(_ threadId: Int?, isMute: Bool) {
        if let threadId = threadId, let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].mute = isMute
        }
    }

    public func removeThread(_ thread: Conversation) {
        guard let index = threads.firstIndex(where: { $0.id == thread.id }) else { return }
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
        response.result?.forEach { key, value in
            if let index = threads.firstIndex(where: { $0.id == Int(key) ?? -1 }) {
                threads[index].unreadCount = value
            }
        }
        isLoading = false
        if response.result?.count ?? 0 > 0 {
            animateObjectWillChange()
        }
    }

    public func updateThreadInfo(_ thread: Conversation) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].title = thread.title
            threads[index].partner = thread.partner
            threads[index].image = thread.image
            threads[index].metadata = thread.metadata
            threads[index].description = thread.description
            threads[index].type = thread.type
            threads[index].userGroupHash = thread.userGroupHash
            threads[index].time = thread.time
            threads[index].group = thread.group
            animateObjectWillChange()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].lastMessage = thread.lastMessage
            threads[index].lastMessageVO = thread.lastMessageVO
            animateObjectWillChange()
        }
    }

    public func onMuteThreadChanged(mute: Bool, threadId: Int?) {
        if let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].mute = mute
            sort()
            animateObjectWillChange()
        }
    }

    func onUserRemovedByAdmin(_ response: ChatResponse<Int>) {
        if let id = response.result, let index = self.threads.firstIndex(where: {$0.id == id}) {
            threads.remove(at: index)
        }
    }

    /// This method will be called whenver we send seen for an unseen message by ourself.
    public func onLastSeenMessageUpdated(_ response: ChatResponse<LastSeenMessageResponse>) {
        if let index = threads.firstIndex(where: {$0.id == response.subjectId }) {
            threads[index].lastSeenMessageTime = response.result?.lastSeenMessageTime
            threads[index].lastSeenMessageId = response.result?.lastSeenMessageId
            threads[index].lastSeenMessageNanos = response.result?.lastSeenMessageNanos
            threads[index].unreadCount = response.contentCount
            animateObjectWillChange()
        }
    }

    /// Automatically cancel a request if there is no response come back from the chat server after 5 seconds.
    func addCancelTimer(key: String) {
        Logger.viewModels.info("Send request with key:\(key)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if ((self?.requests.keys.contains(where: { $0 == key})) != nil) {
                withAnimation {
                    self?.requests.removeValue(forKey: key)
                    self?.isLoading = false
                }
            }
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
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
