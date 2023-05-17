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

public final class ThreadsViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var toggleThreadContactPicker = false
    @Published public var toggle = false
    @AppStorage("Threads", store: UserDefaults.group) public var threadsData: Data?
    @Published public var showAddParticipants = false
    @Published public var showCreateDirectThread = false
    @Published public var showAddToTags = false
    @Published public var threads: OrderedSet<Conversation> = []
    @Published private(set) var tagViewModel = TagsViewModel()
    @Published public var activeCallThreads: [CallToJoin] = []
    public private(set) var cancellableSet: Set<AnyCancellable> = []
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

    public init() {
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: .threadEventNotificationName)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink(receiveValue: onThreadEvent)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: .messageNotificationName)
            .compactMap { $0.object as? MessageEventTypes }
            .sink(receiveValue: onNewMessage)
            .store(in: &cancellableSet)
        NotificationCenter.default.publisher(for: .callEventName)
            .compactMap { $0.object as? CallEventTypes }
            .sink(receiveValue: onCallEvent)
            .store(in: &cancellableSet)
        getThreads()

        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.searchThreads(newValue)
            }
            .store(in: &cancellableSet)
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case let .threadNew(response):
            if let newThreads = response.result {
                appendThreads(threads: [newThreads])
            }
        case let .threadDeleted(response):
            if let threadId = response.subjectId, let thread = threads.first(where: { $0.id == threadId }) {
                removeThread(thread)
            }
        case let .lastMessageDeleted(response), let .lastMessageEdited(response):
            if let thread = response.result {
                onLastMessageChanged(thread)
            }
        case let .threadInfoUpdated(response):
            if let thread = response.result {
                updateThreadInfo(thread)
            }
        case let .threadUnreadCountUpdated(response):
            if let index = threads.firstIndex(where: { $0.id == response.result?.threadId }) {
                threads[index].unreadCount = response.result?.unreadCount
                objectWillChange.send()
            }
        case let .threadMute(response):
            onMuteThreadChanged(mute: true, threadId: response.result)
        case let .threadUnmute(response):
            onMuteThreadChanged(mute: false, threadId: response.result)
        default:
            break
        }
    }

    func onCallEvent(_ event: CallEventTypes) {
        switch event {
        case let .callEnded(response):
            activeCallThreads.removeAll(where: { $0.callId == response?.result })
        case let .groupCallCanceled(response):
            activeCallThreads.append(.init(threadId: response.subjectId ?? -1, callId: response.result?.callId ?? -1))
        case let .callReceived(response):
            activeCallThreads.append(.init(threadId: response.result?.conversation?.id ?? -1, callId: response.result?.callId ?? -1))
        default:
            break
        }
    }

    public func onNewMessage(_ event: MessageEventTypes) {
        if case let .messageNew(response) = event, let index = threads.firstIndex(where: { $0.id == response.result?.conversation?.id }) {
            threads[index].time = response.result?.conversation?.time
            threads[index].unreadCount = (threads[index].unreadCount ?? 0) + 1
            threads[index].lastMessageVO = response.result
            threads[index].lastMessage = response.result?.message
            if threads[index].pin == false {
                sort()
            }
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
        ChatManager.activeInstance?.getThreads(.init(count: count, offset: offset, type: selectedFilterThreadType), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    public func getArchivedThreads() {
        archived = true
        isLoading = true
        ChatManager.activeInstance?.getThreads(.init(count: count, offset: archivedOffset, archived: true), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    public func resetArchiveSettings() {
        archived = false
        archivedOffset = 0
        hasNext = true
        objectWillChange.send()
    }

    public func resetFolderSettings() {
        folder = nil
        hasNext = true
        objectWillChange.send()
    }

    public func getThreadsInsideFolder(_ folder: Tag) {
        self.folder = folder
        let threadIds = folder.tagParticipants?.compactMap(\.conversation?.id) ?? []
        getThreadsWith(threadIds)
    }

    public func getThreadsWith(_ threadIds: [Int]) {
        if threadIds.count == 0 { return }
        isLoading = true
        ChatManager.activeInstance?.getThreads(.init(threadIds: threadIds), completion: onServerResponse, cacheResponse: onCacheResponse)
    }

    public func searchThreads(_ text: String) {
        ChatManager.activeInstance?.getThreads(.init(name: text, type: .publicGroup)) { [weak self] response in
            if let threads = response.result {
                self?.appendThreads(threads: threads)
            }
        }
    }

    public var filtered: [Conversation] {
        if let folder = folder {
            return folder.tagParticipants?
                .compactMap(\.conversation?.id)
                .compactMap { id in threads.first { $0.id == id } }
                ?? []
        } else if searchText.isEmpty {
            return threads.filter { $0.isArchive == archived }
        } else {
            return threads.filter { $0.title?.lowercased().contains(searchText.lowercased()) ?? false && $0.isArchive == archived }
        }
    }

    public func loadMore() {
        if !hasNext { return }
        preparePaginiation()
        getThreads()
    }

    public func onServerResponse(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            firstSuccessResponse = true
            appendThreads(threads: threads)
            hasNext(response.pagination?.hasNext ?? false)
            updateWidgetPreferenceThreads(threads)
        }
        isLoading = false
    }

    public func onCacheResponse(_ response: ChatResponse<[Conversation]>) {
        if let threads = response.result {
            appendThreads(threads: threads)
            hasNext(response.pagination?.hasNext ?? false)
        }
        if isLoading, AppState.shared.connectionStatus != .connected {
            isLoading = false
        }
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
        ChatManager.activeInstance?.createThread(.init(invitees: invitees, title: model.title, type: model.type, uniqueName: model.isPublic ? model.title : nil)) { [weak self] response in
            if let thread = response.result {
                AppState.shared.animateAndShowThread(thread: thread)
            }
            self?.isLoading = false
        }
    }

    /// Create a thread and send a message without adding a contact.
    public func fastMessage(_ invitee: Invitee, _ message: String) {
        isLoading = true
        let messageREQ = CreateThreadMessage(text: message, messageType: .text)
        ChatManager.activeInstance?.createThreadWithMessage(.init(invitees: [invitee], title: "", type: .normal, message: messageREQ)) { [weak self] response in
            if let thread = response.result {
                AppState.shared.animateAndShowThread(thread: thread)
            }
            self?.isLoading = false
        }
    }

    public func searchInsideAllThreads(text _: String) {
        // not implemented yet
        //        ChatManager.activeInstance?.
    }

    public func makeThreadPublic(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.changeThreadType(.init(threadId: threadId, type: .publicGroup)) { [weak self] response in
            if let index = self?.threads.firstIndex(where: {$0.id == response.result?.id })  {
                self?.threads[index].type = .publicGroup
            }
        }
    }

    public func showAddParticipants(_ thread: Conversation) {
        selectedThraed = thread
        showAddParticipants.toggle()
    }

    public func addParticipantsToThread(_ contacts: [Contact]) {
        isLoading = true
        guard let threadId = selectedThraed?.id else {
            return
        }

        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)

        ChatManager.activeInstance?.addParticipant(req) { [weak self] response in
            if let thread = response.result {
                // To navigate to the thread immediately after adding participants
                AppState.shared.animateAndShowThread(thread: thread)
            }
            self?.isLoading = false
        }
    }

    public func showAddThreadToTag(_ thread: Conversation) {
        selectedThraed = thread
        showAddToTags.toggle()
    }

    public func hasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
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

    public func delete(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.deleteThread(.init(subjectId: threadId)) { [weak self] response in
            if response.error == nil {
                self?.removeThread(thread)
            }
        }
    }

    public func leave(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.leaveThread(.init(threadId: threadId, clearHistory: true)) { [weak self] response in
            if response.error == nil {
                self?.removeThread(thread)
            }
        }
    }

    public func clearHistory(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.clearHistory(.init(subjectId: threadId)) { [weak self] response in
            if response.result != nil {
                self?.removeThread(thread)
            }
        }
    }

    public func spamPV(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        ChatManager.activeInstance?.spamPvThread(.init(subjectId: threadId)) { _ in }
    }

    public func firstIndex(_ threadId: Int?) -> Array<Conversation>.Index? {
        threads.firstIndex(where: { $0.id == threadId ?? -1 })
    }

    public func refreshThreadsUnreadCount() {
        let threadsIds = threads.compactMap(\.id)
        ChatManager.activeInstance?.getThreadsUnreadCount(.init(threadIds: threadsIds)) { [weak self] response in
            response.result?.forEach { key, value in
                if let index = self?.threads.firstIndex(where: { $0.id == Int(key) ?? -1 }) {
                    self?.threads[index].unreadCount = value
                }
            }
            self?.isLoading = false
            if response.result?.count ?? 0 > 0 {
                withAnimation {
                    self?.objectWillChange.send()
                }
            }
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
            objectWillChange.send()
        }
    }

    public func onLastMessageChanged(_ thread: Conversation) {
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads[index].lastMessage = thread.lastMessage
            threads[index].lastMessageVO = thread.lastMessageVO
            objectWillChange.send()
        }
    }

    public func onMuteThreadChanged(mute: Bool, threadId: Int?) {
        if let index = threads.firstIndex(where: { $0.id == threadId }) {
            threads[index].mute = mute
            sort()
            objectWillChange.send()
        }
    }
}

public struct CallToJoin {
    public let threadId: Int
    public let callId: Int
}
